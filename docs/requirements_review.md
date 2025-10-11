# Requirements Review and Clarification Log

## Confirmed Understanding
- Target device family is Android (Flutter) with a minimum OS level of Android 14 (API 34), single McDonald's account, and English-first locale pinned to MYT (+08:00). Support for additional locales or multiple accounts is out of scope unless clarified otherwise.
- Ingestion must accept screenshots, prerecorded screen recordings, and an optional live accessibility capture path. Videos and live capture require adaptive frame extraction at roughly 2–5 fps with perceptual hashing to avoid duplicate frames. Raw media must be deleted after seven days.
- On-device OCR must rely on Google ML Kit Text Recognition v2. Transactions with any field below 0.99 confidence move into a manual review queue before persisting confirmed data.
- Transaction parsing deduplicates by SHA-1 of `date|type|points`. Earned, Used, and Expired are the only transaction types. Each Earned entry becomes a FIFO lot that expires 12 months after the earned date, and Used/Expired events replay against the lot ledger deterministically.
- Analytics include current balance, YTD Earned/Used/Expired totals, three-month expiry projections, a monthly bar chart for Earned/Used/Expired, and a per-lot ledger view.
- Local persistence is SQLite with normalized tables for transactions, earned lots, and ledger events. All time calculations must be treated in MYT to avoid device timezone drift.
- Notification capabilities include configurable scheduling (14 days before month end or on the 1st of the month at 09:00 MYT) and a next-month expiry threshold alert with a default threshold of 1,000 points.

## Items Requiring Clarification
1. **Source asset handling**
   - Should screen recordings be pre-trimmed by users, or must the ingestion flow include trimming/selection tools?
   - Are portrait-only recordings guaranteed, or do we need to support landscape captures and different aspect ratios?
2. **OCR and parsing edge cases**
   - How frequently do OCR errors manifest beyond obvious character substitutions (e.g., `0` vs `O`)? Are there examples of partial rows, headers, or promotional banners we must filter out?
   - Can the history list include non-transaction rows (e.g., “tips”, “level-up banners”) that need to be ignored, and if so what identifiers distinguish them?
3. **Manual review workflow**
   - After editing a pending row, should the original OCR text remain visible for auditing, or can it be replaced by the edited values?
   - Is bulk approval/denial needed for reviewers, or will row-by-row confirmation suffice for v1?
   - Are there audit requirements (e.g., export of change history) beyond the deterministic ledger replay that is already specified?
4. **Expiry projections and notifications**
   - Do notifications need snooze/dismiss actions, and should we log notification delivery status for auditing?
   - Can users opt into multiple thresholds or custom schedules, or is a single threshold with two schedule choices sufficient for launch?
5. **Data retention & privacy**
   - The requirements state that raw media is deleted after seven days. Do we also need a user-facing “purge now” control or status surface to confirm deletions?
   - Are there corporate compliance requirements around storing hashes or derived data beyond SQLite on-device (e.g., encrypted backups)?
6. **Testing assets**
   - Are the 10+ screenshots and 3 videos expected to be bundled with the app repo for automated testing, or delivered separately? Are there privacy constraints on including them in version control?
7. **Performance expectations**
   - The goal is a one-minute full-history import on a mid-range device. Which device class should we benchmark against, and do we have representative performance metrics for typical history sizes?

## Risks & Open Questions
- **Adaptive frame sampling**: implementing pHash-based dedupe on-device may require native plugins (e.g., FFmpeg). We should confirm library choices and acceptable binary sizes.
- **Deterministic ledger replay**: the requirements imply recalculating the full ledger on every change. We should confirm whether partial incremental updates are acceptable if they preserve determinism but improve performance.
- **Live capture accessibility service**: clarifying the UX expectations (persistent overlay, background service limitations on Android 14) will influence permissions and onboarding copy.
- **Notification exact alarms**: Android 14 introduces stricter exact alarm policies. We need confirmation on whether requesting `SCHEDULE_EXACT_ALARM` is acceptable at launch or if a fallback schedule is preferred.

## Proposed Next Steps
1. Collect sample media assets representing the hardest OCR cases to guide parsing heuristics.
2. Validate compliance expectations (privacy, permissions copy) with stakeholders.
3. Prioritize clarifications above before implementing ingestion and ledger persistence to avoid rework.
