Continue gift-exchange cross-sweep-ux-hardening. Previous session (2026-07-04) ran a 6-model cross-sweep that fixed critical import-safety, an undo state-race, validation bypasses, and responsive/a11y issues; all changes are committed and the Android release APK builds. Do NOT re-audit the codebase, do NOT re-run the cross-sweep, do NOT re-fix the import/undo/validation/responsive items — they are done and covered by 34 passing tests.

## Next-session model + effort recommendation
**Run this prompt in:** Fresh Claude Code session on Sonnet high
**Why:** Residual work is bounded, non-critical store-prep + UX execution against a clear list (privacy policy, tab rename, empty-state button, iOS on-device build) — spec-driven mechanical execution, matches the "mechanical execution against locked spec" heuristic row.
**PR-review tier (when applicable):** Opus high — only if a change touches iOS signing/entitlements or a data-migration path; otherwise N/A.
**Stop cause from prior session (if any):** Cross-sweep converged (Pass-3 found no new agreed must-fixes) and the multi-vendor reviewer accounts hit their monthly spend limit — a natural stop with all work committed-ready.
**Session routing plan:** single session

## Load context (in order)
1. Read docs/handoffs/2026-07-04-cross-sweep-ux-hardening.md — full session report
2. Read ~/.claude/projects/-Users-esatbalkir-dev-IndividualProjects-gift-exchange/memory/project_cross-sweep-ux-hardening_progress.md — state map
3. mcp__mem0__search_memories "gift-exchange import undo" — architectural decisions
4. mcp__mem0__search_memories "deferred gift-exchange" — deferred items
5. mcp__mem0__search_memories "carryover gift-exchange" — still-open items
6. Read src/frontend/lib/services/gift_service.dart (import + undo contract) and src/frontend/lib/shared/format/currency.dart (money SSOT)

## Critical facts
- Undo API is a BREAKING CHANGE: undoDeleteGift(String id) / undoDeletePerson(String id) now REQUIRE the deleted id. Any new caller must pass it.
- lib/shared/format/currency.dart formatCurrency(num) is the SSOT for money display — use it, don't hardcode '$'.
- importFromJson is now defensive: stages then commits, skips+counts malformed records, drops orphan gifts, rejects version>1 / non-numeric version via FormatException. Do NOT loosen these guards.
- Tests: 34 pass, flutter analyze 0 issues, flutter build apk --release SUCCEEDS (app-release.apk 48.5 MB). Run from src/frontend/.
- Platform: iOS 13+ iPhone+iPad all orientations; Android flutter-default SDK (API 35). All deps free/local — no paid SaaS. Affordability requirement met.
- Privacy policy may already exist in a SEPARATE landing repo (~/dev/landing-pages/…) — CHECK there before claiming it's missing (global CLAUDE.md Part 7).

## In-flight (unfinished right now)
None functionally — all code is complete and green. The only "in-flight" is that the working tree changes await the handoff commit (Step 8). None this session beyond that.

## Deferred this session
- LOW: _trimSnapshots re-insertion ordering under repeated same-id deletes — intentionally not fixed (negligible edge).
- Assert-only invariants stripped in release on Hive-read/copyWith paths — not fixed (import boundary is guarded; local-only app).
- Enum rename → silent friend/given import fallback — left by design (graceful degradation).
- formatCurrency locale hardcoded en_US — single-locale for now.

## Carryover still open
- Privacy policy — REQUIRED/blocking for store submission (check landing repo first).
- Crash reporting (Crashlytics/Sentry) — deferred (local-only).
- Analytics (privacy-respecting) — deferred.
- App rating prompt (in_app_review) — deferred.
- Exchange/History tab rename — cosmetic.
- Empty-state action button on Exchange/History page.
- In-app dark-mode toggle (system-only currently).
- iOS release build NOT run on device (only Android APK built).

## Suggested next steps (ordered by priority)
### Step 1 — Privacy policy for store submission (blocking)
First check ~/dev/landing-pages/ for an existing gift-exchange privacy policy/terms (global CLAUDE.md Part 7). If absent, draft a local-only-data privacy policy (Hive AES-encrypted, no network, no analytics) and host/link it. This is the single blocking item for both stores.

### Step 2 — iOS release build on device
Run flutter build ipa (or open ios/Runner.xcworkspace) with Team 45Q33QWP79; verify it compiles for release and smoke-test on a device. Only Android app-release.apk has been built.

### Step 3 — Quick UX carryover cleanup
Rename the Exchange/History nav label in src/frontend/lib/main.dart; add an action button to the Exchange/History empty state (mirror the People empty state pattern). Bounded, low-risk.

### Step 4 — Optional store-readiness extras
If pursuing production: add in_app_review rating prompt at a positive-engagement milestone; decide on crash reporting (Sentry is privacy-friendlier than Crashlytics for a local app). All deferred, not blocking a beta.

## Rules
- Never regress: keep importFromJson's stage-then-commit + all field guards; keep the id-keyed undo API; keep formatCurrency as money SSOT; keep SafeArea + textScaler clamp + SegmentedButton scroll-wraps.
- Run flutter analyze (0 issues) + flutter test (34 pass) from src/frontend/ after any change; never commit red.
- Critical-code (data-integrity/migration/import) stays on Opus/inline — do not delegate to cheap coders.
- Do NOT add Firebase/network deps unless the user explicitly opts into cloud features — the app is intentionally local-only.
- Diff-verify any subagent output against real bytes before trusting it.

Start with Step 1.
