# McD Point Tracker Requirements

## Goal
An Android (Flutter) app that ingests McDonald's "Points history" via screenshots, screen recordings, or live on-device capture, then outputs:

- Points expiring per month for the next 3 calendar months
- Year-to-date totals for Earned / Used / Expired
- A correct current balance
- A monthly chart plus FIFO lot ledger

## Platforms & Constraints
- Android only, minimum Android 14 (API 34)
- Single McDonald's account
- Initial locale: English (MYT +08:00); app should be architected for localization
- On-device OCR using Google ML Kit
- No cloud storage; use SQLite for data persistence
- Target: full-history import (500–800 rows) in ~1 minute on a Samsung Note 20 Ultra

## Data Ingestion
- **Supported inputs**: screenshots (gallery picker), screen recordings, and optional live screen capture (accessibility service)
- **Frame extraction**: start at ~2 fps and adaptively increase up to 5 fps when UI changes
- **Perceptual hashing**: use pHash to debounce identical frames (via existing Dart/Flutter package or custom plugin)
- **Crop detection**: detect the list rows region once (first frame) and reuse across frames
- Raw media retained for 7 days in simple file storage; no encryption required

## OCR & Parsing
- ML Kit Text Recognition v2 with confidence threshold 0.99; rows below threshold marked "Needs review"
- Each visible row → one transaction
- Supported types: Earned, Used, Expired
- Deduplication key: (date, type, points); keep first seen on collision
- Regex patterns:
  - Type: `\b(Earned|Used|Expired)\b`
  - Date: `\b(20\d{2})-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\b`
  - Points: `\b-?\d{1,6}\b` (Used negative, others positive)

## Manual Review
- Table of parsed rows with inline edit (date picker, type dropdown, number input)
- Rows flagged "Needs review" stored in database with status flag until user confirms

## Domain Logic
- **Expiry rule**: each Earned lot expires exactly 12 months after `earned_date` (same day, MYT)
- **Consumption rule (FIFO)**: Used subtracts from oldest unexpired Earned lots first
- **Expired** removes remaining units in aged lots on their expiry date
- Maintain an internal lot ledger to replay history deterministically
- Ledger replay runs automatically whenever the user imports or edits data

## Calculations & UI
- Home cards:
  - Expiring soon (next 3 calendar months) computed from remaining units in `earned_lots` by expiry month
  - YTD totals (Jan 1–today): Earned / Used / Expired from transactions + replayed ledger
  - Current balance
- Charts: 12‑month bar chart of Earned/Used/Expired
- Ledger screen: per‑lot view (earned date, original, consumed, expired, remaining, expiry)

## Notifications
- Notify 14 days before the points expire at 09:00 MYT
- Threshold alert (default 1000): notify if next month's expiring total > threshold
- Use `flutter_local_notifications`

## Sample Media & Data Management
- Use actual screenshots/videos for development and testing
- On first use, allow users to provide full historical data; afterwards support partial updates
- Provide an option to reset all data and start over

## Design & Accessibility
- Support both light and dark themes
- Follow Android accessibility standards

## Future Localization
- Prepare strings, date formats, and other resources for future localization beyond English/MYT

## Performance Target
- Optimize for importing 500–800 rows in approximately 1 minute on a Samsung Note 20 Ultra

## Implementation Notes
- A minimal Flutter project lives under `flutter_app/` containing the FIFO ledger and perceptual-hash helpers in Dart.
- Run `flutter test` inside that directory to execute the unit tests (requires Flutter SDK).

