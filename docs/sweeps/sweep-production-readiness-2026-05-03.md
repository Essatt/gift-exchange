# Production Readiness Sweep Report — Gift Exchange
Date: 2026-05-03 | Files audited: 16 Dart + 8 config | Issues found: 35

## Executive Summary

The Gift Exchange app is a well-structured Flutter app with clean architecture — Riverpod state management, encrypted local Hive storage, and proper separation of models/services/providers/UI. No security vulnerabilities were found in the encryption or data handling. However, the app has **zero test coverage** (the only test is the Flutter counter template), **no data backup or export**, several UX gaps (no undo delete, misleading labels, no pull-to-refresh on People page), and multiple vibe-coding artifacts (template README, leftover backup files, default pubspec description). The core functionality appears solid, but the app is **not production-ready** without addressing the critical items below. Estimated remediation: 2-3 days for criticals, 1 week for warnings.

## Critical Issues (Fix Before Release)

| # | Issue | File(s) | Fix |
|---|-------|---------|-----|
| 1 | **Zero test coverage** — widget_test.dart is the Flutter counter template. No tests for models, services, providers, or UI. | `test/widget_test.dart` | Write unit tests for GiftService CRUD, provider logic, TimeFilter, PersonStats calculations. Add widget tests for AddGiftDialog, AddPersonDialog. Minimum: 70% coverage on services/providers. |
| 2 | **No data backup/export** — All data is local-only Hive boxes. Uninstalling the app or switching phones means permanent data loss. For a financial tracking app, this is a dealbreaker. | `lib/services/gift_service.dart` | Add JSON export/import functionality. Export all people + gifts as a JSON file to device storage or share sheet. Consider periodic automatic backup. |
| 3 | **No data recovery path** — If Hive box gets corrupted (device crash during write), the catch-all in main.dart shows a generic error. User has no way to recover or reset without reinstalling. | `lib/main.dart:55-71` | Add a "Reset App Data" option in the error screen. Consider Hive box validation on startup with repair/recovery attempt. |
| 4 | **README.md is an AI debugging log** — Contains conversation history about build failures, not project documentation. Users/contributors have no idea what the app does. | `README.md` | Replace with proper README: app description, features, setup instructions, tech stack, platform support. |
| 5 | **`main.dart.backup` in source tree** — Leftover backup file in lib/. Vibe coding artifact. | `lib/main.dart.backup` | Delete the file. |
| 6 | **`firebase-debug.log` in source tree** — Debug log committed/left in lib/. | `lib/firebase-debug.log` | Delete and add to .gitignore if not already covered. |

## Security Findings

| # | Finding | Severity | Detail |
|---|---------|----------|--------|
| 7 | **Encryption is correctly implemented** — HiveAesCipher with key from FlutterSecureStorage. Key generated if not present. | PASS | `lib/main.dart:16-26` |
| 8 | **Android signing keys properly gitignored** — key.properties exists on disk but is NOT tracked by git. | PASS | `.gitignore:48` |
| 9 | **No network calls, Firebase, or backend** — Pure local app. No API keys to leak. No server attack surface. | PASS | N/A |
| 10 | **No hardcoded secrets or tokens** — grep confirmed zero secrets in source. | PASS | N/A |
| 11 | **No input sanitization on person names** — Names accept any characters including emoji, control chars. Labels are sanitized but names aren't. | LOW | Add name sanitization in `AddPersonDialog._handleSave()` — strip control characters, trim whitespace. |
| 12 | **Error messages expose internal details** — `main.dart:63` shows raw exception to user: `'Failed to initialize app. Please restart.\n\nError: $e'`. Hive errors can leak file paths. | LOW | Show user-friendly message only. Log the actual error separately. |

## Code Quality & Vibe Coding Issues

| # | Issue | File(s) | Fix |
|---|-------|---------|-----|
| 13 | **pubspec.yaml description is template default** — "A new Flutter project." | `pubspec.yaml:2` | Update to actual description: "Track gift exchanges with friends and family" |
| 14 | **No lint rules enabled beyond defaults** — analysis_options.yaml only includes flutter_lints/flutter.yaml with no additional rules. | `analysis_options.yaml` | Enable stricter lints: `avoid_print`, `prefer_const_constructors`, `require_trailing_commas`, `unnecessary_lambdas`. |
| 15 | **PersonDetailPage mixes constructor-passed data with provider data** — `person` is passed via constructor, but the page also watches `peopleProvider` for live name. If person is deleted on another screen, `widget.person.id` references stale data. | `lib/features/people/presentation/pages/person_detail_page.dart:67-72` | Use only the provider for person data, pass just the `personId` to the page. |
| 16 | **`RefreshIndicator` on PeoplePage is missing** — People page has no pull-to-refresh unlike Analysis and PersonDetail pages. | `lib/features/people/presentation/pages/people_page.dart:18-46` | Wrap ListView in RefreshIndicator. |
| 17 | **No `const` constructors where possible** — Several widget constructors and static lists could be const. | Multiple files | Run `dart fix --apply` or enable `prefer_const_constructors` lint. |
| 18 | **Singletons used for GiftService** — Factory constructor always returns same instance. Works for local-only but makes testing harder (can't inject mock). | `lib/services/gift_service.dart:55-57` | Consider using Riverpod's provider override for testability instead of singleton pattern. |
| 19 | **Duplicate delete confirmation logic** — `_confirmDeletePerson`, `_confirmDismiss` (gift delete), and `_confirmDelete` are nearly identical dialogs in 3 files. | PeoplePage, PersonDetailPage, GiftExchangePage | Extract a shared `ConfirmDeleteDialog` widget. |
| 20 | **Duplicate timeframe toggle** — `_TimeframeToggle` is defined identically in both `person_detail_page.dart` and `analysis_page.dart`. | Two files | Extract to shared widgets directory. |

## UI/UX Issues

| # | Issue | File(s) | Fix |
|---|-------|---------|-----|
| 21 | **No undo on delete** — Deleting a person cascades to all their gifts permanently. SnackBar shows name but has no undo action. | `people_page.dart:116-119` | Add `SnackBarAction` for undo. Store deleted data temporarily for restoration. |
| 22 | **"Exchange" tab label misleading** — Tab says "Exchange" but page shows transaction history ("Recent Exchanges"). "Exchange" implies active trading. | `main.dart:225-227` | Rename to "History" or "Activity". |
| 23 | **Analysis "Top Recipients" label wrong** — Shows people sorted by `totalGiven` (what YOU spent on THEM). That makes them "Top Recipients" of your spending, but semantically confusing. | `_top_spenders.dart:39-40` | Rename to "Top Spending by Person" or "Where Your Money Went". |
| 24 | **Empty state on Exchange page has no action button** — Unlike People page (has FAB), the Exchange empty state just says "Start logging gifts" with no button. | `gift_exchange_page.dart:68-91` | Add a button or instructions pointing users to the People page to add gifts. |
| 25 | **No visual feedback when tapping outside delete dialog** — Dialog closes without action, user may think gift was deleted. | PersonDetailPage, GiftExchangePage | Set `barrierDismissible: false` on delete confirmation dialogs. |
| 26 | **Hardcoded `$` currency symbol** — No i18n support for other currencies. | Multiple files | Use `NumberFormat.currency()` from intl package. Allow currency preference setting. |
| 27 | **No dark mode toggle** — Dark theme is defined in `_buildTheme()` but there's no UI toggle. System theme is followed automatically via MediaQuery, but no in-app override. | `main.dart:163-185` | Add theme mode setting (system/light/dark) in a settings page or dialog. |
| 28 | **No `Intl.defaultLocale` initialization** — `DateFormat.yMMMd()` is used without explicit locale initialization. May work on most devices but not guaranteed. | Multiple files | Call `Intl.defaultLocale = Platform.localeName` or initialize explicitly. |
| 29 | **Expanded event cards collapse on data refresh** — `_expandedEvent` state is held in widget state and persists through rebuilds, but if data refreshes while expanded, the visual state resets. | `person_detail_page.dart:22` | Track expanded state by event key in a Set, or use provider-based state. |

## Model & Data Integrity

| # | Issue | File(s) | Fix |
|---|-------|---------|-----|
| 30 | **Gift value allows 0** — The validator rejects values ≤ 0, but the model accepts any double. Service creates gift with `value: value` where value comes from `double.tryParse(valueController.text) ?? 0`. The `?? 0` fallback could create $0 gifts if validation is bypassed. | `add_gift_dialog.dart:62`, `gift.dart:18` | Add assert in Gift constructor: `assert(value > 0, 'Gift value must be positive')`. |
| 31 | **No uniqueness check on person names** — Users can create duplicate people with identical names, leading to confusion. | `add_person_dialog.dart` | Check for duplicate names before saving (case-insensitive). |
| 32 | **`updatedAt` not set on gift updates via copyWith** — `Gift.copyWith()` doesn't include updatedAt field. `GiftService.updateGift()` doesn't update timestamp. | `gift_service.dart:97-101`, `gift.dart:43-63` | Add `updatedAt` to Gift model and update it in service.updateGift(). |

## Production & App Store Readiness

| # | Issue | Detail |
|---|-------|--------|
| 33 | **No privacy policy** — Required for App Store / Play Store submission. App stores local data (names, gift values, relationships) which may be considered personal data. | Create privacy policy page or link. Even local-only apps need one for store submission. |
| 34 | **No crash reporting** — No Crashlytics, Sentry, or Firebase Crashlytics. Crashes are invisible. | Integrate Firebase Crashlytics or Sentry for crash reporting. |
| 35 | **No analytics** — No way to know if users are engaging, where they drop off, or what features are used. | Consider privacy-respecting analytics (PostHog self-hosted, Plausible, or firebase_analytics). |
| 36 | **No app rating prompt** — No mechanism to ask happy users for App Store reviews. | Add `in_app_review` package and trigger after positive engagement milestones (e.g., 5+ gifts logged). |

## Architecture & Tech Stack Assessment

| Aspect | Rating | Notes |
|--------|--------|-------|
| State management (Riverpod) | 8/10 | Well-implemented with refresh signals, family providers, derived providers. |
| Local storage (Hive + encryption) | 8/10 | Correctly encrypted. Label cache pattern is good. |
| Model design | 7/10 | Clean immutable models with copyWith. Missing updatedAt on Gift. |
| Service layer | 7/10 | Singleton pattern limits testability. CRUD operations are solid. |
| UI (Material 3) | 7/10 | Good use of M3 theming, dark mode support. Some duplicate widgets. |
| Test coverage | 0/10 | Template test only. Zero real coverage. |
| Error handling | 5/10 | Try/catch present but no recovery paths. Error messages sometimes too technical. |
| Accessibility | 4/10 | No semantic labels, no screen reader support. Color-only indicators for given/received. |
| i18n/L10n | 2/10 | Hardcoded English strings, hardcoded `$` currency. No localization infrastructure. |

## Master Todo List (Priority Order)

- [ ] **CRITICAL** Replace template test with real tests (services, providers, models)
- [ ] **CRITICAL** Add JSON export/import for data backup
- [ ] **CRITICAL** Add data recovery/reset path for corrupted storage
- [ ] **CRITICAL** Replace README.md with actual project documentation
- [ ] **CRITICAL** Delete main.dart.backup and firebase-debug.log
- [ ] **CRITICAL** Add undo action to delete SnackBars
- [ ] **HIGH** Extract duplicate widgets (ConfirmDeleteDialog, TimeframeToggle)
- [ ] **HIGH** Pass personId instead of Person to PersonDetailPage
- [ ] **HIGH** Fix "Exchange" tab label and "Top Recipients" label
- [ ] **HIGH** Add pull-to-refresh on People page
- [ ] **HIGH** Add updatedAt to Gift model and update on save
- [ ] **HIGH** Set barrierDismissible: false on delete dialogs
- [ ] **MEDIUM** Add Person name uniqueness check
- [ ] **MEDIUM** Add Gift value > 0 assertion in model
- [ ] **MEDIUM** Enable stricter lint rules
- [ ] **MEDIUM** Initialize Intl.defaultLocale
- [ ] **MEDIUM** Add dark/light theme toggle
- [ ] **MEDIUM** Add input sanitization for person names
- [ ] **LOW** Create privacy policy
- [ ] **LOW** Integrate crash reporting
- [ ] **LOW** Add app rating prompt
- [ ] **LOW** Consider currency localization
- [ ] **LOW** Add semantic labels for accessibility

## Verdict

**NOT production-ready.** The core architecture and code quality are solid (7/10), but zero test coverage, no data backup, and several UX gaps make this unsuitable for real users. The app is functionally complete for a personal tool or beta, but needs the critical items addressed before App Store / Play Store submission. Estimated 2-3 days to reach production quality.
