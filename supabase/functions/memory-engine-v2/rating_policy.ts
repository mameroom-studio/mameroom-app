import { Rating } from "npm:ts-fsrs@5.4.1";

export type RatingEvidence = {
  isCorrect: boolean;
  hintLevel: number;
  retryCount: number;
};

export function inferRating(
  input: RatingEvidence,
): Rating.Again | Rating.Hard | Rating.Good {
  if (!input.isCorrect) return Rating.Again;
  if (input.hintLevel > 0 || input.retryCount > 0) return Rating.Hard;
  return Rating.Good;
}

export type PassReason =
  | "review_later"
  | "already_known"
  | "out_of_scope"
  | "low_quality"
  | null;
export type PassAction =
  | "deferred"
  | "known"
  | "out_of_scope"
  | "quality_issue"
  | "neutral";

export function mapPassAction(reason: PassReason): PassAction {
  switch (reason) {
    case "review_later":
      return "deferred";
    case "already_known":
      return "known";
    case "out_of_scope":
      return "out_of_scope";
    case "low_quality":
      return "quality_issue";
    case null:
      return "neutral";
  }
}
