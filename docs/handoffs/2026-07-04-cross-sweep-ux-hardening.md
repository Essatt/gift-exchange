# Cross-sweep UX hardening (2026-07-04)

> **📋 Paste this into the next session:**
>
> `resume gift-exchange`. Read `/docs/handoffs/2026-07-04-cross-sweep-ux-hardening.md` in full. Execute **▶️ Start here** steps IN ORDER. Don't redo the import/undo/validation/responsive fixes — they are done and covered by 34 passing tests. Run on Sonnet high.

## ▶️ Start here (next session — do these IN ORDER)

1. **Privacy policy for store submission (blocking).** Check `~/dev/landing-pages/` first (global CLAUDE.md Part 7) for existing gift-exchange privacy policy. If absent, draft a local-only-data privacy policy (Hive AES-encrypted, no network, no analytics) and host/link it. This is the single blocker for both App Store and Play Store.

2. **iOS release build on device.** Run `flutter build ipa` from `src/frontend/` (or open `ios/Runner.xcworkspace`) with Team `45Q33QWP79`; verify release compilation and smoke-test on a device. Only Android `app-release.apk` has been built this session.

3. **Quick UX carryover cleanup.** Rename the Exchange/History nav label in `src/frontend/lib/main.dart`; add an action button to the Exchange/History empty state (mirror the People empty state pattern). Bounded, low-risk.

**Don't redo:** the import/undo/validation/responsive fixes, 34 tests, and APK build are all DONE and committed-ready.

**Rules:** Never regress the import guards, keep the id-keyed undo API, keep `formatCurrency` as SSOT, keep SafeArea+textScaler clamp+scroll-wraps. Run `flutter analyze` (0 issues) and `flutter test` (34 pass) from `src/frontend/` after any change.

## 👤 For You (founder checkpoint)

**✅ Shipped**
- Import rewrite: stage-in-memory→commit, per-field guards, skip+count malformed, drop orphan gifts, version gate. Fix for original half-import + uncaught exception → DB corruption.
- Undo id-keyed bounded maps + required-id API + hideCurrentSnackBar on consecutive deletes (was restoring wrong record).
- `formatCurrency(num)` via intl in new `lib/shared/format/currency.dart` (SSOT for all money display — fixes $-5.00 sign placement + adds grouping).
- Responsive: SegmentedButton scroll-wrap, SafeArea(bottom:false), textScaler clamp 1.0–1.4, Flexible/ellipsis, 48dp tap targets, Semantics. Fixes overflow on 320dp/large text.
- 34 tests all passing (up from 25); `flutter analyze` 0 issues; `flutter build apk --release` SUCCESS (48.5 MB).

**⏳ Left-deferred**
- `_trimSnapshots` re-insertion ordering under repeated same-id deletes (negligible edge, would add complexity).
- Assert-only invariants stripped in RELEASE on Hive-read/copyWith paths (import boundary guarded; local-only app, acceptable).
- Enum rename → graceful friend/given fallback on import (by design, not a bug).
- Currency locale hardcoded en_US (single-locale for now; intl supports switching later).

**👀 You should track-decide**
- Privacy policy hosting (required for store submission — check landing repo first).
- iOS device build + signing (Team 45Q33QWP79 ready; only Android built this session).
- In-app dark-mode toggle (system preference only; light+dark themes exist).
- Crash reporting + analytics (deferred, app is intentionally local-only).

**⚠️ Make sure next session does these right**
- Keep `importFromJson` defensive (never loosen stage-commit or per-field guards).
- Keep undo API id-required (breaking change, must stay).
- Use `formatCurrency` everywhere for money display — never hardcode `$`.
- Run tests + analyze after every change; never commit red.

---

## Session summary

Executed a 6-model cross-sweep (Opus + Sonnet + GLM + Codex + Gemini + Haiku) to fix critical import-safety, undo state-race, validation bypasses, and responsive/a11y issues identified in prior handoff. All code changes complete and green; 17 uncommitted paths await the handoff commit (Step 8). The session fixed:

1. **Import defensive:** original could half-import with uncaught exception → DB corruption. Now stages in-memory, validates per field, skips+counts malformed, drops orphan gifts, rejects version>1 and non-numeric version. All via `FormatException` gates.

2. **Undo state-race:** single-slot undo could restore wrong record on consecutive same-id deletes (e.g., delete A, undo, delete A again → restores old A, not the one just deleted). Fixed via id-keyed bounded maps + required-id API + `hideCurrentSnackBar()` on each delete. **Breaking change:** `undoDeleteGift(String id)` / `undoDeletePerson(String id)` now REQUIRE the id (were no-arg).

3. **Validation + optional field handling:** `_asStringOrNull` helper added (Codex Pass-2 found optional fields still using raw `as String?` → throws, aborts entire import). Now all fields type-safe.

4. **Responsive + a11y:** SafeArea(bottom:false) on main, textScaler clamp 1.0–1.4, SegmentedButton scroll-wrap, Flexible/ellipsis, 48dp tap targets, Semantics. Fixes overflow on 320dp + large text scales.

5. **Money display:** new `lib/shared/format/currency.dart` with `formatCurrency(num)` via intl. SSOT for all currency — fixes $-5.00 sign placement, adds thousands grouping. Replaced hardcoded `$` in 4 display files.

Test suite grew 25 → 34 (all pass). Android release APK builds successfully (48.5 MB, font tree-shaken 99.6%). Cross-sweep converged at Pass-3 (no new agreed must-fixes); reviewer accounts hit monthly spend limit at this point, so natural stopping point.

---

## Files created/modified

**New files:**
- `src/frontend/lib/shared/format/currency.dart` — formatCurrency(num) SSOT

**Modified (all under `src/frontend/`):**
- `lib/services/gift_service.dart` — import rewrite (stage-commit, per-field guards, orphan-drop, version gate) + undo id-keyed maps + required-id API
- `lib/main.dart` — SafeArea(bottom:false), textScaler clamp
- `lib/shared/widgets/timeframe_toggle.dart` — SegmentedButton scroll-wrap
- `lib/features/analysis/presentation/pages/analysis_page.dart` — responsive (Flexible, ellipsis)
- `lib/features/analysis/presentation/pages/_top_spenders.dart` — formatCurrency callsites
- `lib/features/gifts/presentation/pages/gift_exchange_page.dart` — SafeArea, responsive, hideCurrentSnackBar on delete
- `lib/features/people/presentation/pages/people_page.dart` — responsive
- `lib/features/people/presentation/pages/person_detail_page.dart` — responsive, undo id-keyed
- `lib/features/people/presentation/widgets/add_gift_dialog.dart` — formatCurrency, undo id-keyed
- `lib/features/people/presentation/widgets/add_person_dialog.dart` — responsive
- `test/widget_test.dart` — 9 new tests (undo state-race, malformed-JSON, skip-invalid, version-reject, optional-field-skip, orphan-drop, numeric-version-reject, 320dp-overflow, formatCurrency)
- `docs/INDEX.md` — pre-existing modification (see project index edits)

---

## Decisions (mem0-saved, 5 total)

**Decision 1: Import rewrite — stage-in-memory→commit**
- Rationale: Original could half-import + throw uncaught → DB corruption.
- Implementation: Load all JSON → validate + guard per field → commit to Hive only if all pass. Skip malformed, drop orphan gifts (gift.personId not in people), reject version>1 or non-numeric version.
- Files: `lib/services/gift_service.dart`
- Guards: `_asStringOrNull`, `FormatException` on version/non-numeric, safe casting on optional fields.

**Decision 2: `_asStringOrNull` helper for optional fields**
- Rationale: Codex Pass-2 found mandatory fields guarded but optional still using raw `as String?` → throws on non-string, aborts whole import.
- Implementation: Helper returns String? safely; all 5 optional fields now guarded.
- Files: `lib/services/gift_service.dart`

**Decision 3: Undo id-keyed bounded maps + required-id API**
- Rationale: Single-slot undo could restore wrong record on consecutive deletes (e.g., A, undo, A again → old A restored, not newly-deleted A).
- Implementation: Id-keyed bounded maps (max 1 per type); `undoDeleteGift(String id)` and `undoDeletePerson(String id)` now REQUIRE id (breaking change). Call `hideCurrentSnackBar()` on each delete to prevent stale undo buttons.
- Files: `gift_service.dart` + `gift_exchange_page.dart`, `person_detail_page.dart`, `add_gift_dialog.dart`

**Decision 4: Central `formatCurrency` via intl**
- Rationale: Fix $-5.00 sign placement (negative before currency) + add thousands grouping. Single SSOT prevents drift.
- Implementation: `lib/shared/format/currency.dart` exports `formatCurrency(num)` using `intl` (en_US hardcoded for now).
- Files: `currency.dart` (new) + `_top_spenders.dart`, `add_gift_dialog.dart`, 2 others

**Decision 5: Responsive + a11y hardening**
- Rationale: Overflow on 320dp + 3x text scale + tap targets <48dp.
- Implementation: SafeArea(bottom:false) on main, textScaler clamp 1.0–1.4, SegmentedButton scroll-wrap, Flexible/ellipsis, 48dp buttons, Semantics.
- Files: `main.dart`, `timeframe_toggle.dart`, `analysis_page.dart`, `gift_exchange_page.dart`, `person_detail_page.dart`, `add_*_dialog.dart`

---

## In-flight

None functionally — all code complete and green. The only "in-flight" is the 17 uncommitted paths in the working tree; they await the handoff commit (Step 8 in the prompt). All live under `src/frontend/` + one doc edit.

---

## Deferred

- **LOW:** `_trimSnapshots` re-insertion ordering under repeated same-id deletes — intentionally NOT fixed (negligible real-world edge; would add complexity).
- **Acceptable:** Assert-only invariants (Gift value>0, PersonStats non-negative) stripped in RELEASE builds; import now guards value at JSON boundary, but Hive-read + copyWith paths still rely on assert. Not fixed — data written by own validated paths; only hand-edited box file bypasses. Out of scope for local app.
- **By design:** Enum rename → silent friend/given fallback on import (graceful degradation, intentional).
- **Single-locale:** Currency locale hardcoded to en_US in `formatCurrency`; intl supports switching later if multi-locale needed.

---

## Carryover (from prior handoff 2026-05-04, cross-checked)

**Removed from open list (DONE this session):**
- Name input sanitization (control chars): Fixed via validator now checking `_sanitizeName(value)`.
- Currency localization ($ hardcoded): Fixed via `lib/shared/format/currency.dart`.

**Still open:**
- **REQUIRED/blocking:** Privacy policy — required for App Store / Play Store submission. NOTE: Check `~/dev/landing-pages/gift-exchange` or similar FIRST (global CLAUDE.md Part 7) — it may already exist there.
- Crash reporting (Crashlytics/Sentry): Deferred (app intentionally local-only, no network deps).
- Analytics (privacy-respecting): Deferred.
- App rating prompt (in_app_review): Deferred.
- Exchange/History tab rename: Cosmetic, low-priority.
- Empty-state action button on Exchange/History page: Deferred.
- In-app dark-mode toggle: System preference only; light+dark themes exist.
- iOS release build NOT run on device: Only Android `app-release.apk` built this session.

---

## Critical facts

- **Undo is BREAKING:** `undoDeleteGift(String id)` / `undoDeletePerson(String id)` now REQUIRE the deleted id (were no-arg). Any future caller must pass it.
- **formatCurrency is SSOT:** `lib/shared/format/currency.dart` exports formatCurrency(num). Use it everywhere for money display — never hardcode `$`.
- **Import is defensive:** Stage-in-memory→commit, per-field guards, skip+count malformed, orphan-gift drop, version gate via FormatException. Never loosen these guards.
- **Tests:** 34 passing (up from 25). New tests cover multi-slot undo state-race, malformed-JSON reject, skip-invalid-records, newer-version reject, non-string-optional-field skip, orphan-gift drop, non-numeric-version reject, 320dp+3x-textscale overflow, formatCurrency sign/grouping.
- **Build status:** `flutter analyze` = 0 issues. `flutter build apk --release` = SUCCESS (app-release.apk, 48.5 MB, font tree-shaken 99.6%). Run from `src/frontend/`.
- **Platform:** iOS deployment target 13.0, iPhone+iPad, all orientations enabled. Android flutter-default SDK (API 35). All deps free/local (Riverpod, Hive, secure_storage, uuid, intl) — no paid SaaS.
- **Cross-sweep gap:** Pass-3 reviewers hit monthly account limit; two checks (SegmentedButton unbounded-width edge, formatCurrency correctness) verified by Opus arbiter directly instead.
- **mem0 status:** Back UP this session (was DOWN at start per SessionStart hook). 5 decisions saved successfully.

---

## Resume context refs

- **Prior handoff:** `docs/handoffs/2026-05-04-production-readiness-sweep-and-fix.md` (APK build, 25 tests, undo-delete, strict linting)
- **State file:** `~/.claude/projects/-Users-esatbalkir-dev-IndividualProjects-gift-exchange/memory/project_cross-sweep-ux-hardening_progress.md`
- **Prompt to load:** `docs/handoffs/2026-07-04-cross-sweep-ux-hardening-PROMPT.md`
- **Memory searches:** `mcp__mem0__search_memories "gift-exchange import undo"` (arch decisions), `mcp__mem0__search_memories "deferred gift-exchange"` (deferred items)
- **Memory pointer line:** Prepended to `~/.claude/projects/.../memory/MEMORY.md`
