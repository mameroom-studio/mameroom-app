import {
  createEmptyCard,
  fsrs,
  generatorParameters,
  Rating,
} from "npm:ts-fsrs@5.4.1";

const parameters = generatorParameters({ request_retention: 0.9 });
const scheduler = fsrs(parameters);
const now = new Date("2026-07-21T00:00:00.000Z");
const card = createEmptyCard(now);
const result = scheduler.next(card, now, Rating.Good);

if (result.card.due <= now) {
  throw new Error("FSRS did not create a future due date");
}
if (result.card.stability <= 0 || result.card.difficulty <= 0) {
  throw new Error("FSRS returned invalid memory state");
}

console.log(JSON.stringify({
  due: result.card.due.toISOString(),
  stability: result.card.stability,
  difficulty: result.card.difficulty,
  state: result.card.state,
  scheduledDays: result.card.scheduled_days,
  reviewLogRating: result.log.rating,
}));
