import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Material = {
  id: string;
  user_id: string;
  title: string;
  file_hash: string;
  status: string;
};

type ConceptRow = {
  id: string;
  name: string;
  description: string | null;
  importance: number;
  importance_score: number | null;
  concept_type: string | null;
  evaluation: unknown;
  exclusion_reason: string | null;
  evidence: unknown;
};

type QuizQuestion = {
  type: "multiple_choice" | "ox" | "fill_blank";
  concept_id: string;
  section_id: string | null;
  question_text: string;
  options: string[];
  answer: string;
  explanation: string;
  evidence: string;
  difficulty: number;
};

type ErrorCode =
  | "CONFIGURATION_ERROR"
  | "UNAUTHORIZED"
  | "INVALID_REQUEST"
  | "MATERIAL_NOT_FOUND"
  | "INVALID_MATERIAL_STATUS"
  | "CONCEPTS_EMPTY"
  | "OPENAI_REQUEST_FAILED"
  | "OPENAI_PARSE_FAILED"
  | "QUESTION_MIX_INVALID"
  | "QUESTIONS_INSERT_FAILED"
  | "DB_UPDATE_FAILED"
  | "DB_QUERY_FAILED"
  | "UNKNOWN_ERROR";

class AppError extends Error {
  constructor(
    public code: ErrorCode,
    message: string,
    public status = 500,
    public cause?: unknown,
  ) {
    super(message);
    this.name = "AppError";
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let activeSupabase: ReturnType<typeof createClient> | null = null;
  let activeMaterialId: string | null = null;

  try {
    logStep("quiz.start");
    const openAiApiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openAiApiKey) {
      throw new AppError("CONFIGURATION_ERROR", "OPENAI_API_KEY must be configured as a Supabase Edge Function secret.");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!supabaseUrl || !supabaseAnonKey) {
      throw new AppError("CONFIGURATION_ERROR", "Supabase Edge Function environment is missing SUPABASE_URL or SUPABASE_ANON_KEY.");
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    activeSupabase = supabase;

    const { data: authData, error: authError } = await supabase.auth.getUser();
    if (authError || !authData.user) {
      return errorJson(new AppError("UNAUTHORIZED", "Unauthorized", 401, authError), activeMaterialId);
    }

    const { materialId } = await req.json();
    if (typeof materialId !== "string" || materialId.length === 0) {
      return errorJson(new AppError("INVALID_REQUEST", "materialId is required", 400), activeMaterialId);
    }
    activeMaterialId = materialId;
    logStep("quiz.material.request", { materialId });

    const material = await loadMaterial(supabase, materialId, authData.user.id);
    const existingForMaterial = await loadQuestionsByMaterial(supabase, authData.user.id, material.id);
    if (existingForMaterial.length >= 10) {
      await updateMaterial(supabase, material.id, { status: "completed" });
      return json({
        materialId,
        status: "completed",
        questionCount: existingForMaterial.length,
        usedCache: true,
        message: "Reused existing first quiz for this material.",
      });
    }

    if (material.status !== "concepts_completed") {
      return errorJson(new AppError("INVALID_MATERIAL_STATUS", "generate-first-quiz requires status concepts_completed.", 409), material.id);
    }

    const concepts = filterUsableConcepts(await loadConcepts(supabase, authData.user.id, material.id));
    if (concepts.length === 0) {
      throw new AppError("CONCEPTS_EMPTY", "No usable concept text found for this material. Concepts with empty names or internal IDs were excluded.", 409);
    }

    const cachedBySourceHash = await loadQuestionsBySourceHash(
      supabase,
      authData.user.id,
      material.file_hash,
      material.id,
    );
    if (cachedBySourceHash.length >= 10) {
      const copiedCount = await copyCachedQuestions({
        supabase,
        userId: authData.user.id,
        materialId: material.id,
        sourceHash: material.file_hash,
        cachedQuestions: cachedBySourceHash.slice(0, 10),
        concepts,
      });
      if (copiedCount >= 10) {
        await updateMaterial(supabase, material.id, { status: "completed" });
        return json({
          materialId,
          status: "completed",
          questionCount: copiedCount,
          usedCache: true,
          message: "Reused first quiz for the same source hash.",
        });
      }
    }

    logStep("quiz.status.questions_generating", { materialId: material.id, conceptCount: concepts.length });
    await updateMaterial(supabase, material.id, { status: "questions_generating" });
    logStep("quiz.openai.start", { materialId: material.id });
    const questions = await generateQuestionsWithOpenAi({
      apiKey: openAiApiKey,
      materialTitle: material.title,
      concepts,
    });

    logQuestionMix("quiz.questions.final_mix", questions);
    validateQuestionMix(questions);
    logStep("quiz.questions.save.start", { materialId: material.id, questionCount: questions.length });
    await saveQuestions({
      supabase,
      userId: authData.user.id,
      materialId: material.id,
      sourceHash: material.file_hash,
      questions,
    });

    await updateMaterial(supabase, material.id, { status: "completed" });
    return json({
      materialId,
      status: "completed",
      questionCount: questions.length,
      usedCache: false,
      message: "First quiz generated and saved.",
    });
  } catch (error) {
    const serialized = serializeError(error);
    logStep("quiz.error", { materialId: activeMaterialId, error: serialized });
    if (activeSupabase && activeMaterialId) {
      await markMaterialFailed(activeSupabase, activeMaterialId, serialized.message);
    }
    return errorJson(error, activeMaterialId);
  }
});

async function loadMaterial(
  supabase: ReturnType<typeof createClient>,
  materialId: string,
  userId: string,
): Promise<Material> {
  const { data, error } = await supabase
    .from("study_materials")
    .select("id,user_id,title,file_hash,status")
    .eq("id", materialId)
    .eq("user_id", userId)
    .maybeSingle();

  if (error) throw new AppError("DB_QUERY_FAILED", "Failed to load study material.", 500, error);
  if (!data) throw new AppError("MATERIAL_NOT_FOUND", "Study material was not found.", 404);
  return data as Material;
}

async function loadConcepts(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  materialId: string,
): Promise<ConceptRow[]> {
  const { data, error } = await supabase
    .from("concepts")
    .select("id,name,description,importance,importance_score,concept_type,evaluation,exclusion_reason,evidence")
    .eq("user_id", userId)
    .eq("material_id", materialId)
    .gte("importance_score", 65)
    .is("exclusion_reason", null)
    .order("importance_score", { ascending: false })
    .limit(50);

  if (error) throw new AppError("DB_QUERY_FAILED", "Database query failed.", 500, error);
  return (data ?? []) as ConceptRow[];
}


function filterUsableConcepts(concepts: ConceptRow[]) {
  return concepts
    .map((concept) => {
      if ((concept.importance_score ?? 0) < 65) return null;
      if (concept.exclusion_reason) return null;
      if (!isQuestionWorthyConceptType(concept.concept_type)) return null;
      const name = sanitizeLearningTerm(concept.name);
      if (!name) return null;
      return { ...concept, name };
    })
    .filter((concept): concept is ConceptRow => concept !== null);
}

async function loadQuestionsByMaterial(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  materialId: string,
) {
  const { data, error } = await supabase
    .from("questions")
    .select("*")
    .eq("user_id", userId)
    .eq("material_id", materialId)
    .eq("initial_batch", true)
    .order("order_index", { ascending: true });

  if (error) throw new AppError("DB_QUERY_FAILED", "Database query failed.", 500, error);
  return data ?? [];
}

async function loadQuestionsBySourceHash(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  sourceHash: string,
  excludeMaterialId: string,
) {
  const { data, error } = await supabase
    .from("questions")
    .select("type,question_text,options,answer,explanation,evidence,difficulty,concept_id,section_id,order_index,concepts(name)")
    .eq("user_id", userId)
    .eq("source_hash", sourceHash)
    .neq("material_id", excludeMaterialId)
    .eq("initial_batch", true)
    .order("order_index", { ascending: true })
    .limit(10);

  if (error) throw new AppError("DB_QUERY_FAILED", "Database query failed.", 500, error);
  return data ?? [];
}

async function copyCachedQuestions({
  supabase,
  userId,
  materialId,
  sourceHash,
  cachedQuestions,
  concepts,
}: {
  supabase: ReturnType<typeof createClient>;
  userId: string;
  materialId: string;
  sourceHash: string;
  cachedQuestions: Record<string, unknown>[];
  concepts: ConceptRow[];
}) {
  const conceptByName = new Map(concepts.map((concept) => [concept.name, concept.id]));
  const rows = cachedQuestions.map((question, index) => {
    const nestedConcept = question.concepts as { name?: unknown } | null;
    const conceptName = typeof nestedConcept?.name === "string" ? nestedConcept.name : "";
    const mappedConceptId = conceptByName.get(conceptName) ?? concepts[index % concepts.length]?.id;
    if (!mappedConceptId) return null;
    return {
    user_id: userId,
    material_id: materialId,
    concept_id: mappedConceptId,
    section_id: question.section_id,
    source_hash: sourceHash,
    type: question.type,
    question_text: koreanVisibleText(question.question_text),
    options: question.type === "multiple_choice" ? sanitizeOptions(Array.isArray(question.options) ? question.options : [], sanitizeLearningTerm(question.answer) ?? "") : [],
    answer: question.type === "ox" ? sanitizeOxAnswer(question.answer) : sanitizeLearningTerm(question.answer),
    explanation: koreanVisibleText(question.explanation),
    evidence: { text: koreanVisibleText(evidenceToText(question.evidence)) },
    difficulty: question.difficulty ?? 3,
    initial_batch: true,
    order_index: index + 1,
    };
  }).filter((row): row is Record<string, unknown> => {
    if (row === null) return false;
    if (!row.question_text || !row.answer || !row.explanation) return false;
    if (row.type === "multiple_choice" && (!Array.isArray(row.options) || row.options.length !== 4 || !row.options.includes(row.answer))) return false;
    return true;
  });

  if (rows.length > 0) {
    const { error } = await supabase
      .from("questions")
      .upsert(rows, { onConflict: "material_id,order_index" });
    if (error) throw new AppError("QUESTIONS_INSERT_FAILED", "Failed to copy cached questions.", 500, error);
  }
  return rows.length;
}

const requiredQuestionMix: Record<QuizQuestion["type"], number> = {
  multiple_choice: 5,
  ox: 3,
  fill_blank: 2,
};

async function generateQuestionsWithOpenAi({
  apiKey,
  materialTitle,
  concepts,
}: {
  apiKey: string;
  materialTitle: string;
  concepts: ConceptRow[];
}): Promise<QuizQuestion[]> {
  const attempts = [1, 2];
  let bestQuestions: QuizQuestion[] = [];

  for (const attempt of attempts) {
    const questions = await requestQuestionsFromOpenAi({
      apiKey,
      materialTitle,
      concepts,
      attempt,
    });
    logQuestionMix("quiz.openai.question_mix", questions, { attempt });

    if (isQuestionMixValid(questions)) {
      return takeRequiredQuestionMix(questions);
    }

    if (questionMixScore(questions) > questionMixScore(bestQuestions)) {
      bestQuestions = questions;
    }

    if (attempt === 1) {
      logStep("quiz.openai.retry", {
        reason: "QUESTION_MIX_INVALID",
        attempt,
        mix: countQuestionMix(questions),
      });
    }
  }

  logQuestionMix("quiz.openai.invalid_final_mix", bestQuestions, {
    reason: "QUESTION_MIX_INVALID",
  });
  throw new AppError("QUESTION_MIX_INVALID", "AI2 did not return a valid 10-question quiz. No fallback questions were generated.", 502, countQuestionMix(bestQuestions));
}

async function requestQuestionsFromOpenAi({
  apiKey,
  materialTitle,
  concepts,
  attempt,
}: {
  apiKey: string;
  materialTitle: string;
  concepts: ConceptRow[];
  attempt: number;
}): Promise<QuizQuestion[]> {
  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini";
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text: "Generate an initial quiz only from provided concepts. Return JSON only. The JSON must contain exactly 10 questions: 5 multiple_choice, 3 ox, and 2 fill_blank. All user-visible question_text, options, answer explanations, hints, and evidence summaries must be written in Korean. Keep domain acronyms such as IFRS17, ALM, and K-ICS as acronyms, but write surrounding explanations in Korean. Do not invent unsupported facts. Never include UUIDs, database IDs, material IDs, storage paths, source hashes, or concept IDs in user-visible text.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: quizPrompt(materialTitle, concepts, attempt),
            },
          ],
        },
      ],
    }),
  });

  const body = await response.text();
  logStep("quiz.openai.response", {
    attempt,
    status: response.status,
    bodyLength: body.length,
    bodyPreview: previewText(body, 1000),
  });
  if (!response.ok) {
    throw new AppError("OPENAI_REQUEST_FAILED", `OpenAI AI2 request failed (${response.status}).`, 502, body);
  }

  let parsed: Record<string, unknown>;
  try {
    const outputText = extractOutputText(JSON.parse(body));
    logStep("quiz.openai.output_text", {
      attempt,
      outputLength: outputText.length,
      outputPreview: previewText(outputText, 1000),
    });
    parsed = parseQuestionPayload(outputText) as Record<string, unknown>;
  } catch (parseError) {
    throw new AppError("OPENAI_PARSE_FAILED", "Failed to parse OpenAI AI2 JSON response.", 502, parseError);
  }

  const rawQuestions = Array.isArray(parsed.questions) ? parsed.questions : [];
  const normalized = rawQuestions
    .map((value: unknown) => normalizeQuestion(value, concepts))
    .filter((question): question is QuizQuestion => question !== null);
  logStep("quiz.openai.normalized", {
    attempt,
    rawQuestionCount: rawQuestions.length,
    normalizedQuestionCount: normalized.length,
    mix: countQuestionMix(normalized),
  });
  return normalized;
}
function quizPrompt(materialTitle: string, concepts: ConceptRow[], attempt = 1) {
  const compactConcepts = concepts.map((concept) => ({
    id: concept.id,
    name: concept.name,
    description: concept.description,
    importance: concept.importance,
    importance_score: concept.importance_score,
    concept_type: concept.concept_type,
    evaluation: concept.evaluation,
    evidence: concept.evidence,
  }));

  return `Material title: ${materialTitle}

Task:
Create exactly 10 original study questions from the concepts below.
The questions array must contain exactly this distribution:
- exactly 5 questions with "type":"multiple_choice"
- exactly 3 questions with "type":"ox"
- exactly 2 questions with "type":"fill_blank"

Rules:
- Return one JSON object only. No markdown. No code fences. No commentary.
- The top-level object must be {"questions":[...]} and questions.length must be 10.
- Use only the concept data below.
- Prioritize concepts with higher importance_score.
- Use concept_type to write suitable exam-style questions.
- Every question must reference one valid concept_id from the input.
- Use concept_id only in the concept_id JSON field for database mapping.
- Never include UUIDs, database IDs, material IDs, concept IDs, or internal identifiers in question_text, options, answer, explanation, or evidence.
- Options and answers must be human-readable Korean study terms or short domain acronyms, not IDs.
- All question_text, options, answer explanations, and evidence summaries must be Korean. Domain acronyms such as IFRS17, ALM, and K-ICS may remain as acronyms.
- section_id must be null if no section id is available.
- difficulty must be an integer from 1 to 5.
- multiple_choice must include exactly 4 options and one answer that matches an option.
- ox answer must be either O or X.
- fill_blank question_text must include ____.
- Do not copy existing textbook questions.
- If this is retry attempt ${attempt}, strictly repair the question type distribution and keep only valid questions.
- Return JSON only with this exact shape:
{"questions":[{"type":"multiple_choice","concept_id":"VALID_INPUT_CONCEPT_ID","section_id":null,"question_text":"...","options":["..."],"answer":"...","explanation":"...","evidence":"...","difficulty":3}]}

Concepts:
${JSON.stringify(compactConcepts)}`;
}


function parseQuestionPayload(outputText: string): unknown {
  const candidates = candidateJsonStrings(outputText);
  for (const candidate of candidates) {
    try {
      const parsed = JSON.parse(candidate);
      if (typeof parsed === "string") return parseQuestionPayload(parsed);
      return parsed;
    } catch (_) {
      // Try the next candidate.
    }
  }
  throw new AppError("OPENAI_PARSE_FAILED", "OpenAI AI2 output did not contain parseable JSON.", 502, previewText(outputText, 1000));
}

function candidateJsonStrings(value: string) {
  const trimmed = stripJsonFence(value);
  const candidates = [trimmed];
  const codeFenceMatch = value.match(new RegExp("```(?:json)?\\s*([\\s\\S]*?)```", "i"));
  if (codeFenceMatch?.[1]) candidates.push(codeFenceMatch[1].trim());
  const firstObject = trimmed.indexOf("{");
  const lastObject = trimmed.lastIndexOf("}");
  if (firstObject >= 0 && lastObject > firstObject) candidates.push(trimmed.slice(firstObject, lastObject + 1));
  return [...new Set(candidates.filter(Boolean))];
}

function countQuestionMix(questions: QuizQuestion[]) {
  return {
    total: questions.length,
    multiple_choice: questions.filter((question) => question.type === "multiple_choice").length,
    ox: questions.filter((question) => question.type === "ox").length,
    fill_blank: questions.filter((question) => question.type === "fill_blank").length,
  };
}

function logQuestionMix(step: string, questions: QuizQuestion[], details: Record<string, unknown> = {}) {
  logStep(step, {
    ...details,
    mix: countQuestionMix(questions),
    questionTypes: questions.map((question) => question.type),
  });
}

function isQuestionMixValid(questions: QuizQuestion[]) {
  const mix = countQuestionMix(questions);
  return mix.total === 10 &&
    mix.multiple_choice === requiredQuestionMix.multiple_choice &&
    mix.ox === requiredQuestionMix.ox &&
    mix.fill_blank === requiredQuestionMix.fill_blank;
}

function questionMixScore(questions: QuizQuestion[]) {
  const mix = countQuestionMix(questions);
  return Math.min(mix.multiple_choice, requiredQuestionMix.multiple_choice) +
    Math.min(mix.ox, requiredQuestionMix.ox) +
    Math.min(mix.fill_blank, requiredQuestionMix.fill_blank);
}

function takeRequiredQuestionMix(questions: QuizQuestion[]) {
  return (["multiple_choice", "ox", "fill_blank"] as QuizQuestion["type"][])
    .flatMap((type) => questions
      .filter((question) => question.type === type)
      .slice(0, requiredQuestionMix[type]));
}

function evidenceToText(value: unknown): string {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (typeof value === "object") {
    const raw = value as Record<string, unknown>;
    if (typeof raw.text === "string") return raw.text;
  }
  try { return JSON.stringify(value); } catch (_) { return String(value); }
}

function normalizeQuestion(value: unknown, concepts: ConceptRow[]): QuizQuestion | null {
  if (!value || typeof value !== "object") return null;
  const raw = value as Record<string, unknown>;
  const type = raw.type;
  if (type !== "multiple_choice" && type !== "ox" && type !== "fill_blank") return null;

  const conceptId = typeof raw.concept_id === "string" ? raw.concept_id : "";
  const concept = concepts.find((concept) => concept.id === conceptId);
  if (!concept) return null;

  const conceptName = safeConceptName(concept);
  let questionText = koreanVisibleText(raw.question_text);
  let answer = type === "ox"
    ? sanitizeOxAnswer(raw.answer)
    : sanitizeLearningTerm(raw.answer) ?? conceptName;
  const explanation = koreanVisibleText(raw.explanation);
  const evidence = koreanVisibleText(raw.evidence);
  if (!questionText || !answer || !explanation || !evidence) return null;

  const rawOptions = Array.isArray(raw.options) ? raw.options : [];
  const options = type === "multiple_choice" ? sanitizeOptions(rawOptions, answer) : [];
  if (type === "multiple_choice" && (options.length !== 4 || !options.includes(answer))) return null;
  if (type === "ox" && answer !== "O" && answer !== "X") return null;
  if (type === "fill_blank" && !questionText.includes("____")) {
    questionText = `____?/??${questionText}`;
  }

  return {
    type,
    concept_id: conceptId,
    section_id: typeof raw.section_id === "string" && !containsInternalIdentifier(raw.section_id) ? raw.section_id : null,
    question_text: questionText,
    options: type === "multiple_choice" ? options : [],
    answer,
    explanation,
    evidence,
    difficulty: Math.max(1, Math.min(5, Math.round(Number(raw.difficulty) || 3))),
  };
}

function sanitizeOptions(
  values: unknown[],
  answer: string,
) {
  const seen = new Set<string>();
  const options = values
    .map((option) => sanitizeLearningTerm(option))
    .filter((option): option is string => Boolean(option))
    .filter((option) => {
      const key = option.toLowerCase();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });

  return options.includes(answer) ? options.slice(0, 4) : [answer, ...options].slice(0, 4);
}

function sanitizeVisibleText(value: unknown) {
  return stripInternalIdentifiers(stringFromUnknown(value))
    .replace(/\s+/g, " ")
    .trim();
}

function koreanVisibleText(value: unknown) {
  const sanitized = sanitizeVisibleText(value);
  if (!sanitized || containsInternalIdentifier(sanitized) || !hasKorean(sanitized)) {
    return "";
  }
  return sanitized;
}

function sanitizeOxAnswer(value: unknown) {
  const sanitized = sanitizeVisibleText(value).toUpperCase();
  return sanitized === "O" || sanitized === "X" ? sanitized : "O";
}

function sanitizeLearningTerm(value: unknown) {
  const original = stringFromUnknown(value);
  if (containsInternalIdentifier(original)) return null;
  const sanitized = sanitizeVisibleText(original);
  if (!sanitized) return null;
  if (containsInternalIdentifier(sanitized)) return null;
  if (!/[A-Za-z媛-??/.test(sanitized)) return null;
  if (looksLikeStoragePath(sanitized)) return null;
  if (!isAllowedLearningTerm(sanitized)) return null;
  if (sanitized.length > 80) return null;
  return sanitized;
}

function stripInternalIdentifiers(value: string) {
  return value
    .replace(uuidPattern(), "")
    .replace(storagePathPattern(), "")
    .replace(hashPattern(), "")
    .replace(fileNamePattern(), "")
    .replace(/\b(?:material|concept|question|section|source)[_-]?id\s*[:=]?\s*/gi, "")
    .replace(/\b(?:materialId|conceptId|questionId|sectionId|sourceHash|storagePath|fileHash)\b\s*[:=]?\s*/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function containsInternalIdentifier(value: string) {
  return uuidPattern().test(value) ||
    storagePathPattern().test(value) ||
    hashPattern().test(value) ||
    fileNamePattern().test(value) ||
    /\b(?:material|concept|question|section|source)[_-]?id\b/i.test(value) ||
    /\b(?:materialId|conceptId|questionId|sectionId|sourceHash|storagePath|fileHash)\b/.test(value) ||
    looksLikeStoragePath(value);
}

function hasKorean(value: string) {
  return /[媛-??/.test(value);
}

function isAllowedLearningTerm(value: string) {
  if (hasKorean(value)) return true;
  const compact = value.trim();
  if (/^[A-Z0-9][A-Z0-9+./&-]{1,24}$/.test(compact)) return true;
  if (/^[A-Z][A-Za-z0-9+./&-]{1,24}$/.test(compact) && !/\s/.test(compact)) return true;
  return false;
}

function looksLikeStoragePath(value: string) {
  return storagePathPattern().test(value) ||
    /(?:^|\s)(?:materials|storage|uploads|public|private)\//i.test(value) ||
    /[A-Za-z]:\\/.test(value) ||
    /\/(?:[^\s/]+\/){1,}[^\s/]+/.test(value);
}

function uuidPattern() {
  return /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/gi;
}

function storagePathPattern() {
  return /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\/[\w.-]+\b/gi;
}

function hashPattern() {
  return /\b[0-9a-f]{32,128}\b/gi;
}

function fileNamePattern() {
  return /\b[^\s]+\.(?:pdf|docx?|pptx?|xlsx?|png|jpe?g|txt|md|hwp|hwpx)\b/gi;
}

function isQuestionWorthyConceptType(value: unknown) {
  const type = typeof value === "string" ? value : "";
  return new Set([
    "core_concept",
    "technical_term",
    "definition",
    "formula_or_metric",
    "regulation_or_standard",
    "process_step",
    "comparison_point",
    "prerequisite_concept",
    "acronym",
  ]).has(type);
}

function safeConceptName(concept: ConceptRow) {
  return sanitizeLearningTerm(concept.name) ?? "?듭떖 媛쒕뀗";
}

function stringFromUnknown(value: unknown): string {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  try {
    return JSON.stringify(value);
  } catch (_) {
    return String(value);
  }
}
function validateQuestionMix(questions: QuizQuestion[]) {
  const multipleChoice = questions.filter((question) => question.type === "multiple_choice").length;
  const ox = questions.filter((question) => question.type === "ox").length;
  const fillBlank = questions.filter((question) => question.type === "fill_blank").length;
  if (questions.length !== 10 || multipleChoice !== 5 || ox !== 3 || fillBlank !== 2) {
    throw new AppError("QUESTION_MIX_INVALID", "AI2 must generate exactly 5 multiple_choice, 3 ox, and 2 fill_blank questions.", 502);
  }
}

async function saveQuestions({
  supabase,
  userId,
  materialId,
  sourceHash,
  questions,
}: {
  supabase: ReturnType<typeof createClient>;
  userId: string;
  materialId: string;
  sourceHash: string;
  questions: QuizQuestion[];
}) {
  const rows = questions.map((question, index) => ({
    user_id: userId,
    material_id: materialId,
    concept_id: question.concept_id,
    section_id: question.section_id,
    source_hash: sourceHash,
    type: question.type,
    question_text: question.question_text,
    options: question.options,
    answer: question.answer,
    explanation: question.explanation,
    evidence: { text: question.evidence },
    difficulty: question.difficulty,
    initial_batch: true,
    order_index: index + 1,
  }));

  const { error } = await supabase
    .from("questions")
    .upsert(rows, { onConflict: "material_id,order_index" });
  if (error) throw new AppError("QUESTIONS_INSERT_FAILED", "Failed to insert generated questions.", 500, error);
}

async function updateMaterial(
  supabase: ReturnType<typeof createClient>,
  materialId: string,
  values: Record<string, unknown>,
) {
  const { error } = await supabase
    .from("study_materials")
    .update({ ...values, updated_at: new Date().toISOString() })
    .eq("id", materialId);
  if (error) throw new AppError("DB_UPDATE_FAILED", "Failed to update study material.", 500, error);
}

async function markMaterialFailed(
  supabase: ReturnType<typeof createClient>,
  materialId: string,
  message: string,
) {
  try {
    await updateMaterial(supabase, materialId, {
      status: "failed",
      analysis_error: message,
    });
  } catch (_) {
    // Keep the original error response if failure marking also fails.
  }
}

function extractOutputText(responseJson: Record<string, unknown>) {
  if (typeof responseJson.output_text === "string" && responseJson.output_text.trim()) {
    return responseJson.output_text;
  }

  const output = Array.isArray(responseJson.output) ? responseJson.output : [];
  let text = "";
  for (const item of output) {
    if (!item || typeof item !== "object") continue;
    const content = Array.isArray((item as Record<string, unknown>).content)
      ? ((item as Record<string, unknown>).content as unknown[])
      : [];
    for (const part of content) {
      if (part && typeof part === "object" && typeof (part as Record<string, unknown>).text === "string") {
        text += (part as Record<string, string>).text;
      }
    }
  }

  if (!text.trim()) {
    throw new AppError("OPENAI_PARSE_FAILED", "OpenAI AI2 response did not include output text.", 502);
  }
  return text.trim();
}

function stripJsonFence(value: string) {
  return value.trim().replace(/^```(?:json)?\s*/, "").replace(/\s*```$/, "").trim();
}

function previewText(value: string, maxLength: number) {
  return value.replace(/\s+/g, " ").trim().slice(0, maxLength);
}
function serializeError(error: unknown) {
  if (error instanceof AppError) {
    return {
      code: error.code,
      message: error.message,
      status: error.status,
      details: serializeUnknown(error.cause),
    };
  }
  if (error instanceof Error) {
    return {
      code: "UNKNOWN_ERROR" as ErrorCode,
      message: error.message,
      status: 500,
      details: serializeUnknown(error),
    };
  }
  return {
    code: "UNKNOWN_ERROR" as ErrorCode,
    message: serializeUnknown(error),
    status: 500,
    details: serializeUnknown(error),
  };
}

function serializeUnknown(value: unknown): string {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  if (value instanceof Error) return value.stack ?? value.message;
  try {
    return JSON.stringify(value);
  } catch (_) {
    return Object.prototype.toString.call(value);
  }
}

function errorJson(error: unknown, materialId: string | null) {
  const serialized = serializeError(error);
  return json({
    error: serialized.message,
    code: serialized.code,
    details: serialized.details,
    materialId,
  }, serialized.status);
}

function logStep(step: string, details: Record<string, unknown> = {}) {
  console.log(JSON.stringify({ step, ...details }));
}

function json(value: unknown, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}






