import { assert, assertEquals, assertGreater } from "jsr:@std/assert@1.0.14";
import { Rating } from "npm:ts-fsrs@5.4.1";
import { scheduleCard } from "./fsrs_engine.ts";
import { inferRating, mapPassAction } from "./rating_policy.ts";

Deno.test("rating policy never infers Easy", () => {
  assertEquals(
    inferRating({ isCorrect: false, hintLevel: 0, retryCount: 0 }),
    Rating.Again,
  );
  assertEquals(
    inferRating({ isCorrect: true, hintLevel: 1, retryCount: 0 }),
    Rating.Hard,
  );
  assertEquals(
    inferRating({ isCorrect: true, hintLevel: 0, retryCount: 1 }),
    Rating.Hard,
  );
  assertEquals(
    inferRating({ isCorrect: true, hintLevel: 0, retryCount: 0 }),
    Rating.Good,
  );
});

Deno.test("PASS remains schedule-neutral action", () => {
  assertEquals(mapPassAction(null), "neutral");
  assertEquals(mapPassAction("review_later"), "deferred");
  assertEquals(mapPassAction("already_known"), "known");
  assertEquals(mapPassAction("out_of_scope"), "out_of_scope");
  assertEquals(mapPassAction("low_quality"), "quality_issue");
});

Deno.test("FSRS repeated Good grows beyond legacy seven-day ceiling", () => {
  let card = null;
  let now = new Date("2026-01-01T00:00:00.000Z");
  for (let index = 0; index < 8; index++) {
    const next = scheduleCard(card, now, Rating.Good);
    card = {
      ...next,
      due_at: next.due,
      last_reviewed_at: next.last_review,
      state_version: index + 1,
    };
    now = new Date(next.due);
  }
  assert(card != null);
  assertGreater(card.scheduled_days, 7);
});
