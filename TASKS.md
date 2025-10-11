# Development Task Backlog

The following tasks remain to bring the McD Point Tracker Flutter app to feature-complete status. Items are grouped by area and should each include design, implementation, and testing.

## Platform & Tooling
- [ ] Install and verify the Flutter SDK in the project CI/local workflow and ensure `flutter test` passes.
- [ ] Configure platform-specific build settings for Android 14+, including permissions for media access, accessibility service, notifications, and background processing.

## Media Ingestion & Deduplication
- [ ] Implement screenshot, gallery video, and live capture ingestion flows with appropriate permissions and user education.
- [ ] Build adaptive frame extraction (2–5 fps) with perceptual hashing to drop near-duplicate frames before OCR.
- [ ] Persist raw media with metadata and expose a settings screen that lets users choose the retention window (default 7 days) and trigger cleanup.

## OCR, Parsing, and Review Workflow
- [ ] Integrate Google ML Kit Text Recognition v2 (on-device) with the required confidence threshold.
- [ ] Parse transactions via regex, detecting Earned/Used/Expired, dates, and point values.
- [ ] Surface low-confidence rows in a review queue where users can edit values; keep these rows out of the ledger until approved.
- [ ] During partial imports, detect overlapping rows via deduplication heuristics and prompt users before proceeding with duplicates.

## Data Persistence & Ledger
- [ ] Set up SQLite (via `sqflite` or equivalent) for transactions, raw media references, user settings, and review status.
- [ ] Wire the Dart FIFO ledger to persisted transactions, ensuring automatic replay after imports or edits.
- [ ] Implement reset functionality that clears all persisted data and media on demand.

## User Experience & Visualization
- [ ] Create dashboard cards for current balance, YTD totals, and upcoming expirations.
- [ ] Implement charts (12-month Earned/Used/Expired) and detailed ledger views per lot.
- [ ] Support light/dark themes, typography, and accessibility (screen reader labels, contrast, large text).
- [ ] Localize strings and date formatting infrastructure for future languages.

## Notifications & Background Work
- [ ] Schedule notifications 14 days before each lot expires at 09:00 MYT.
- [ ] Implement threshold-based alerts when the next month's expiring total exceeds the configured value.

## Testing & Quality
- [ ] Add unit, widget, and integration tests covering ingestion, ledger replay, notifications, and settings.
- [ ] Document QA scenarios and provide instructions for manual verification using the supplied sample media.

Track progress by checking off tasks as they are completed and ensure each feature ships with adequate test coverage and documentation.
