export const MIN_USABLE_CONCEPTS = 5;

export type Concept = {
  name: string;
  description: string;
  importance: number;
  importance_score: number;
  concept_type: string;
  evaluation: Record<string, number>;
  exclusion_reason: string | null;
  evidence: string;
};

export type ConceptExtractionInput = {
  apiKey: string;
  title: string;
  structuredText: string;
};