# Gift Exchange

Track gift exchanges with friends and family. Log gifts given and received, analyze spending patterns, and maintain balanced relationships.

## Features

- **People Management** — Add people with relationship types (family, friend, colleague, partner, or custom)
- **Gift Tracking** — Log gifts given and received with event labels, descriptions, dates, and values
- **Exchange History** — Browse all gift exchanges chronologically
- **Spending Analysis** — View spending breakdowns by person and event label with yearly/monthly filters
- **Balance Tracking** — See net balance (given vs. received) per person and overall
- **Dark Mode** — Automatic light/dark theme based on system preference
- **Local & Private** — All data stored encrypted on-device, no account required

## Tech Stack

- Flutter 3.x + Dart 3.10
- Riverpod (state management)
- Hive (encrypted local storage)
- Material 3 design system

## Getting Started

```bash
cd src/frontend
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart              # App entry point, theme, navigation
├── models/                # Domain models (Person, Gift, enums, stats)
├── services/              # GiftService — CRUD, labels, encryption
├── providers/             # Riverpod providers for reactive data
└── features/
    ├── people/            # People list, person detail, add/edit dialogs
    ├── gifts/             # Exchange history feed
    └── analysis/          # Spending analysis & breakdowns
```

## License

Proprietary. All rights reserved.
