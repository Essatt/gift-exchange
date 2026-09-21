# Gift Exchange — Documentation Index

📥 **Inbox:** unactioned items in [../inbox/inbox.md](../inbox/inbox.md)

Last Updated: 2026-09-21

## Project

- `docs/PRD.json` — Product requirements document

## Handoffs

- See [docs/handoffs/INDEX.md](handoffs/INDEX.md) for session handoff reports

## Implementation

- `lib/shared/format/currency.dart` — Central formatCurrency(num) SSOT for all money display (sign placement, grouping)
- `lib/services/gift_service.dart` — Defensive import (stage-commit, per-field guards, skip malformed, drop orphans, version gate); id-keyed undo API

## Sweeps

- [2026-05-03 Production Readiness Sweep](sweeps/sweep-production-readiness-2026-05-03.md) — 35 issues found, 6 critical, pre-fix audit
- [2026-09-21 Design Sweep](sweeps/sweep-design-2026-09-21.md) — cross-skill design audit and HTML redesign decisions
- [2026-07-04 Cross-sweep UX Hardening](handoffs/2026-07-04-cross-sweep-ux-hardening.md) — 6-model cross-sweep: import-safety, undo state-race, validation, responsive/a11y fixes; 34 tests

## Design artifacts

- [Gift Exchange redesign prototype](../design/gift-exchange-redesign.html) — clickable HTML redesign for the audited UI and flows
