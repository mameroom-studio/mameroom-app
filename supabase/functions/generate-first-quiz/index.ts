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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let activeSupabase: ReturnType<typeof createClient> | null = null;
  let activeMaterialId: string | null = null;

  try {
    const openAiApiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openAiApiKey) {
      throw new Error("OPENAI_API_KEY must be configured as a Supabase Edge Function secret.");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error("Supabase Edge Function environment is missing SUPABASE_URL or SUPABASE_ANON_KEY.");
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    activeSupabase = supabase;

    const { data: authData, error: authError } = await supabase.auth.getUser();
    if (authError || !authData.user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const { materialId } = await req.json();
    if (typeof materialId !== "string" || materialId.length === 0) {
      return json({ error: "materialId is required" }, 400);
    }
    activeMaterialId = materialId;

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
      return json({ error: "generate-first-quiz requires status concepts_completed." }, 409);
    }

    const concepts = await loadConcepts(supabase, authData.user.id, material.id);
    if (concepts.length === 0) {
      throw new Error("No concepts found for this material.");
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

    await updateMaterial(supabase, material.id, { status: "questions_generating" });
    const questions = await generateQuestionsWithOpenAi({
      apiKey: openAiApiKey,
      materialTitle: material.title,
      concepts,
    });

    validateQuestionMix(questions);
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
    const message = error instanceof Error ? error.message : String(error);
    if (activeSupabase && activeMaterialId) {
      await markMaterialFailed(activeSupabase, activeMaterialId, message);
    }
    return json({ error: message }, 500);
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

  if (error) throw error;
  if (!data) throw new Error("Study material was not found.");
  return data as Material;
}

async function loadConcepts(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  materialId: string,
): Promise<ConceptRow[]> {
  const { data, error } = await supabase
    .from("concepts")
    .select("id,name,description,importance,evidence")
    .eq("user_id", userId)
    .eq("material_id", materialId)
    .order("importance", { ascending: false })
    .limit(50);

  if (error) throw error;
  return (data ?? []) as ConceptRow[];
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

  if (error) throw error;
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

  if (error) throw error;
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
    question_text: question.question_text,
    options: question.options ?? [],
    answer: question.answer,
    explanation: question.explanation,
    evidence: question.evidence ?? {},
    difficulty: question.difficulty ?? 3,
    initial_batch: true,
    order_index: index + 1,
    };
  }).filter((row): row is Record<string, unknown> => row !== null);

  if (rows.length > 0) {
    const { error } = await supabase
      .from("questions")
      .upsert(rows, { onConflict: "material_id,order_index" });
    if (error) throw error;
  }
  return rows.length;
}

async function generateQuestionsWithOpenAi({
  apiKey,
  materialTitle,
  concepts,
}: {
  apiKey: string;
  materialTitle: string;
  concepts: ConceptRow[];
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
              text: "Generate an initial quiz only from provided concepts. Do not invent unsupported facts. Return JSON only.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: quizPrompt(materialTitle, concepts),
            },
          ],
        },
      ],
    }),
  });

  const body = await response.text();
  if (!response.ok) {
    throw new Error(`OpenAI AI2 request failed (${response.status}): ${body}`);
  }

  const outputText = extractOutputText(JSON.parse(body));
  const parsed = JSON.parse(stripJsonFence(outputText));
  const rawQuestions = Array.isArray(parsed.questions) ? parsed.questions : [];
  return rawQuestions
    .map((value: unknown) => normalizeQuestion(value, concepts))
    .filter((question): question is QuizQuestion => question !== null)
    .slice(0, 10);
}

function quizPrompt(materialTitle: string, concepts: ConceptRow[]) {
  const compactConcepts = concepts.map((concept) => ({
    id: concept.id,
    name: concept.name,
    description: concept.description,
    importance: concept.importance,
    evidence: concept.evidence,
  }));

  return `Material title: ${materialTitle}

Task:
Create exactly 10 original study questions from the concepts below:
- 5 multiple_choice
- 3 ox
- 2 fill_blank

Rules:
- Use only the concept data below.
- Every question must reference one valid concept_id from the input.
- section_id must be null if no section id is available.
- difficulty must be an integer from 1 to 5.
- multiple_choice must include exactly 4 options and one answer that matches an option.
- ox answer must be either O or X.
- fill_blank question_text must include ____.
- Do not copy existing textbook questions.
- Return JSON only with this shape:
{"questions":[{"type":"multiple_choice","concept_id":"uuid","section_id":null,"question_text":"...","options":["..."],"answer":"...","explanation":"...","evidence":"...","difficulty":3}]}

Concepts:
${JSON.stringify(compactConcepts)}`;
}

function normalizeQuestion(value: unknown, concepts: ConceptRow[]): QuizQuestion | null {
  if (!value || typeof value !== "object") return null;
  const raw = value as Record<string, unknown>;
  const type = raw.type;
  if (type !== "multiple_choice" && type !== "ox" && type !== "fill_blank") return null;

  const conceptId = typeof raw.concept_id === "string" ? raw.concept_id : "";
  if (!concepts.some((concept) => concept.id === conceptId)) return null;

  const questionText = typeof raw.question_text === "string" ? raw.question_text.trim() : "";
  const answer = typeof raw.answer === "string" ? raw.answer.trim() : "";
  const explanation = typeof raw.explanation === "string" ? raw.explanation.trim() : "";
  const evidence = typeof raw.evidence === "string" ? raw.evidence.trim() : "";
  if (!questionText || !answer || !explanation || !evidence) return null;

  const rawOptions = Array.isArray(raw.options) ? raw.options : [];
  const options = rawOptions.map((option) => String(option).trim()).filter(Boolean);
  if (type === "multiple_choice" && (options.length !== 4 || !options.includes(answer))) return null;
  if (type === "ox" && answer !== "O" && answer !== "X") return null;
  if (type === "fill_blank" && !questionText.includes("____")) return null;

  return {
    type,
    concept_id: conceptId,
    section_id: typeof raw.section_id === "string" ? raw.section_id : null,
    question_text: questionText,
    options: type === "multiple_choice" ? options : [],
    answer,
    explanation,
    evidence,
    difficulty: Math.max(1, Math.min(5, Math.round(Number(raw.difficulty) || 3))),
  };
}

function validateQuestionMix(questions: QuizQuestion[]) {
  const multipleChoice = questions.filter((question) => question.type === "multiple_choice").length;
  const ox = questions.filter((question) => question.type === "ox").length;
  const fillBlank = questions.filter((question) => question.type === "fill_blank").length;
  if (questions.length !== 10 || multipleChoice !== 5 || ox !== 3 || fillBlank !== 2) {
    throw new Error("AI2 must generate exactly 5 multiple_choice, 3 ox, and 2 fill_blank questions.");
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
  if (error) throw error;
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
  if (error) throw error;
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
    throw new Error("OpenAI AI2 response did not include output text.");
  }
  return text.trim();
}

function stripJsonFence(value: string) {
  return value.trim().replace(/^```(?:json)?\s*/, "").replace(/\s*```$/, "").trim();
}

function json(value: unknown, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}