import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Rating } from "npm:ts-fsrs@5.4.1";
import { scheduleCard, type StoredCard } from "./fsrs_engine.ts";
import {
  inferRating,
  mapPassAction,
  type PassReason,
} from "./rating_policy.ts";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers });
  try {
    const url = requiredEnv("SUPABASE_URL");
    const anon = requiredEnv("SUPABASE_ANON_KEY");
    const serviceRole = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const authorization = request.headers.get("Authorization") ?? "";
    const userClient = createClient(url, anon, {
      global: { headers: { Authorization: authorization } },
    });
    const { data: auth, error: authError } = await userClient.auth.getUser();
    if (authError || !auth.user) return json(401, { code: "UNAUTHORIZED" });
    if (!enabledFor(auth.user.id)) {
      return json(409, { code: "MEMORY_ENGINE_V2_DISABLED" });
    }
    const service = createClient(url, serviceRole, {
      auth: { persistSession: false },
    });
    const body = await request.json() as Record<string, unknown>;
    if (body.action === "due") {
      const limit = Number(body.limit ?? 20);
      const { data, error } = await userClient.rpc("get_due_reviews_v2", {
        p_limit: limit,
        p_count_only: body.countOnly === true,
      });
      if (error) throw new Error(`DUE_QUERY_FAILED:${error.message}`);
      return json(200, data);
    }
    return await submit(service, auth.user.id, body);
  } catch (error) {
    return json(500, {
      code: "MEMORY_ENGINE_V2_FAILED",
      detail: safeError(error),
    });
  }
});

// Generated database types are unavailable before the additive migration is applied.
// deno-lint-ignore no-explicit-any
async function submit(
  service: any,
  userId: string,
  body: Record<string, unknown>,
) {
  const submissionId = requiredString(body.submissionId);
  const questionId = requiredString(body.questionId);
  const passReason = (body.passReason ?? null) as PassReason;
  const isPass = body.isPass === true;
  const { data: rawCurrent, error: currentError } = await service.from(
    "question_memory_states_v2",
  )
    .select(
      "state,due_at,last_reviewed_at,stability,difficulty,elapsed_days,scheduled_days,reps,lapses,learning_steps,state_version",
    )
    .eq("user_id", userId).eq("question_id", questionId).maybeSingle();
  if (currentError) {
    throw new Error(`STATE_READ_FAILED:${currentError.message}`);
  }
  const current = rawCurrent as StoredCard | null;
  const preliminaryType = isPass
    ? "pass"
    : current == null
    ? "initial"
    : "review";
  const { data: reserved, error: reserveError } = await service.rpc(
    "reserve_memory_submission_v2",
    {
      p_user_id: userId,
      p_submission_id: submissionId,
      p_question_id: questionId,
      p_session_id: body.sessionId ?? null,
      p_event_type: preliminaryType,
      p_expected_state_version: current?.state_version ?? null,
    },
  );
  if (reserveError) throw new Error(`RESERVE_FAILED:${reserveError.message}`);
  const reservation = reserved as {
    status: string;
    response: unknown;
    reviewed_at: string;
  };
  if (reservation.status === "completed") {
    return json(200, reservation.response);
  }
  const isCorrect = body.isCorrect === true;
  const hintLevel = boundedInt(body.hintLevel, 0, 2);
  const retryCount = boundedInt(body.retryCount, 0, 100);
  const rating = isPass
    ? null
    : inferRating({ isCorrect, hintLevel, retryCount });
  let activeCurrent = current;
  let activeReviewedAt = new Date(reservation.reviewed_at);
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const eventType = !isPass && activeCurrent != null &&
        new Date(activeCurrent.due_at) > activeReviewedAt
      ? "voluntary"
      : activeCurrent == null
      ? "initial"
      : "review";
    const candidate = rating == null || eventType === "voluntary"
      ? {}
      : scheduleCard(
        activeCurrent,
        activeReviewedAt,
        rating as Rating.Again | Rating.Hard | Rating.Good,
      );
    const { data, error } = await service.rpc(
      "finalize_memory_submission_v2",
      {
        p_user_id: userId,
        p_submission_id: submissionId,
        p_selected_answer: String(body.selectedAnswer ?? ""),
        p_is_correct: isCorrect,
        p_response_time_ms: boundedInt(body.responseTimeMs, 0, 86400000),
        p_retry_count: retryCount,
        p_hint_level: hintLevel,
        p_rating: rating,
        p_pass_action: isPass ? mapPassAction(passReason) : null,
        p_candidate: candidate,
      },
    );
    if (!error) return json(200, data);
    if (!error.message.includes("STATE_VERSION_CONFLICT") || attempt > 0) {
      if (error.message.includes("STATE_VERSION_CONFLICT")) {
        return json(409, { code: "STATE_VERSION_CONFLICT" });
      }
      throw new Error(`FINALIZE_FAILED:${error.message}`);
    }
    const { data: refreshed, error: refreshError } = await service.rpc(
      "refresh_memory_submission_v2",
      { p_user_id: userId, p_submission_id: submissionId },
    );
    if (refreshError) {
      throw new Error(`STATE_REFRESH_FAILED:${refreshError.message}`);
    }
    const refresh = refreshed as {
      reviewed_at: string;
      state: StoredCard | null;
    };
    activeCurrent = refresh.state;
    activeReviewedAt = new Date(refresh.reviewed_at);
  }
  return json(409, { code: "STATE_VERSION_CONFLICT" });
}

function enabledFor(userId: string): boolean {
  if (
    (Deno.env.get("MEMORY_ENGINE_V2_ENABLED") ?? "false").toLowerCase() !==
      "true"
  ) return false;
  const allowlist = (Deno.env.get("MEMORY_ENGINE_V2_ALLOWLIST") ?? "").split(
    ",",
  ).map((v) => v.trim()).filter(Boolean);
  return allowlist.includes("*") || allowlist.includes(userId);
}
function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`MISSING_${name}`);
  return value;
}
function requiredString(value: unknown): string {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error("INVALID_STRING");
  }
  return value;
}
function boundedInt(value: unknown, min: number, max: number): number {
  const parsed = Number(value ?? 0);
  if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
    throw new Error("INVALID_INTEGER");
  }
  return parsed;
}
function safeError(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 240) : "UNKNOWN";
}
function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers });
}
