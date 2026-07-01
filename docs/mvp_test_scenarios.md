# MVP User Flow Test Scenarios

## 1. Auth
- New user can sign up with email and password.
- If email confirmation is required, the app shows a clear confirmation guide.
- Existing user can sign in and lands on LibraryPage.
- Session is restored after app restart.
- Logout clears the route and returns to LoginPage.

## 2. Library
- Empty library shows an empty state and the upload CTA.
- Existing materials are listed with status, recent learning summary, review count, total memory score, wallet balance, and streak.
- Upload CTA navigates to UploadPage.
- Review CTA opens ReviewPage.
- My Room CTA opens RoomPage.

## 3. Upload
- PDF selection shows filename and size.
- Image selection shows filename and size.
- Camera capture handles permission denial and cancellation.
- Text paste path prepares a study_materials row without creating a storage file.
- Invalid file type is rejected.
- Oversized file is rejected.
- Valid file upload writes to materials bucket under user_id/material_id/original_filename.
- Upload success creates study_materials with status uploaded and navigates to AnalysisPage.

## 4. Analysis AI1
- AnalysisPage shows uploaded, extracting, analyzing, concepts_completed, and failed states.
- Existing file_hash cache prevents duplicate analysis.
- AI1 is invoked only through the extract-core-concepts Edge Function with materialId.
- Concepts are saved to concepts table.
- Failure changes study_materials.status to failed.

## 5. First Quiz Generation AI2
- generate-first-quiz only runs when status is concepts_completed.
- It creates exactly 10 initial questions: 5 multiple choice, 3 OX, 2 fill blank.
- Questions are saved with evidence, concept_id, section_id, difficulty, type, answer, and explanation.
- Existing initial questions for the same material are reused without another AI call.
- Success changes status to completed.

## 6. Quiz
- QuizPage loads completed material questions where initial_batch is true ordered by order_index.
- Multiple choice, OX, and fill blank answers can be submitted.
- Correctness is calculated locally without AI or Edge Function calls.
- Explanation and evidence are shown after answering.
- quiz_attempts are saved.
- question_feedback supports like, hard, and inaccurate.
- Final question navigates to QuizResultPage.

## 7. Memory Engine
- After each attempt, memory_states are created or updated by concept_id.
- memory_score uses normalized accuracy, response_time, difficulty, forgetting_curve, and confidence.
- next_review_at is calculated from memory_score thresholds.
- review_schedules are created or updated.
- QuizResultPage shows memory change and next review time.

## 8. Review Today
- ReviewPage loads schedules with next_review_at <= now.
- Items are sorted by overdue first, then lower memory_score.
- Review uses the same quiz interaction pattern without AI calls.
- Completion updates review_schedules and memory_states.

## 9. Coins
- Correct answers grant M-Coin through DB-controlled reward logic.
- 5-answer streak bonus is granted once per eligible quiz flow.
- First learning, review completion, and memory improvement rewards are recorded.
- QuizResultPage shows earned, bonus, and wallet balance.
- LibraryPage shows current balance and today earned.

## 10. My Room
- RoomPage shows base room, character, wallet balance, streak badge, and placed items.
- ShopPage lists active seeded items and prices.
- Purchase succeeds only when balance is sufficient.
- Coin spend is processed by DB function, not direct client wallet update.
- Purchased item can be placed with the MVP tap/fixed placement behavior.
