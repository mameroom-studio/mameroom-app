# MVP Performance Measurement Points

## Startup And Auth
- Cold start to first rendered page.
- Supabase session restore latency.
- Login request p50 and p95.

## Upload And Analysis
- File picker response time.
- File hash calculation time by file size.
- Storage upload duration and failure rate.
- Text extraction duration by file type.
- AI1 Edge Function latency and timeout rate.
- AI2 Edge Function latency and timeout rate.
- file_hash cache hit ratio.
- Time from upload success to first playable quiz.

## Quiz And Review
- Completed quiz question query latency.
- Answer submit and quiz_attempt insert p50 and p95.
- Memory state update latency.
- Review due item query latency.
- Review completion update latency.
- Coin reward RPC latency.
- Streak RPC latency.

## UI And Device
- Frame jank during quiz answer transition.
- Frame jank on RoomPage item rendering.
- Memory usage during large file selection.
- App resume latency after background.
- Crash-free session rate.

## Release Target
- Primary product target: first question available within 30 seconds after upload for supported small or medium files.
- Quiz and review target: no AI or Edge Function call during answer flow.
