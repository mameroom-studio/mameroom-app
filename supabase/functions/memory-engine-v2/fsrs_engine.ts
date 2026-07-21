import {
  type Card,
  createEmptyCard,
  fsrs,
  generatorParameters,
  Rating,
  State,
} from "npm:ts-fsrs@5.4.1";

export const ENGINE_VERSION = "fsrs_v2";
export const ALGORITHM_VERSION = "fsrs-6";
export const PARAMETER_VERSION = "fsrs-6-default-v1";

const scheduler = fsrs(
  generatorParameters({ request_retention: desiredRetention() }),
);

export type StoredCard = {
  state: "new" | "learning" | "review" | "relearning";
  due_at: string;
  last_reviewed_at: string | null;
  stability: number;
  difficulty: number;
  elapsed_days: number;
  scheduled_days: number;
  reps: number;
  lapses: number;
  learning_steps: number;
  state_version: number;
};

export type FsrsCandidate = {
  state: StoredCard["state"];
  due: string;
  last_review: string;
  stability: number;
  difficulty: number;
  elapsed_days: number;
  scheduled_days: number;
  reps: number;
  lapses: number;
  learning_steps: number;
};

export function scheduleCard(
  stored: StoredCard | null,
  reviewedAt: Date,
  rating: Rating.Again | Rating.Hard | Rating.Good,
): FsrsCandidate {
  const card = stored ? toFsrsCard(stored) : createEmptyCard(reviewedAt);
  const result = scheduler.next(card, reviewedAt, rating).card;
  return {
    state: fromState(result.state),
    due: result.due.toISOString(),
    last_review: reviewedAt.toISOString(),
    stability: result.stability,
    difficulty: result.difficulty,
    elapsed_days: result.elapsed_days,
    scheduled_days: result.scheduled_days,
    reps: result.reps,
    lapses: result.lapses,
    learning_steps: result.learning_steps,
  };
}

function desiredRetention(): number {
  const raw = Number(Deno.env.get("MEMORY_ENGINE_DESIRED_RETENTION") ?? "0.90");
  if (!Number.isFinite(raw) || raw < 0.70 || raw > 0.99) {
    throw new Error("INVALID_DESIRED_RETENTION");
  }
  return raw;
}

function toFsrsCard(stored: StoredCard): Card {
  return {
    due: new Date(stored.due_at),
    stability: stored.stability,
    difficulty: stored.difficulty,
    elapsed_days: stored.elapsed_days,
    scheduled_days: stored.scheduled_days,
    reps: stored.reps,
    lapses: stored.lapses,
    learning_steps: stored.learning_steps,
    state: toState(stored.state),
    last_review: stored.last_reviewed_at
      ? new Date(stored.last_reviewed_at)
      : undefined,
  };
}

function toState(state: StoredCard["state"]): State {
  switch (state) {
    case "new":
      return State.New;
    case "learning":
      return State.Learning;
    case "review":
      return State.Review;
    case "relearning":
      return State.Relearning;
  }
}

function fromState(state: State): StoredCard["state"] {
  switch (state) {
    case State.New:
      return "new";
    case State.Learning:
      return "learning";
    case State.Review:
      return "review";
    case State.Relearning:
      return "relearning";
  }
}
