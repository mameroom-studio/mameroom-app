import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as pdfjsLib from "https://esm.sh/pdfjs-dist@4.10.38/legacy/build/pdf.mjs?bundle";
import * as pdfjsWorker from "https://esm.sh/pdfjs-dist@4.10.38/legacy/build/pdf.worker.mjs?bundle";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const PDF_UPLOADS_BUCKET = "pdf_uploads";
const PDFJS_CMAP_URL = "https://esm.sh/pdfjs-dist@4.10.38/cmaps/";
const PDFJS_STANDARD_FONT_DATA_URL = "https://esm.sh/pdfjs-dist@4.10.38/standard_fonts/";

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

type PdfPage = { pageNumber: number; text: string; itemCount: number; diagnostics: TextDiagnostics };

type PdfParserResult = {
  rawText: string;
  structuredText: string;
  pages: PdfPage[];
};

type TextDiagnostics = {
  rawTextLength: number;
  koreanCharCount: number;
  replacementCharCount: number;
  printableRatio: number;
  wordLikeRatio: number;
  objectStreamScore: number;
  metadataKeywordScore: number;
};

type TextQualityResult = TextDiagnostics & {
  ok: boolean;
  reasons: string[];
};

interface PdfParser {
  readonly name: string;
  parse(input: Uint8Array, title: string, materialId: string): Promise<PdfParserResult>;
}

type ErrorCode =
  | "CONFIGURATION_ERROR"
  | "UNAUTHORIZED"
  | "INVALID_REQUEST"
  | "MATERIAL_NOT_FOUND"
  | "PDF_DOWNLOAD_FAILED"
  | "PDF_PARSE_FAILED"
  | "PDF_TEXT_EMPTY"
  | "PDF_TEXT_EXTRACTION_FAILED"
  | "DB_QUERY_FAILED"
  | "DB_UPDATE_FAILED"
  | "RLS_POLICY_DENIED"
  | "STATUS_CHECK_FAILED"
  | "MATERIAL_UPDATE_NOT_ALLOWED"
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

class PdfJsParser implements PdfParser {
  readonly name = "PdfJsParser";

  async parse(input: Uint8Array, title: string, materialId: string): Promise<PdfParserResult> {
    try {
      configurePdfJsNoWorker();
      const loadingTask = pdfjsLib.getDocument({
        data: input,
        disableWorker: true,
        useSystemFonts: true,
        isEvalSupported: false,
        cMapUrl: PDFJS_CMAP_URL,
        cMapPacked: true,
        standardFontDataUrl: PDFJS_STANDARD_FONT_DATA_URL,
      });
      const pdf = await loadingTask.promise;
      logStep("PDF-DOC-01 document.load.success", {
        analysisId: materialId,
        materialId,
        parser: this.name,
        numPages: pdf.numPages,
      });

      const pages: PdfPage[] = [];
      try {
        for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
          logStep("PDF-PAGE-01 page.load.start", {
            analysisId: materialId,
            materialId,
            pageNumber,
            numPages: pdf.numPages,
          });
          const page = await pdf.getPage(pageNumber);
          logStep("PDF-PAGE-02 page.load.success", {
            analysisId: materialId,
            materialId,
            pageNumber,
            numPages: pdf.numPages,
          });

          const content = await page.getTextContent({
            includeMarkedContent: false,
            disableNormalization: false,
          });
          const strings = content.items
            .map((item: unknown) => {
              const maybeTextItem = item as { str?: unknown };
              return typeof maybeTextItem.str === "string" ? maybeTextItem.str : "";
            })
            .filter((value) => value.trim().length > 0);
          const text = normalizeText(strings.join(" "));
          const diagnostics = textDiagnostics(text);
          const pageLog = {
            analysisId: materialId,
            materialId,
            pageNumber,
            numPages: pdf.numPages,
            itemCount: content.items.length,
            pageTextLength: text.length,
            koreanCharCount: diagnostics.koreanCharCount,
            replacementCharCount: diagnostics.replacementCharCount,
            printableRatio: diagnostics.printableRatio,
          };
          logStep(text.trim().length > 0 ? "PDF-PAGE-03 text.content.success" : "PDF-PAGE-04 text.content.empty", pageLog);
          pages.push({ pageNumber, text, itemCount: content.items.length, diagnostics });
        }
      } finally {
        await pdf.destroy();
      }

      const rawText = normalizeText(pages.map((page) => page.text).join("\n\n"));
      const structuredText = buildPdfStructuredText(title, pages);
      return { rawText, structuredText, pages };
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw new AppError("PDF_PARSE_FAILED", "Failed to parse PDF page text layer with pdfjs-dist.", 502, error);
    }
  }
}

async function parsePdfWithBestParser(
  input: Uint8Array,
  title: string,
  materialId: string,
): Promise<PdfParserResult & { parserName: string; diagnostics: Record<string, unknown>[]; quality: TextQualityResult }> {
  const diagnostics: Record<string, unknown>[] = [];
  try {
    const parsed = await new PdfJsParser().parse(input, title, materialId);
    const diagnostic = parserDiagnostic("PdfJsParser", parsed.rawText);
    diagnostics.push(diagnostic);
    const quality = validateExtractedText(parsed.rawText, title);
    logStep("PDF-PARSE-03B parser.result", {
      ...diagnostic,
      selectedParser: "PdfJsParser",
      fallbackUsed: false,
      qualityOk: quality.ok,
      qualityReasons: quality.reasons,
      pages: parsed.pages.map((page) => ({
        pageNumber: page.pageNumber,
        itemCount: page.itemCount,
        pageTextLength: page.text.length,
        koreanCharCount: page.diagnostics.koreanCharCount,
        replacementCharCount: page.diagnostics.replacementCharCount,
        printableRatio: page.diagnostics.printableRatio,
      })),
    });
    if (!quality.ok) {
      throw new AppError("PDF_TEXT_EXTRACTION_FAILED", "PDF text extraction quality check failed.", 422, quality);
    }
    return { ...parsed, parserName: "PdfJsParser", diagnostics, quality };
  } catch (error) {
    const serialized = serializeError(error);
    diagnostics.push({
      parser: "PdfJsParser",
      error: serialized,
    });
    logStep("PDF-PARSE-03B parser.failed", {
      parser: "PdfJsParser",
      error: serialized,
      fallbackUsed: false,
      reason: "binary/string fallback is disabled; raw PDF bytes will not be decoded as text",
    });
    if (error instanceof AppError) throw error;
    throw new AppError("PDF_PARSE_FAILED", "pdfjs-dist failed before extracting valid page text.", 502, error);
  }
}

function parserDiagnostic(parser: string, rawText: string) {
  const diagnostics = textDiagnostics(rawText);
  return {
    parser,
    ...diagnostics,
    cMapUrl: parser === "PdfJsParser" ? PDFJS_CMAP_URL : null,
    standardFontDataUrl: parser === "PdfJsParser" ? PDFJS_STANDARD_FONT_DATA_URL : null,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let activeSupabase: ReturnType<typeof createClient> | null = null;
  let activeMaterialId: string | null = null;
  let activeUserId: string | null = null;
  let activeStoragePath: string | null = null;

  try {
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

    const body = await req.json();
    const materialId = typeof body.materialId === "string" ? body.materialId : "";
    if (!materialId) {
      return errorJson(new AppError("INVALID_REQUEST", "materialId is required", 400), activeMaterialId);
    }
    activeMaterialId = materialId;

    const material = await loadMaterial(supabase, materialId, authData.user.id);
    activeStoragePath = typeof body.storagePath === "string" && body.storagePath.trim()
      ? body.storagePath.trim()
      : material.storage_path;

    if (material.source_type !== "pdf") {
      throw new AppError("INVALID_REQUEST", "analyze-pdf only supports PDF materials.", 400);
    }
    if (!activeStoragePath) {
      throw new AppError("PDF_DOWNLOAD_FAILED", "PDF material does not include storage_path.", 422);
    }

    const cached = await findCachedTextByHash(supabase, authData.user.id, material.id, material.file_hash);
    if (cached?.raw_text?.trim() && cached?.structured_text?.trim()) {
      const cachedQuality = validateExtractedText(cached.raw_text, material.title);
      logStep("PDF-CACHE-01 cached_text.quality", {
        analysisId: material.id,
        materialId: material.id,
        cacheMaterialId: cached.id,
        qualityOk: cachedQuality.ok,
        qualityReasons: cachedQuality.reasons,
        rawTextLength: cachedQuality.rawTextLength,
        koreanCharCount: cachedQuality.koreanCharCount,
        printableRatio: cachedQuality.printableRatio,
      });
      if (cachedQuality.ok) {
        await updateMaterial(supabase, material.id, {
          raw_text: cached.raw_text,
          structured_text: cached.structured_text,
          status: "generating",
          analysis_error: null,
        }, authData.user.id);
        return json({
          materialId: material.id,
          status: "generating",
          textLength: cached.raw_text.length,
          selectedParser: "cache",
          usedCache: true,
          message: "Reused cached PDF text for the same file hash.",
        });
      }
    }

    await updateMaterial(supabase, material.id, {
      status: "parsing",
      raw_text: null,
      structured_text: null,
      analysis_error: null,
    }, authData.user.id);
    const pdfBytes = await downloadPdfBytes(supabase, activeStoragePath, material.id);

    const parseStopwatch = Stopwatch.start();
    const parsed = await parsePdfWithBestParser(pdfBytes, material.title, material.id);
    logStep("PDF-PARSE-03 text.extract.success", {
      analysisId: material.id,
      materialId: material.id,
      elapsedMs: parseStopwatch.elapsedMs(),
      textLength: parsed.rawText.length,
      koreanCharCount: parsed.quality.koreanCharCount,
      replacementCharCount: parsed.quality.replacementCharCount,
      printableRatio: parsed.quality.printableRatio,
      selectedParser: parsed.parserName,
      parserDiagnostics: parsed.diagnostics,
      pageCount: parsed.pages.length,
      pages: parsed.pages.map((page) => ({
        pageNumber: page.pageNumber,
        itemCount: page.itemCount,
        pageTextLength: page.text.length,
      })),
    });

    await updateMaterial(supabase, material.id, {
      raw_text: parsed.rawText,
      structured_text: parsed.structuredText,
      status: "generating",
      analysis_error: null,
    }, authData.user.id);

    return json({
      materialId: material.id,
      status: "generating",
      textLength: parsed.rawText.length,
      structuredTextLength: parsed.structuredText.length,
      koreanCharCount: parsed.quality.koreanCharCount,
      replacementCharCount: parsed.quality.replacementCharCount,
      printableRatio: parsed.quality.printableRatio,
      selectedParser: parsed.parserName,
      parserDiagnostics: parsed.diagnostics,
      pages: parsed.pages.map((page) => ({
        pageNumber: page.pageNumber,
        itemCount: page.itemCount,
        pageTextLength: page.text.length,
      })),
      usedCache: false,
      message: "PDF page text layer parsed on the server.",
    });
  } catch (error) {
    const serialized = serializeError(error);
    logStep("PDF-PARSE-04 text.extract.failed", {
      analysisId: activeMaterialId,
      materialId: activeMaterialId,
      error: serialized,
    });
    if (activeSupabase && activeMaterialId) {
      await markMaterialFailed(activeSupabase, activeMaterialId, "PDF_TEXT_EXTRACTION_FAILED", activeUserId);
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

async function findCachedTextByHash(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  materialId: string,
  fileHash: string,
) {
  const { data, error } = await supabase
    .from("study_materials")
    .select("id,status,raw_text,structured_text")
    .eq("user_id", userId)
    .eq("file_hash", fileHash)
    .neq("id", materialId)
    .neq("status", "failed")
    .not("raw_text", "is", null)
    .not("structured_text", "is", null)
    .limit(1);

  if (error) throw new AppError("DB_QUERY_FAILED", "Failed to find cached PDF text.", 500, error);
  return data?.[0] ?? null;
}

async function downloadPdfBytes(
  supabase: ReturnType<typeof createClient>,
  storagePath: string,
  materialId: string,
) {
  const stopwatch = Stopwatch.start();
  logStep("PDF-PARSE-01 storage.download.start", {
    analysisId: materialId,
    materialId,
    storagePath,
    elapsedMs: 0,
  });
  const { data, error } = await supabase.storage
    .from(PDF_UPLOADS_BUCKET)
    .download(storagePath);
  if (error || !data) {
    throw new AppError("PDF_DOWNLOAD_FAILED", "Failed to download PDF from Supabase Storage.", 502, error);
  }

  const bytes = new Uint8Array(await data.arrayBuffer());
  logStep("PDF-PARSE-02 storage.download.success", {
    analysisId: materialId,
    materialId,
    storagePath,
    elapsedMs: stopwatch.elapsedMs(),
    byteSize: bytes.length,
  });
  if (bytes.length === 0) {
    throw new AppError("PDF_DOWNLOAD_FAILED", "Downloaded PDF was empty.", 502);
  }
  return bytes;
}

function configurePdfJsNoWorker() {
  (globalThis as unknown as { pdfjsWorker?: typeof pdfjsWorker }).pdfjsWorker = pdfjsWorker;
}

function buildPdfStructuredText(title: string, pages: PdfPage[]) {
  const sections = pages
    .filter((page) => page.text.trim().length > 0)
    .map((page) => "[Page " + page.pageNumber + "]\n" + page.text.trim());
  return normalizeText(["Title: " + title, "Source type: pdf", ...sections].join("\n\n"));
}

function validateExtractedText(rawText: string, title: string): TextQualityResult {
  const diagnostics = textDiagnostics(rawText);
  const compact = rawText.replace(/\s+/g, "");
  const reasons: string[] = [];
  const titleLooksKorean = /[\uAC00-\uD7A3]/.test(title);

  if (diagnostics.rawTextLength === 0) reasons.push("empty_text");
  if (diagnostics.rawTextLength < 20) reasons.push("too_short_for_text_pdf");
  if (diagnostics.printableRatio < 0.86) reasons.push("low_printable_ratio");
  if (diagnostics.wordLikeRatio < 0.42) reasons.push("low_word_sentence_ratio");
  if (diagnostics.replacementCharCount > Math.max(3, diagnostics.rawTextLength * 0.01)) reasons.push("too_many_replacement_chars");
  if (diagnostics.objectStreamScore >= 2) reasons.push("pdf_object_or_content_stream_detected");
  if (diagnostics.metadataKeywordScore >= 2 && diagnostics.koreanCharCount < 20) reasons.push("metadata_only_text_detected");
  if (titleLooksKorean && diagnostics.koreanCharCount < 20) reasons.push("korean_title_but_almost_no_korean_text");
  if (compact.length > 80 && /[^\p{L}\p{N}\s.,;:!?()[\]{}'"?쒋앪섃쇑?-_/+=%~<>|\\]{40,}/u.test(rawText)) {
    reasons.push("long_random_symbol_run_detected");
  }

  return { ...diagnostics, ok: reasons.length === 0, reasons };
}

function textDiagnostics(rawText: string): TextDiagnostics {
  const text = normalizeText(rawText);
  const rawTextLength = text.length;
  const koreanCharCount = countMatches(text, /[\uAC00-\uD7A3]/gu);
  const replacementCharCount = countMatches(text, /\uFFFD/gu);
  const printableCount = countPrintable(text);
  const wordLikeCount = countMatches(text, /[\p{L}\p{N}\s.,;:!?()[\]{}'"?쒋앪섃쇑?-_/+=%]/gu);
  const objectStreamScore = [
    /\b\d+\s+\d+\s+obj\b/i,
    /\bendobj\b/i,
    /\bstream\b/i,
    /\bendstream\b/i,
    /\bxref\b/i,
    /\/FlateDecode\b/i,
    /\/ObjStm\b/i,
    /\/Length\s+\d+/i,
  ].filter((pattern) => pattern.test(text)).length;
  const metadataKeywordScore = [
    /ReportLab PDF Library/i,
    /\bAdobe\b/i,
    /PDF Producer/i,
    /CreationDate/i,
    /ModDate/i,
    /Creator/i,
  ].filter((pattern) => pattern.test(text)).length;

  return {
    rawTextLength,
    koreanCharCount,
    replacementCharCount,
    printableRatio: ratio(printableCount, rawTextLength),
    wordLikeRatio: ratio(wordLikeCount, rawTextLength),
    objectStreamScore,
    metadataKeywordScore,
  };
}

function previewText(value: string, maxLength: number) {
  return normalizeText(value).slice(0, maxLength);
}

function normalizeText(value: string) {
  return value
    .replace(/\u0000/g, "")
    .replace(/[ \t]+/g, " ")
    .replace(/\s+\n/g, "\n")
    .replace(/\n\s+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function countMatches(text: string, pattern: RegExp) {
  return text.match(pattern)?.length ?? 0;
}

function countPrintable(text: string) {
  let count = 0;
  for (const char of text) {
    if (/[\p{L}\p{N}\p{P}\p{S}\s]/u.test(char) && char !== "\uFFFD") {
      count += 1;
    }
  }
  return count;
}

function ratio(numerator: number, denominator: number) {
  if (denominator <= 0) return 0;
  return Math.round((numerator / denominator) * 1000) / 1000;
}

async function updateMaterial(
  supabase: ReturnType<typeof createClient>,
  materialId: string,
  values: Record<string, unknown>,
  userId?: string | null,
) {
  const payload = { ...values, updated_at: new Date().toISOString() };
  let query = supabase.from("study_materials").update(payload).eq("id", materialId);
  if (userId) query = query.eq("user_id", userId);

  const { data, error } = await query.select("id,user_id,status").maybeSingle();
  if (error) {
    const postgrest = postgrestErrorDetails(error);
    const classified = classifyStudyMaterialUpdateError(postgrest);
    throw new AppError(classified.code, classified.message, classified.status, postgrest);
  }
  if (!data) {
    throw new AppError("MATERIAL_UPDATE_NOT_ALLOWED", "Study material update affected no rows.", 404);
  }
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
      raw_text: null,
      structured_text: null,
    }, userId);
  } catch (markError) {
    logStep("analyze_pdf.material.mark_failed.error", {
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
    return { code: "RLS_POLICY_DENIED" as ErrorCode, message: "study_materials update was blocked by RLS policy.", status: 403 };
  }
  if (error.code === "23514" || joined.includes("check constraint") || joined.includes("study_materials_status")) {
    return { code: "STATUS_CHECK_FAILED" as ErrorCode, message: "study_materials status update violated a check constraint.", status: 409 };
  }
  return { code: "DB_UPDATE_FAILED" as ErrorCode, message: error.message ? "Failed to update study material: " + error.message : "Failed to update study material.", status: 500 };
}

class Stopwatch {
  private startedAt = Date.now();
  static start() { return new Stopwatch(); }
  elapsedMs() { return Date.now() - this.startedAt; }
}

function stringFromUnknown(value: unknown): string {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  try { return JSON.stringify(value); } catch (_) { return String(value); }
}

function serializeError(error: unknown) {
  if (error instanceof AppError) {
    return { code: error.code, message: error.message, status: error.status, details: serializeErrorDetails(error.cause) };
  }
  if (error instanceof Error) {
    return { code: "UNKNOWN_ERROR" as ErrorCode, message: error.message, status: 500, details: serializeUnknown(error) };
  }
  return { code: "UNKNOWN_ERROR" as ErrorCode, message: serializeUnknown(error), status: 500, details: serializeUnknown(error) };
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
  try { return JSON.stringify(value); } catch (_) { return Object.prototype.toString.call(value); }
}


function errorJson(error: unknown, materialId: string | null) {
  const serialized = serializeError(error);
  return json({ error: serialized.message, code: serialized.code, details: serialized.details, materialId }, serialized.status);
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
