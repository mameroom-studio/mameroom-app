import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as pdfjsLib from "https://esm.sh/pdfjs-dist@4.10.38/legacy/build/pdf.mjs?bundle";
import * as pdfjsWorker from "https://esm.sh/pdfjs-dist@4.10.38/legacy/build/pdf.worker.mjs?bundle";
import { MIN_USABLE_CONCEPTS, type Concept } from "../shared/ai/concept_extractor.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const PDFJS_CMAP_URL = "https://esm.sh/pdfjs-dist@4.10.38/cmaps/";
const PDFJS_STANDARD_FONT_DATA_URL = "https://esm.sh/pdfjs-dist@4.10.38/standard_fonts/";
const MATERIALS_BUCKET = "materials";
const requiredPdfInputTerms = [
  "ALM",
  "AiR",
  "IFRS17",
  "K-ICS",
  "ORSA",
  "DR",
  "PV 검증",
  "준비금 검증",
  "위험률 산출",
];

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

type ErrorCode =
  | "CONFIGURATION_ERROR"
  | "UNAUTHORIZED"
  | "INVALID_REQUEST"
  | "MATERIAL_NOT_FOUND"
  | "DUPLICATE_ANALYSIS_IN_PROGRESS"
  | "PDF_DOWNLOAD_FAILED"
  | "PDF_PARSE_FAILED"
  | "PDF_TEXT_EMPTY"
  | "OPENAI_REQUEST_FAILED"
  | "OPENAI_PARSE_FAILED"
  | "CONCEPTS_EMPTY"
  | "CONCEPTS_INSUFFICIENT"
  | "CONCEPTS_INSERT_FAILED"
  | "DB_UPDATE_FAILED"
  | "RLS_POLICY_DENIED"
  | "STATUS_CHECK_FAILED"
  | "MATERIAL_UPDATE_NOT_ALLOWED"
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
  let activeUserId: string | null = null;

  try {
    logStep("extract.start");
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
    activeUserId = authData.user.id;

    const { materialId } = await req.json();
    if (typeof materialId !== "string" || materialId.length === 0) {
      return errorJson(new AppError("INVALID_REQUEST", "materialId is required", 400), activeMaterialId);
    }
    activeMaterialId = materialId;
    logStep("extract.material.request", { materialId });

    const material = await loadMaterial(supabase, materialId, authData.user.id);
    if (material.status === "completed") {
      const conceptCount = await countConcepts(supabase, materialId);
      return json({
        materialId,
        status: "generating",
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
    if (sameHash && sameHash.status !== "completed") {
      await updateMaterial(supabase, material.id, {
        status: "failed",
        analysis_error: "DUPLICATE_ANALYSIS_IN_PROGRESS: The same file hash already has an analysis job.",
      }, authData.user.id);
      return errorJson(new AppError("DUPLICATE_ANALYSIS_IN_PROGRESS", "The same file hash already has an analysis job.", 409), material.id);
    }
    if (sameHash && sameHash.status === "completed") {
      const copiedCount = await copyCachedConcepts(
        supabase,
        authData.user.id,
        sameHash.id,
        material.id,
        sameHash.structured_text,
      );
      if (copiedCount < MIN_USABLE_CONCEPTS) {
        throw new AppError("CONCEPTS_INSUFFICIENT", `Cached analysis has only ${copiedCount} usable concepts. At least ${MIN_USABLE_CONCEPTS} are required.`, 422);
      }
      await updateMaterial(supabase, material.id, {
        status: "generating",
        analysis_completed_at: new Date().toISOString(),
      }, authData.user.id);
      return json({
        materialId,
        status: "generating",
        conceptCount: copiedCount,
        usedCache: true,
        message: "Reused cached analysis for the same file hash.",
      });
    }

    logStep("extract.status.generating", { materialId: material.id });
    await updateMaterial(supabase, material.id, { status: "generating" }, authData.user.id);
    const extractedText = await extractStructuredText(supabase, material);
    const structuredText = extractedText.structuredText;
    logStep("extract.text.ready", {
      materialId: material.id,
      sourceType: material.source_type,
      rawTextLength: extractedText.rawText.length,
      structuredTextLength: structuredText.length,
      sectionCount: extractedText.sectionCount,
      openAiInputPreview: previewText(structuredText, 2000),
    });

    if (material.source_type === "pdf") {
      logStep("extract.pdf.text_ready", {
        materialId: material.id,
        textLength: extractedText.rawText.length,
        structuredLength: structuredText.length,
        sectionCount: extractedText.sectionCount,
        textPreview: previewText(structuredText, 800),
        requiredTermHits: requiredPdfInputTerms.filter((term) => structuredText.includes(term)),
      });
    }

    await updateMaterial(supabase, material.id, {
      status: "generating",
      raw_text: extractedText.rawText,
      structured_text: structuredText,
    }, authData.user.id);
    logStep("extract.openai.start", { materialId: material.id });
    const concepts = await extractConceptsWithOpenAi({
      apiKey: openAiApiKey,
      title: material.title,
      structuredText,
    });

    const fallbackConcepts = fallbackConceptsFromText(structuredText, material.title);
    let conceptsToSave = mergeConceptsByName(concepts);
    let usableConcepts = usableConceptsForQuiz(conceptsToSave);
    if (usableConcepts.length < MIN_USABLE_CONCEPTS) {
      const beforeSupplementCount = usableConcepts.length;
      conceptsToSave = mergeConceptsByName([...conceptsToSave, ...fallbackConcepts]);
      usableConcepts = usableConceptsForQuiz(conceptsToSave);
      logStep("extract.concepts.fallback_supplement", {
        materialId: material.id,
        openAiConceptCount: concepts.length,
        fallbackConceptCount: fallbackConcepts.length,
        usableBeforeSupplement: beforeSupplementCount,
        usableAfterSupplement: usableConcepts.length,
        fallbackConcepts: fallbackConcepts.map(conceptLogSummary),
      });
    }
    const usabilityDiagnostics = conceptUsabilityDiagnostics(conceptsToSave);
    logStep("extract.concepts.quality_gate", {
      materialId: material.id,
      candidateCount: conceptsToSave.length,
      usableCount: usableConcepts.length,
      candidates: conceptsToSave.map(conceptLogSummary),
      rejectedConcepts: usabilityDiagnostics
        .filter((diagnostic) => diagnostic.rejection_reason)
        .map((diagnostic) => ({
          name: diagnostic.name,
          rejection_reason: diagnostic.rejection_reason,
          importance_score: diagnostic.importance_score,
          concept_type: diagnostic.concept_type,
          exclusion_reason: diagnostic.exclusion_reason,
        })),
      usableConcepts: usableConcepts.map(conceptLogSummary),
    });
    if (usableConcepts.length === 0) {
      throw new AppError("CONCEPTS_EMPTY", "No exam-worthy concepts found after deterministic filtering and importance evaluation.", 422);
    }
    if (usableConcepts.length < MIN_USABLE_CONCEPTS) {
      throw new AppError("CONCEPTS_INSUFFICIENT", `Only ${usableConcepts.length} usable concepts found. At least ${MIN_USABLE_CONCEPTS} are required for quiz generation.`, 422);
    }
    logStep("extract.concepts.save.start", {
      materialId: material.id,
      conceptCount: usableConcepts.length,
      concepts: usableConcepts.map((concept) => ({
        name: concept.name,
        importance_score: concept.importance_score,
        concept_type: concept.concept_type,
      })),
    });
    await saveConcepts(supabase, authData.user.id, material.id, usableConcepts);

    await updateMaterial(supabase, material.id, {
      status: "generating",
      analysis_completed_at: new Date().toISOString(),
    }, authData.user.id);

    return json({
      materialId,
      status: "generating",
      conceptCount: usableConcepts.length,
      usedCache: false,
      message: "Core concepts extracted by extract-core-concepts.",
    });
  } catch (error) {
    const serialized = serializeError(error);
    logStep("extract.error", { materialId: activeMaterialId, error: serialized });
    if (activeSupabase && activeMaterialId) {
      await markMaterialFailed(activeSupabase, activeMaterialId, `${serialized.code}: ${serialized.message}`, activeUserId);
    }
    return errorJson(error, activeMaterialId);
  }
});

async function loadMaterial(supabase: ReturnType<typeof createClient>, materialId: string, userId: string): Promise<Material> {
  const { data, error } = await supabase
    .from("study_materials")
    .select("id,user_id,title,source_type,file_hash,storage_path,raw_text,structured_text,status")
    .eq("id", materialId)
    .eq("user_id", userId)
    .maybeSingle();

  if (error) throw new AppError("DB_QUERY_FAILED", "Failed to load study material.", 500, error);
  if (!data) throw new AppError("MATERIAL_NOT_FOUND", "Study material was not found.", 404);
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
    .neq("status", "failed")
    .limit(1);

  if (error) throw new AppError("DB_QUERY_FAILED", "Failed to find same file hash material.", 500, error);
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
    await updateMaterial(supabase, toMaterialId, { structured_text: structuredText }, userId);
  }

  const { data, error } = await supabase
    .from("concepts")
    .select("name,description,importance,importance_score,concept_type,evaluation,exclusion_reason,evidence")
    .eq("material_id", fromMaterialId)
    .eq("user_id", userId);
  if (error) throw new AppError("DB_QUERY_FAILED", "Failed to load cached concepts.", 500, error);

  const rows = (data ?? []).map((concept) => ({
    user_id: userId,
    material_id: toMaterialId,
    name: concept.name,
    description: concept.description,
    importance: concept.importance,
    importance_score: concept.importance_score ?? concept.importance * 20,
    concept_type: concept.concept_type ?? "core_concept",
    evaluation: concept.evaluation ?? {},
    exclusion_reason: concept.exclusion_reason ?? null,
    evidence: concept.evidence,
  }));

  if (rows.length > 0) {
    const { error: upsertError } = await supabase
      .from("concepts")
      .upsert(rows, { onConflict: "material_id,name" });
    if (upsertError) throw new AppError("CONCEPTS_INSERT_FAILED", "Failed to copy cached concepts.", 500, upsertError);
  }

  return rows.length;
}

type ExtractedMaterialText = {
  rawText: string;
  structuredText: string;
  sectionCount: number;
};

async function extractStructuredText(
  supabase: ReturnType<typeof createClient>,
  material: Material,
): Promise<ExtractedMaterialText> {
  if (material.structured_text?.trim()) {
    const structuredText = material.structured_text.trim();
    return {
      rawText: material.raw_text?.trim() || structuredText,
      structuredText,
      sectionCount: estimateSectionCount(structuredText),
    };
  }

  if (material.source_type === "pdf") {
    return extractPdfStructuredText(supabase, material);
  }

  if (material.source_type === "text") {
    if (!material.raw_text?.trim()) {
      throw new AppError("INVALID_REQUEST", "Text material does not include raw_text for analysis.", 400);
    }
    const rawText = normalizeExtractedPdfText(material.raw_text);
    const structuredText = `Title: ${material.title}\nSource type: text\n\n${rawText}`;
    return {
      rawText,
      structuredText,
      sectionCount: estimateSectionCount(structuredText),
    };
  }

  throw new AppError("INVALID_REQUEST", `Unsupported source_type for text extraction: ${material.source_type}`, 400);
}

async function extractPdfStructuredText(
  supabase: ReturnType<typeof createClient>,
  material: Material,
): Promise<ExtractedMaterialText> {
  if (!material.storage_path?.trim()) {
    throw new AppError("PDF_DOWNLOAD_FAILED", "PDF material does not include storage_path.", 422);
  }

  const pdfBytes = await downloadPdfBytes(supabase, material.storage_path);
  const pages = await extractPdfPages(pdfBytes);
  const rawText = normalizeExtractedPdfText(pages.map((page) => page.text).join("\n\n"));
  if (rawText.trim().length === 0) {
    throw new AppError("PDF_TEXT_EMPTY", "PDF text extraction returned empty text.", 422);
  }

  const structuredText = buildPdfStructuredText(material.title, pages);
  return {
    rawText,
    structuredText,
    sectionCount: pages.filter((page) => page.text.trim().length > 0).length,
  };
}

async function downloadPdfBytes(
  supabase: ReturnType<typeof createClient>,
  storagePath: string,
) {
  const { data, error } = await supabase.storage
    .from(MATERIALS_BUCKET)
    .download(storagePath);
  logStep("extract.pdf.storage_download", {
    success: !error && Boolean(data),
    storagePath,
    error: error ? serializeUnknown(error) : null,
  });
  if (error || !data) {
    throw new AppError("PDF_DOWNLOAD_FAILED", "Failed to download PDF from Supabase Storage.", 502, error);
  }

  const bytes = new Uint8Array(await data.arrayBuffer());
  logStep("extract.pdf.downloaded", {
    byteSize: bytes.length,
    headerPreview32Bytes: Array.from(bytes.slice(0, 32)),
    headerPreview32Text: String.fromCharCode(...bytes.slice(0, 32)).replace(/[^\x20-\x7E]/g, "."),
  });
  if (bytes.length === 0) {
    throw new AppError("PDF_DOWNLOAD_FAILED", "Downloaded PDF was empty.", 502);
  }
  return bytes;
}

async function extractPdfPages(pdfBytes: Uint8Array) {
  try {
    logStep("extract.pdf.pdfjs_get_document.start", {
      byteSize: pdfBytes.length,
    });
    configurePdfJsNoWorker();
    const loadingTask = pdfjsLib.getDocument({
      data: pdfBytes,
      disableWorker: true,
      useSystemFonts: true,
      isEvalSupported: false,
      cMapUrl: PDFJS_CMAP_URL,
      cMapPacked: true,
      standardFontDataUrl: PDFJS_STANDARD_FONT_DATA_URL,
    });
    const pdf = await loadingTask.promise;
    logStep("extract.pdf.pdfjs_get_document.success", {
      success: true,
      numPages: pdf.numPages,
    });
    const pages: Array<{ pageNumber: number; text: string }> = [];
    try {
      for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
        const page = await pdf.getPage(pageNumber);
        let content;
        try {
          content = await page.getTextContent({ includeMarkedContent: false, disableNormalization: false });
          logStep("extract.pdf.page_text_content.success", {
            pageNumber,
            success: true,
            itemCount: content.items.length,
          });
        } catch (pageError) {
          logStep("extract.pdf.page_text_content.error", {
            pageNumber,
            success: false,
            error: serializeUnknown(pageError),
            stack: pageError instanceof Error ? pageError.stack : null,
          });
          throw pageError;
        }
        const text = normalizeExtractedPdfText(
          content.items
            .map((item: unknown) => {
              const maybeTextItem = item as { str?: unknown };
              return typeof maybeTextItem.str === "string" ? maybeTextItem.str : "";
            })
            .filter(Boolean)
            .join(" "),
        );
        logStep("extract.pdf.page_text_extracted", {
          pageNumber,
          textLength: text.length,
          textPreview200: previewText(text, 200),
        });
        pages.push({ pageNumber, text });
      }
    } finally {
      await pdf.destroy();
    }
    return pages;
  } catch (error) {
    logStep("extract.pdf.parse_failed", {
      pdfParseFailedLine: "supabase/functions/extract-core-concepts/index.ts:506",
      error: serializeUnknown(error),
      stack: error instanceof Error ? error.stack : null,
    });
    throw new AppError("PDF_PARSE_FAILED", "Failed to parse text layer from PDF.", 502, error);
  }
}

function configurePdfJsNoWorker() {
  (globalThis as unknown as {
    pdfjsWorker?: typeof pdfjsWorker;
  }).pdfjsWorker = pdfjsWorker;
}

function buildPdfStructuredText(title: string, pages: Array<{ pageNumber: number; text: string }>) {
  const sections = pages
    .filter((page) => page.text.trim().length > 0)
    .map((page) => `[Page ${page.pageNumber}]\n${page.text.trim()}`);
  return normalizeExtractedPdfText([`Title: ${title}`, ...sections].join("\n\n"));
}

function normalizeExtractedPdfText(value: string) {
  return value
    .replace(/\u0000/g, "")
    .replace(/[ \t]+/g, " ")
    .replace(/\s+\n/g, "\n")
    .replace(/\n\s+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function hasRequiredPdfInputSignal(structuredText: string) {
  const hitCount = requiredPdfInputTerms.filter((term) => structuredText.includes(term)).length;
  return hitCount >= 2;
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
  logStep("extract.openai.input", {
    textLength: structuredText.length,
    clippedTextLength: clippedText.length,
    sectionCount: estimateSectionCount(structuredText),
    textPreview: previewText(clippedText, 2000),
  });

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
              text: "You are an expert Korean insurance, finance, accounting, and certification exam item writer. Extract candidate concepts first, then evaluate exam-worthiness. Return valid JSON only. Do not create quiz questions. Exclude metadata, UUIDs, file names, file paths, storage paths, hashes, and generic words.",
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
  logStep("extract.openai.response", {
    status: response.status,
    bodyLength: body.length,
    rawResponsePreview: previewText(body, 2000),
  });
  if (!response.ok) {
    throw new AppError("OPENAI_REQUEST_FAILED", `OpenAI AI1 request failed (${response.status}).`, 502, body);
  }

  try {
    logStep("extract.openai.raw_before_parse", {
      rawResponsePreview: previewText(body, 2000),
    });
    const responseJson = JSON.parse(body) as Record<string, unknown>;
    const outputText = extractOutputText(responseJson);
    logStep("extract.openai.output_text", {
      outputLength: outputText.length,
      outputPreview: previewText(outputText, 2000),
    });
    const parsed = parseConceptPayload(outputText);
    const concepts = conceptsArrayFromParsed(parsed);
    const normalizationDiagnostics = concepts.map(conceptNormalizationDiagnostic);
    logStep("extract.openai.concepts.raw", {
      rawConceptCount: concepts.length,
      rawConcepts: concepts.map(rawConceptLogSummary),
    });
    logStep("extract.openai.concepts.normalized", {
      beforeValidatorCount: concepts.length,
      acceptedCount: normalizationDiagnostics.filter((diagnostic) => !diagnostic.rejection_reason).length,
      rejectedConcepts: normalizationDiagnostics.filter((diagnostic) => diagnostic.rejection_reason),
      acceptedConcepts: normalizationDiagnostics.filter((diagnostic) => !diagnostic.rejection_reason),
    });
    return concepts
      .map(normalizeConcept)
      .filter((concept): concept is Concept => concept !== null)
      .slice(0, 50);
  } catch (parseError) {
    logStep("extract.openai.parse_fallback", {
      error: serializeUnknown(parseError),
      rawPreview: previewText(body, 1000),
    });
    return [];
  }
}

function conceptPrompt(title: string, clippedText: string) {
  return `Material title: ${title}

Task:
Phase 1: Extract broad candidate concepts from the material.
Phase 2: Evaluate each candidate for exam and memorization value.

Audience:
- Korean insurance, finance, accounting, actuarial, IFRS17, K-ICS, ALM, solvency, reserve, premium, claim, cash-flow, discount-rate, regulation, and certification-exam learners.

Scoring:
- importance_score must be an integer from 0 to 100.
- exam_likelihood: likelihood that an exam would ask this concept.
- memorization_need: whether the learner must memorize the term, definition, formula, criterion, or process.
- core_concept: whether it is central to the material.
- prerequisite_value: whether it unlocks later concepts.
- document_emphasis: repetition, headings, tables, definitions, bold/emphasis, or examples.
- insurance_certification_fit: relevance to insurance/certification/exam prep.
- metadata_penalty: 100 when it looks like metadata, UUID, file name, path, storage path, hash, or generic noise.

Immediately exclude and set exclusion_reason:
- UUIDs, database IDs, material IDs, concept IDs, source hashes, file hashes
- file names, file extensions, file paths, URLs, storage paths
- metadata-only phrases
- generic words such as 개념, 테스트, 자료, 문서, 내용, 정보, 파일, 업로드, 분석, 텍스트, 데이터, 페이지, 문제, 정답, 설명
- weak candidates without supporting evidence

Accepted concept_type values:
- core_concept
- technical_term
- definition
- formula_or_metric
- regulation_or_standard
- process_step
- comparison_point
- prerequisite_concept
- acronym
- case_or_example
- metadata_noise
- generic_noise

Return 8 to 12 save-worthy concepts whenever the material contains enough text. Do not return fewer than 8 concepts unless the material has fewer than 8 distinct supported concepts.
Only concepts with importance_score >= 65 and exclusion_reason = null will be saved.
Use Korean for descriptions and evidence summaries. Keep domain acronyms such as IFRS17, ALM, K-ICS in their original form.
Use only the material below. Do not invent unsupported facts.
Return valid JSON only. Do not include markdown, code fences, commentary, or extra keys.

Return exactly this JSON shape:
{"concepts":[{"name":"보험부채","description":"문서 근거에 기반한 한국어 한 문장 설명","importance":5,"importance_score":92,"concept_type":"core_concept","evaluation":{"exam_likelihood":90,"memorization_need":85,"core_concept":95,"prerequisite_value":80,"document_emphasis":75,"insurance_certification_fit":95,"metadata_penalty":0},"exclusion_reason":null,"evidence":"문서에서 확인되는 짧은 한국어 근거"}]}

Material:
${clippedText}`;
}

function normalizeConcept(value: unknown): Concept | null {
  if (!value || typeof value !== "object") return null;
  const raw = value as Record<string, unknown>;
  const name = sanitizeConceptName(raw.name);
  const exclusionReason = sanitizeExclusionReason(raw.exclusion_reason) ?? rejectCandidateReason(stringFromUnknown(raw.name));
  if (!name || exclusionReason) return null;

  const importanceScore = Math.max(0, Math.min(100, Math.round(Number(raw.importance_score) || 0)));
  if (importanceScore < 65) return null;

  const conceptType = sanitizeConceptType(raw.concept_type);
  if (!conceptType || !isQuestionWorthyConceptType(conceptType)) return null;

  const evaluation = normalizeEvaluation(raw.evaluation);
  if ((evaluation.metadata_penalty ?? 0) >= 50) return null;

  const importance = Math.max(1, Math.min(5, Math.round(Number(raw.importance) || Math.ceil(importanceScore / 20))));
  const description = sanitizeVisibleKoreanText(raw.description);
  const evidence = sanitizeVisibleKoreanText(raw.evidence);
  if (!description || !evidence) return null;

  return {
    name,
    description,
    importance,
    importance_score: importanceScore,
    concept_type: conceptType,
    evaluation,
    exclusion_reason: null,
    evidence,
  };
}

function parseConceptPayload(outputText: string): unknown {
  const candidates = candidateJsonStrings(outputText);
  for (const candidate of candidates) {
    const parsed = parseJsonPossiblyNested(candidate);
    if (parsed != null) return parsed;
  }
  throw new AppError("OPENAI_PARSE_FAILED", "OpenAI AI1 output did not contain parseable JSON.", 502, previewText(outputText, 1000));
}

function candidateJsonStrings(value: string) {
  const trimmed = stripJsonFence(value);
  const candidates = [trimmed];
  const codeFenceMatch = value.match(new RegExp("```(?:json)?\\s*([\\s\\S]*?)```", "i"));
  if (codeFenceMatch?.[1]) candidates.push(codeFenceMatch[1].trim());
  const firstObject = trimmed.indexOf("{");
  const lastObject = trimmed.lastIndexOf("}");
  if (firstObject >= 0 && lastObject > firstObject) candidates.push(trimmed.slice(firstObject, lastObject + 1));
  const firstArray = trimmed.indexOf("[");
  const lastArray = trimmed.lastIndexOf("]");
  if (firstArray >= 0 && lastArray > firstArray) candidates.push(trimmed.slice(firstArray, lastArray + 1));
  return [...new Set(candidates.filter(Boolean))];
}

function parseJsonPossiblyNested(value: string): unknown {
  try {
    const parsed = JSON.parse(value);
    if (typeof parsed === "string") return parseJsonPossiblyNested(stripJsonFence(parsed));
    return parsed;
  } catch (_) {
    return null;
  }
}

function conceptsArrayFromParsed(parsed: unknown): unknown[] {
  if (Array.isArray(parsed)) return parsed;
  if (!parsed || typeof parsed !== "object") return [];
  const raw = parsed as Record<string, unknown>;
  const conceptLike = raw.concepts ?? raw.core_concepts ?? raw.items;
  if (Array.isArray(conceptLike)) return conceptLike;
  if (typeof conceptLike === "string") {
    const nested = parseJsonPossiblyNested(stripJsonFence(conceptLike));
    return Array.isArray(nested) ? nested : conceptsArrayFromParsed(nested);
  }
  if (raw.data) return conceptsArrayFromParsed(raw.data);
  if (raw.result) return conceptsArrayFromParsed(raw.result);
  return [];
}

function mergeConceptsByName(concepts: Concept[]) {
  const byName = new Map<string, Concept>();
  for (const concept of concepts) {
    const name = sanitizeConceptName(concept.name);
    if (!name) continue;
    const key = name.toLowerCase();
    const normalized = { ...concept, name };
    const existing = byName.get(key);
    if (!existing || (Number(normalized.importance_score) || 0) > (Number(existing.importance_score) || 0)) {
      byName.set(key, normalized);
    }
  }
  return [...byName.values()];
}

function fallbackConceptsFromText(structuredText: string, title: string): Concept[] {
  const keywords = extractFallbackKeywords(structuredText, title).slice(0, 12);
  return keywords
    .map((keyword, index) => {
      const name = sanitizeConceptName(keyword);
      if (!name) return null;
      const evidence = sanitizeVisibleKoreanText(evidenceSnippetForKeyword(structuredText, name));
      if (!evidence) return null;
      return {
        name,
        description: name + "은 업로드된 학습 자료에서 반복되거나 강조된 핵심 학습 용어입니다.",
        importance: Math.max(3, 5 - Math.floor(index / 2)),
        importance_score: Math.max(65, 80 - index * 3),
        concept_type: isAcronym(name) ? "acronym" : "technical_term",
        evaluation: {
          exam_likelihood: 65,
          memorization_need: 70,
          core_concept: 65,
          prerequisite_value: 50,
          document_emphasis: 65,
          insurance_certification_fit: 60,
          metadata_penalty: 0,
        },
        exclusion_reason: null,
        evidence,
      } as Concept;
    })
    .filter((concept): concept is Concept => concept !== null);
}

function extractFallbackKeywords(structuredText: string, title: string) {
  const counts = new Map<string, number>();
  const source = structuredText;
  const tokens = source.match(/[A-Za-z][A-Za-z0-9+./&-]{1,30}|[\p{Script=Hangul}][\p{Script=Hangul}A-Za-z0-9+./&-]{1,30}/gu) ?? [];
  for (const token of tokens) {
    const normalized = token.trim();
    const key = /[A-Za-z]/.test(normalized) ? normalized.toLowerCase() : normalized;
    if (key.length < 2 || rejectCandidateReason(normalized)) continue;
    counts.set(normalized, (counts.get(normalized) ?? 0) + 1);
  }
  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1] || b[0].length - a[0].length)
    .map(([keyword]) => keyword)
    .filter((keyword, index, array) => array.findIndex((item) => item.toLowerCase() === keyword.toLowerCase()) === index);
}

function evidenceSnippetForKeyword(structuredText: string, keyword: string) {
  const compact = structuredText.replace(/\s+/g, " ").trim();
  const index = compact.toLowerCase().indexOf(keyword.toLowerCase());
  if (index < 0) return previewText(compact, 160) || keyword;
  const start = Math.max(0, index - 60);
  return compact.slice(start, Math.min(compact.length, index + keyword.length + 100)).trim();
}



const genericConceptWords = new Set([
  "개념", "테스트", "자료", "문서", "내용", "정보", "파일", "업로드", "분석", "텍스트", "데이터", "페이지", "문제", "정답", "설명", "학습", "항목", "예시",
  "title", "source", "type", "text", "pdf", "ocr", "storage", "path", "adapter", "prepared", "replace", "metadata", "fallback", "server", "side", "parser", "before", "production", "material", "document", "file", "upload", "data", "test"
]);

const validConceptTypes = new Set([
  "core_concept",
  "technical_term",
  "definition",
  "formula_or_metric",
  "regulation_or_standard",
  "process_step",
  "comparison_point",
  "prerequisite_concept",
  "acronym",
  "case_or_example",
  "metadata_noise",
  "generic_noise",
]);

const questionWorthyConceptTypes = new Set([
  "core_concept",
  "technical_term",
  "definition",
  "formula_or_metric",
  "regulation_or_standard",
  "process_step",
  "comparison_point",
  "prerequisite_concept",
  "acronym",
]);

function sanitizeConceptName(value: unknown) {
  const text = stripInternalIdentifiers(stringFromUnknown(value)).replace(/\s+/g, " ").trim();
  if (!text || rejectCandidateReason(text)) return "";
  if (text.length > 80) return "";
  if (!/[A-Za-z\p{Script=Hangul}]/u.test(text)) return "";
  return text;
}

function sanitizeVisibleKoreanText(value: unknown) {
  const text = stripInternalIdentifiers(stringFromUnknown(value)).replace(/\s+/g, " ").trim();
  if (!text || containsInternalIdentifier(text)) return "";
  if (!/[가-힣]/.test(text)) return "";
  return text.slice(0, 500);
}

function rejectCandidateReason(value: string) {
  const text = value.trim();
  if (!text) return "empty";
  const lower = text.toLowerCase();
  if (containsInternalIdentifier(text)) return "internal_identifier";
  if (looksLikeFileName(text)) return "file_name";
  if (looksLikeHash(text)) return "hash";
  if (looksLikeUrl(text)) return "url";
  if (genericConceptWords.has(lower) || genericConceptWords.has(text)) return "generic_word";
  if (text.length < 2) return "too_short";
  return null;
}

function sanitizeConceptType(value: unknown) {
  const type = stringFromUnknown(value).trim();
  return validConceptTypes.has(type) ? type : "";
}

function isQuestionWorthyConceptType(value: string) {
  return questionWorthyConceptTypes.has(value);
}

function usableConceptsForQuiz(concepts: Concept[]) {
  return concepts
    .map((concept) => ({
      ...concept,
      name: sanitizeConceptName(concept.name),
      description: sanitizeVisibleKoreanText(concept.description),
      evidence: sanitizeVisibleKoreanText(concept.evidence),
      importance_score: Math.max(0, Math.min(100, Math.round(Number(concept.importance_score) || 0))),
      concept_type: sanitizeConceptType(concept.concept_type),
      exclusion_reason: sanitizeExclusionReason(concept.exclusion_reason),
    }))
    .filter((concept): concept is Concept => Boolean(
      concept.name &&
      concept.description &&
      concept.evidence &&
      concept.importance_score >= 65 &&
      concept.exclusion_reason == null &&
      isQuestionWorthyConceptType(concept.concept_type) &&
      !rejectCandidateReason(concept.name),
    ));
}

function conceptLogSummary(concept: Concept) {
  return {
    name: concept.name,
    description: previewText(concept.description, 160),
    importance_score: concept.importance_score,
    concept_type: concept.concept_type,
    exclusion_reason: concept.exclusion_reason,
    evidence: previewText(concept.evidence, 160),
  };
}

function rawConceptLogSummary(value: unknown) {
  if (!value || typeof value !== "object") {
    return { value: previewText(stringFromUnknown(value), 240) };
  }
  const raw = value as Record<string, unknown>;
  return {
    name: stringFromUnknown(raw.name),
    description: previewText(stringFromUnknown(raw.description), 240),
    importance_score: raw.importance_score,
    concept_type: raw.concept_type,
    exclusion_reason: raw.exclusion_reason,
    evidence: previewText(stringFromUnknown(raw.evidence), 240),
  };
}

function conceptNormalizationDiagnostic(value: unknown) {
  const rawSummary = rawConceptLogSummary(value);
  if (!value || typeof value !== "object") {
    return { ...rawSummary, rejection_reason: "not_object" };
  }

  const raw = value as Record<string, unknown>;
  const rawName = stringFromUnknown(raw.name);
  const name = sanitizeConceptName(raw.name);
  const explicitExclusionReason = sanitizeExclusionReason(raw.exclusion_reason);
  const deterministicRejection = rejectCandidateReason(rawName);
  const exclusionReason = explicitExclusionReason ?? deterministicRejection;
  if (!name) return { ...rawSummary, rejection_reason: deterministicRejection ?? "invalid_name" };
  if (exclusionReason) return { ...rawSummary, rejection_reason: exclusionReason };

  const importanceScore = Math.max(0, Math.min(100, Math.round(Number(raw.importance_score) || 0)));
  if (importanceScore < 65) return { ...rawSummary, rejection_reason: "importance_score_below_65" };

  const conceptType = sanitizeConceptType(raw.concept_type);
  if (!conceptType) return { ...rawSummary, rejection_reason: "invalid_concept_type" };
  if (!isQuestionWorthyConceptType(conceptType)) return { ...rawSummary, rejection_reason: "non_question_worthy_concept_type" };

  const evaluation = normalizeEvaluation(raw.evaluation);
  if ((evaluation.metadata_penalty ?? 0) >= 50) return { ...rawSummary, rejection_reason: "metadata_penalty" };

  const description = sanitizeVisibleKoreanText(raw.description);
  if (!description) return { ...rawSummary, rejection_reason: "invalid_description" };

  const evidence = sanitizeVisibleKoreanText(raw.evidence);
  if (!evidence) return { ...rawSummary, rejection_reason: "invalid_evidence" };

  return {
    name,
    importance_score: importanceScore,
    concept_type: conceptType,
    exclusion_reason: null,
    rejection_reason: null,
  };
}

function conceptUsabilityDiagnostics(concepts: Concept[]) {
  return concepts.map((concept) => {
    const name = sanitizeConceptName(concept.name);
    const description = sanitizeVisibleKoreanText(concept.description);
    const evidence = sanitizeVisibleKoreanText(concept.evidence);
    const importanceScore = Math.max(0, Math.min(100, Math.round(Number(concept.importance_score) || 0)));
    const conceptType = sanitizeConceptType(concept.concept_type);
    const exclusionReason = sanitizeExclusionReason(concept.exclusion_reason);
    const candidateRejection = rejectCandidateReason(concept.name);
    let rejectionReason: string | null = null;
    if (!name) rejectionReason = candidateRejection ?? "invalid_name";
    else if (!description) rejectionReason = "invalid_description";
    else if (!evidence) rejectionReason = "invalid_evidence";
    else if (importanceScore < 65) rejectionReason = "importance_score_below_65";
    else if (exclusionReason != null) rejectionReason = exclusionReason;
    else if (!isQuestionWorthyConceptType(conceptType)) rejectionReason = conceptType ? "non_question_worthy_concept_type" : "invalid_concept_type";
    else if (candidateRejection) rejectionReason = candidateRejection;

    return {
      name: concept.name,
      sanitized_name: name,
      importance_score: importanceScore,
      concept_type: conceptType,
      exclusion_reason: exclusionReason,
      rejection_reason: rejectionReason,
    };
  });
}

function estimateSectionCount(text: string) {
  const pageMarkers = text.match(/^\[?Page\s+\d+\]?/gim)?.length ?? 0;
  if (pageMarkers > 0) return pageMarkers;
  const headingMarkers = text.match(/^#{1,6}\s+|^\d+(?:\.\d+)*\s+\S+/gm)?.length ?? 0;
  if (headingMarkers > 0) return headingMarkers;
  return text.trim() ? 1 : 0;
}

function sanitizeExclusionReason(value: unknown) {
  const reason = stringFromUnknown(value).trim();
  if (!reason || reason.toLowerCase() === "null" || reason.toLowerCase() === "none") return null;
  return reason.slice(0, 80);
}

function normalizeEvaluation(value: unknown) {
  const raw = value && typeof value === "object" ? value as Record<string, unknown> : {};
  const keys = [
    "exam_likelihood",
    "memorization_need",
    "core_concept",
    "prerequisite_value",
    "document_emphasis",
    "insurance_certification_fit",
    "metadata_penalty",
  ];
  const result: Record<string, number> = {};
  for (const key of keys) {
    result[key] = Math.max(0, Math.min(100, Math.round(Number(raw[key]) || 0)));
  }
  return result;
}

function stripInternalIdentifiers(value: string) {
  return value
    .replace(uuidPattern(), "")
    .replace(storagePathPattern(), "")
    .replace(hashPattern(), "")
    .replace(/\b(?:material|concept|question|section|source)[_-]?id\s*[:=]?\s*/gi, "")
    .replace(/\b(?:materialId|conceptId|questionId|sectionId|sourceHash|storagePath|fileHash)\b\s*[:=]?\s*/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function containsInternalIdentifier(value: string) {
  return uuidPattern().test(value) ||
    storagePathPattern().test(value) ||
    hashPattern().test(value) ||
    /\b(?:material|concept|question|section|source)[_-]?id\b/i.test(value) ||
    /\b(?:materialId|conceptId|questionId|sectionId|sourceHash|storagePath|fileHash)\b/.test(value) ||
    looksLikeStoragePath(value);
}

function looksLikeStoragePath(value: string) {
  return storagePathPattern().test(value) ||
    /(?:^|\s)(?:materials|storage|uploads|public|private)\//i.test(value) ||
    /[A-Za-z]:\\/.test(value) ||
    /\/(?:[^\s/]+\/){1,}[^\s/]+/.test(value);
}

function looksLikeFileName(value: string) {
  return /\b[^\s]+\.(?:pdf|docx?|pptx?|xlsx?|png|jpe?g|txt|md|hwp|hwpx)\b/i.test(value);
}

function looksLikeUrl(value: string) {
  return /^https?:\/\//i.test(value) || /^supabase:\/\//i.test(value);
}

function looksLikeHash(value: string) {
  return hashPattern().test(value);
}

function isAcronym(value: string) {
  return /^[A-Z0-9][A-Z0-9+./&-]{1,24}$/.test(value.trim());
}

function uuidPattern() {
  return /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/gi;
}

function hashPattern() {
  return /\b[0-9a-f]{32,128}\b/gi;
}

function storagePathPattern() {
  return /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\/[\w.-]+\b/gi;
}

function stringFromUnknown(value: unknown): string {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  try { return JSON.stringify(value); } catch (_) { return String(value); }
}

async function saveConcepts(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  materialId: string,
  concepts: Concept[],
) {
  if (concepts.length === 0) throw new AppError("CONCEPTS_EMPTY", "No valid concepts to save.");

  const rows = concepts.map((concept) => ({
    user_id: userId,
    material_id: materialId,
    name: concept.name,
    description: concept.description,
    importance: concept.importance,
    importance_score: concept.importance_score,
    concept_type: concept.concept_type,
    evaluation: concept.evaluation,
    exclusion_reason: concept.exclusion_reason,
    evidence: { text: concept.evidence },
  }));

  const { error } = await supabase
    .from("concepts")
    .upsert(rows, { onConflict: "material_id,name" });
  if (error) throw new AppError("CONCEPTS_INSERT_FAILED", "Failed to insert concepts.", 500, error);
}

async function countConcepts(supabase: ReturnType<typeof createClient>, materialId: string) {
  const { data, error } = await supabase
    .from("concepts")
    .select("id")
    .eq("material_id", materialId);
  if (error) throw new AppError("DB_QUERY_FAILED", "Failed to count concepts.", 500, error);
  return data?.length ?? 0;
}

async function updateMaterial(
  supabase: ReturnType<typeof createClient>,
  materialId: string,
  values: Record<string, unknown>,
  userId?: string | null,
) {
  const payload = { ...values, updated_at: new Date().toISOString() };
  logStep("extract.material.update.start", {
    materialId,
    userId: userId ?? null,
    updatePayload: payload,
  });

  let query = supabase
    .from("study_materials")
    .update(payload)
    .eq("id", materialId);

  if (userId) {
    query = query.eq("user_id", userId);
  }

  const { data, error } = await query
    .select("id,user_id,status")
    .maybeSingle();

  if (error) {
    const postgrest = postgrestErrorDetails(error);
    const classified = classifyStudyMaterialUpdateError(postgrest);
    logStep("extract.material.update.error", {
      materialId,
      userId: userId ?? null,
      updatePayload: payload,
      classification: classified.code,
      postgrest,
    });
    throw new AppError(classified.code, classified.message, classified.status, {
      materialId,
      userId: userId ?? null,
      updatePayload: payload,
      postgrest,
    });
  }

  if (!data) {
    const details = {
      code: "NO_ROWS_UPDATED",
      message: "No study_materials row was updated.",
      details: "materialId does not exist for this user, or RLS prevented update visibility.",
      hint: "Check materialId, user_id ownership, and study_materials UPDATE/SELECT RLS policies.",
    };
    logStep("extract.material.update.no_rows", {
      materialId,
      userId: userId ?? null,
      updatePayload: payload,
      postgrest: details,
    });
    throw new AppError(
      "MATERIAL_UPDATE_NOT_ALLOWED",
      "Study material update affected no rows. Check materialId ownership or RLS policy.",
      404,
      {
        materialId,
        userId: userId ?? null,
        updatePayload: payload,
        postgrest: details,
      },
    );
  }

  logStep("extract.material.update.success", {
    materialId,
    userId: userId ?? null,
    status: (data as Record<string, unknown>).status,
  });
}

async function markMaterialFailed(
  supabase: ReturnType<typeof createClient>,
  materialId: string,
  message: string,
  userId?: string | null,
) {
  try {
    await updateMaterial(supabase, materialId, {
      status: "failed",
      analysis_error: message,
    }, userId);
  } catch (markError) {
    logStep("extract.material.mark_failed.error", {
      materialId,
      userId: userId ?? null,
      error: serializeError(markError),
    });
  }
}
function postgrestErrorDetails(error: unknown) {
  const raw = error && typeof error === "object" ? error as Record<string, unknown> : {};
  return {
    code: stringFromUnknown(raw.code),
    message: stringFromUnknown(raw.message) || serializeUnknown(error),
    details: stringFromUnknown(raw.details),
    hint: stringFromUnknown(raw.hint),
  };
}

function classifyStudyMaterialUpdateError(error: ReturnType<typeof postgrestErrorDetails>) {
  const joined = [error.code, error.message, error.details, error.hint].join(" ").toLowerCase();
  if (error.code === "42501" || joined.includes("row-level security") || joined.includes("rls") || joined.includes("permission denied")) {
    return {
      code: "RLS_POLICY_DENIED" as ErrorCode,
      message: "study_materials update was blocked by RLS policy.",
      status: 403,
    };
  }
  if (error.code === "23514" || joined.includes("check constraint") || joined.includes("study_materials_status")) {
    return {
      code: "STATUS_CHECK_FAILED" as ErrorCode,
      message: "study_materials status update violated a check constraint.",
      status: 409,
    };
  }
  return {
    code: "DB_UPDATE_FAILED" as ErrorCode,
    message: error.message ? "Failed to update study material: " + error.message : "Failed to update study material.",
    status: 500,
  };
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
    throw new AppError("OPENAI_PARSE_FAILED", "OpenAI AI1 response did not include output text.", 502);
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
      details: serializeErrorDetails(error.cause),
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

function serializeErrorDetails(value: unknown): unknown {
  if (value && typeof value === "object") return value;
  return serializeUnknown(value);
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


