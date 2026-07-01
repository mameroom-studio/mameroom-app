import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Material = {
  id: string;
  user_id: string;
  title: string;
  source_type: string;
  file_hash: string;
  storage_path: string | null;
  raw_text: string | null;
  structured_text: string | null;
  status: string;
};

type Concept = {
  name: string;
  description: string;
  importance: number;
  evidence: string;
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
    if (material.status === "concepts_completed" || material.status === "completed") {
      const conceptCount = await countConcepts(supabase, materialId);
      return json({
        materialId,
        status: "concepts_completed",
        conceptCount,
        usedCache: false,
        message: "Core concepts are already extracted.",
      });
    }

    const sameHash = await findSameHashMaterial(
      supabase,
      authData.user.id,
      material.id,
      material.file_hash,
    );
    if (sameHash && sameHash.status !== "concepts_completed" && sameHash.status !== "completed") {
      await updateMaterial(supabase, material.id, {
        status: "failed",
        analysis_error: "The same file hash already has an analysis job.",
      });
      return json({ error: "The same file hash already has an analysis job." }, 409);
    }
    if (sameHash && (sameHash.status === "concepts_completed" || sameHash.status === "completed")) {
      const copiedCount = await copyCachedConcepts(
        supabase,
        authData.user.id,
        sameHash.id,
        material.id,
        sameHash.structured_text,
      );
      await updateMaterial(supabase, material.id, {
        status: "concepts_completed",
        analysis_completed_at: new Date().toISOString(),
      });
      return json({
        materialId,
        status: "concepts_completed",
        conceptCount: copiedCount,
        usedCache: true,
        message: "Reused cached analysis for the same file hash.",
      });
    }

    await updateMaterial(supabase, material.id, { status: "extracting" });
    const structuredText = extractStructuredText(material);

    await updateMaterial(supabase, material.id, {
      status: "analyzing",
      structured_text: structuredText,
    });
    const concepts = await extractConceptsWithOpenAi({
      apiKey: openAiApiKey,
      title: material.title,
      structuredText,
    });

    await saveConcepts(supabase, authData.user.id, material.id, concepts);

    await updateMaterial(supabase, material.id, {
      status: "concepts_completed",
      analysis_completed_at: new Date().toISOString(),
    });

    return json({
      materialId,
      status: "concepts_completed",
      conceptCount: concepts.length,
      usedCache: false,
      message: "Core concepts extracted by extract-core-concepts.",
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (activeSupabase && activeMaterialId) {
      await markMaterialFailed(activeSupabase, activeMaterialId, message);
    }
    return json({ error: message }, 500);
  }
});

async function loadMaterial(supabase: ReturnType<typeof createClient>, materialId: string, userId: string): Promise<Material> {
  const { data, error } = await supabase
    .from("study_materials")
    .select("id,user_id,title,source_type,file_hash,storage_path,raw_text,structured_text,status")
    .eq("id", materialId)
    .eq("user_id", userId)
    .maybeSingle();

  if (error) throw error;
  if (!data) throw new Error("Study material was not found.");
  return data as Material;
}

async function findSameHashMaterial(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  materialId: string,
  fileHash: string,
) {
  const { data, error } = await supabase
    .from("study_materials")
    .select("id,status,structured_text")
    .eq("user_id", userId)
    .eq("file_hash", fileHash)
    .neq("id", materialId)
    .limit(1);

  if (error) throw error;
  return data?.[0] ?? null;
}

async function copyCachedConcepts(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  fromMaterialId: string,
  toMaterialId: string,
  structuredText: string | null,
) {
  if (structuredText) {
    const { error } = await supabase
      .from("study_materials")
      .update({ structured_text: structuredText })
      .eq("id", toMaterialId)
      .eq("user_id", userId);
    if (error) throw error;
  }

  const { data, error } = await supabase
    .from("concepts")
    .select("name,description,importance,evidence")
    .eq("material_id", fromMaterialId)
    .eq("user_id", userId);
  if (error) throw error;

  const rows = (data ?? []).map((concept) => ({
    user_id: userId,
    material_id: toMaterialId,
    name: concept.name,
    description: concept.description,
    importance: concept.importance,
    evidence: concept.evidence,
  }));

  if (rows.length > 0) {
    const { error: upsertError } = await supabase
      .from("concepts")
      .upsert(rows, { onConflict: "material_id,name" });
    if (upsertError) throw upsertError;
  }

  return rows.length;
}

function extractStructuredText(material: Material) {
  if (material.structured_text?.trim()) {
    return material.structured_text.trim();
  }

  if (material.source_type === "text") {
    if (!material.raw_text?.trim()) {
      throw new Error("Text material does not include raw_text for analysis.");
    }
    return `Title: ${material.title}\nSource type: text\n\n${material.raw_text.trim()}`;
  }

  return `Title: ${material.title}\nSource type: ${material.source_type}\nStorage path: ${material.storage_path ?? ""}\n\nPDF/OCR extraction adapter is prepared for this file type. Replace this metadata-only fallback with a server-side parser before production.`;
}

async function extractConceptsWithOpenAi({
  apiKey,
  title,
  structuredText,
}: {
  apiKey: string;
  title: string;
  structuredText: string;
}): Promise<Concept[]> {
  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini";
  const clippedText = structuredText.length > 12000 ? structuredText.slice(0, 12000) : structuredText;

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
              text: "Extract study-worthy concepts only from the provided material. Return JSON only. Do not create quiz questions.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: conceptPrompt(title, clippedText),
            },
          ],
        },
      ],
    }),
  });

  const body = await response.text();
  if (!response.ok) {
    throw new Error(`OpenAI AI1 request failed (${response.status}): ${body}`);
  }

  const outputText = extractOutputText(JSON.parse(body));
  const parsed = JSON.parse(stripJsonFence(outputText));
  const concepts = Array.isArray(parsed.concepts) ? parsed.concepts : [];
  return concepts
    .map(normalizeConcept)
    .filter((concept): concept is Concept => concept !== null)
    .slice(0, 50);
}

function conceptPrompt(title: string, clippedText: string) {
  return `Material title: ${title}

Task:
Extract up to 50 core concepts or technical terms that are valuable for memorization.
Use only the material below. If evidence is weak, omit the concept.
Return exactly this JSON shape:
{"concepts":[{"name":"short concept name","description":"one sentence based only on the material","importance":1,"evidence":"short supporting phrase from the material"}]}
Importance must be an integer from 1 to 5.
Do not generate questions.
Do not include markdown.

Material:
${clippedText}`;
}

function normalizeConcept(value: unknown): Concept | null {
  if (!value || typeof value !== "object") return null;
  const raw = value as Record<string, unknown>;
  const name = typeof raw.name === "string" ? raw.name.trim() : "";
  if (!name) return null;

  const importance = Math.max(1, Math.min(5, Math.round(Number(raw.importance) || 3)));
  return {
    name,
    description: typeof raw.description === "string" ? raw.description.trim() : "",
    importance,
    evidence: typeof raw.evidence === "string" ? raw.evidence.trim() : "",
  };
}

async function saveConcepts(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  materialId: string,
  concepts: Concept[],
) {
  if (concepts.length === 0) return;

  const rows = concepts.map((concept) => ({
    user_id: userId,
    material_id: materialId,
    name: concept.name,
    description: concept.description,
    importance: concept.importance,
    evidence: { text: concept.evidence },
  }));

  const { error } = await supabase
    .from("concepts")
    .upsert(rows, { onConflict: "material_id,name" });
  if (error) throw error;
}

async function countConcepts(supabase: ReturnType<typeof createClient>, materialId: string) {
  const { data, error } = await supabase
    .from("concepts")
    .select("id")
    .eq("material_id", materialId);
  if (error) throw error;
  return data?.length ?? 0;
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
    throw new Error("OpenAI AI1 response did not include output text.");
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