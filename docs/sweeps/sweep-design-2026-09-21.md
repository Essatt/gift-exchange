# Gift Exchange design sweep

Date: 2026-09-21  
Scope: current Flutter UI and interaction flows in `src/frontend/lib`  
Output: [interactive HTML redesign](../../design/gift-exchange-redesign.html)

## Executive finding

The app has a sound Material 3 foundation and a coherent data model, but its product experience is split across screens that each work in isolation. The main release risk is interaction clarity: users must infer where to log a gift, what “History” means, what a balance represents, and how to recover from destructive actions. The redesign should start with the task “log and remember a gift” and make people, exchanges, analysis, and backup feel like views of one journal.

There are no P0 visual or interaction blockers in the current code. Five P1 themes should be addressed before calling the UI release-ready:

1. Rename and clarify the primary navigation and make gift entry available from a consistent primary action.
2. Replace the dense, nested gift dialog with a guided form that keeps the person, direction, event, date, and value hierarchy visible.
3. Make semantic meaning explicit with labels and directional icons; color must support meaning rather than carry it.
4. Give destructive actions specific consequences and reliable recovery feedback.
5. Promote backup/import into a visible data-safety surface instead of hiding it in an overflow menu and clipboard-only flow.

## Sweep coverage

The `/sweep` routing pass classified this design chain:

`design`, `ux-design`, `ux-researcher-designer`, `ui-design-system`, `ui-ux-design-review`, `ui-ux-pro-max`, `frontend-design`, `accessibility-auditor`, `contrast-checker`, `web-design-guidelines`, `critique`, `design-motion-principles`, `emil-design-eng`, `impeccable`, `design-consultation`, `design-html`, `taste-design`, `gsd-ui-review`, `plan-design-review`, and `huashu-design`.

Six read-only review lanes returned independent findings covering UX, UI/UX review, accessibility, and contrast. The remaining lenses were applied during synthesis using their audit criteria. `gsd-ui-review` was unavailable in the live skill router; its intended six-pillar review was covered manually. No reviewer changed application files.

## Consensus findings

| Priority | Finding | Evidence | Why it matters | Redesign decision |
| --- | --- | --- | --- | --- |
| P1 | Navigation terminology is ambiguous. | `src/frontend/lib/main.dart:246-264`; `src/frontend/lib/features/gifts/presentation/pages/gift_exchange_page.dart:21-30` | “History” opens “Recent Exchanges,” so users must guess whether the destination is a log, a gift-entry surface, or an activity history. | Use `People`, `Exchanges`, and `Analysis` consistently. Add a persistent `Log gift` action that can start from a person or choose one. |
| P1 | The main gift task has too much path depth. | `src/frontend/lib/features/people/presentation/pages/person_detail_page.dart:211-223`; `src/frontend/lib/features/gifts/presentation/pages/gift_exchange_page.dart:97-125` | A gift can only be added from a person detail page. The empty History state redirects to People, and the visible FAB is icon-only in the context where the task matters. | Prototype a labeled `Log gift` action on People, Exchanges, and Person detail. The form starts with person selection when launched globally. |
| P1 | Gift entry is dense and modal-heavy. | `src/frontend/lib/features/people/presentation/widgets/add_gift_dialog.dart:127-177,192-376` | Direction, event labels, date, description, value, and quick values compete for attention. Creating a new label opens a second dialog and interrupts completion. | Use a full-height sheet on mobile / side panel on desktop with a clear step order: person → given/received → occasion → date → item and amount. Keep `Add occasion` inline but secondary. |
| P1 | Financial meaning relies on color and shorthand. | `src/frontend/lib/features/people/presentation/pages/person_detail_page.dart:227-345`; `src/frontend/lib/features/gifts/presentation/pages/gift_exchange_page.dart:147-223`; `src/frontend/lib/features/analysis/presentation/pages/analysis_page.dart:220-291` | Red/teal and directional icons are not enough for color-vision users, dark mode, or quick scanning. “Net Balance” is also not explained. | Pair every state with text, sign, and icon. Make net balance the primary metric and explain “received minus given.” Use theme-derived tokens instead of raw relationship colors. |
| P1 | Custom controls have accessibility gaps. | `src/frontend/lib/features/people/presentation/widgets/add_gift_dialog.dart:268-291,402-408`; `src/frontend/lib/features/people/presentation/pages/person_detail_page.dart:428-471` | Gesture-only date and direction controls and bare expandable headers may be unreachable or unclear to keyboard, switch, VoiceOver, and TalkBack users. | Use native semantic controls, focusable buttons, expanded state announcements, focus restoration, and at least 48dp targets. |
| P1 | Destructive action recovery is inconsistent. | `src/frontend/lib/shared/widgets/confirm_delete_dialog.dart:4-28`; `src/frontend/lib/features/people/presentation/pages/people_page.dart:50-89`; `src/frontend/lib/features/gifts/presentation/pages/gift_exchange_page.dart:49-87` | Person deletion removes all gifts. Gift deletion has generic copy. Undo is transient and failures are swallowed. Raw exceptions can reach users. | Use consequence-specific confirmation, a distinct destructive action, visible undo state with an accessible announcement, and human-readable errors. |
| P1 | Data safety is hidden in Analysis overflow and clipboard-only. | `src/frontend/lib/features/analysis/presentation/pages/analysis_page.dart:40-140` | A user cannot easily discover whether a backup exists or understand how to recover. Import confirmation does not preview what will be added. | Prototype a visible Backup area with export status, import preview, and clear “adds to existing data” language. |
| P2 | History is hard to browse at scale. | `src/frontend/lib/features/gifts/presentation/pages/gift_exchange_page.dart:28-93` | Chronological cards have no search, person filter, event filter, or grouping beyond date order. | Add search, filter chips, person shortcuts, and grouped timeline sections. |
| P2 | Person detail buries records inside event accordions. | `src/frontend/lib/features/people/presentation/pages/person_detail_page.dart:103-223,421-557` | Collapsed event groups hide the records and their edit/delete affordances. | Show event summary plus explicit expand state; keep the first relevant group open after add/edit and expose a visible add action. |
| P2 | Analysis mixes scope, view, and backup actions. | `src/frontend/lib/features/analysis/presentation/pages/analysis_page.dart:40-189`; `src/frontend/lib/shared/widgets/timeframe_toggle.dart:14-48` | “All/Year/Month,” “By Person/By Label,” totals, and overflow actions share one vertical stack without a clear reading order. | Separate period scope from analysis view, add short definitions, and make the comparison/ranking visual primary. |
| P2 | Empty/loading/error states are under-specified. | `src/frontend/lib/features/people/presentation/pages/people_page.dart:15-21,106-129`; `src/frontend/lib/features/analysis/presentation/pages/analysis_page.dart:37-77` | Empty lists are not clearly distinguished from unavailable data, and failure feedback is transient. | Give each state a title, explanation, next action, and accessible announcement. The prototype includes first-use and filtered-empty states. |
| P2 | Dense layouts are fragile at large text sizes. | `src/frontend/lib/main.dart:204-210`; `src/frontend/lib/features/people/presentation/pages/people_page.dart:168-179`; `src/frontend/lib/features/analysis/presentation/pages/_top_spenders.dart:60-74` | The global 1.4× cap and many one-line ellipses can hide names, labels, values, and dates. | Respect system scaling where possible, test at 1.3–2×, let rows wrap, and avoid horizontal scrolling as the only fallback. |
| P3 | Visual tokens are repeated ad hoc. | `src/frontend/lib/main.dart:95-180` and screen-level font sizes/radii | Repeated 8/10/12/16/20px radii and many one-off font sizes make the product feel assembled rather than designed as one system. | Adopt shared shape, spacing, type, semantic-color, and component-state tokens. |

## Proposed design direction

The redesign uses a quiet, warm “gift journal” direction: paper-like surfaces, ink-forward type, one aubergine action color, and restrained coral/blue-green semantic accents. The tone should feel personal and trustworthy rather than festive or finance-dashboard-like.

- **Canvas:** warm parchment `#F7F4EE`; elevated surface `#FFFDF8`; ink `#252329`; muted ink `#706C72`.
- **Primary action:** aubergine `#6B4EFF` with a light lavender focus/surface tint.
- **Given:** coral `#B94D42` with a `Given` label and arrow-up icon.
- **Received:** blue-green `#1D7770` with a `Received` label and arrow-down icon.
- **Balanced:** ink/neutral treatment with a check icon and the word `Balanced`.
- **Typography:** system sans with a distinctive display weight; use type roles rather than per-widget font sizes.
- **Shape:** 12px controls, 18px cards, 24px sheets; flat surfaces with borders, limited elevation for transient UI.
- **Motion:** short spring-like press feedback, clear expand/collapse, and a short success confirmation. No decorative perpetual motion.
- **Responsive rule:** mobile-first single column under 768px; desktop gets a narrow navigation rail and a content canvas, while the core interaction stays identical.

## HTML prototype coverage

The prototype at `design/gift-exchange-redesign.html` covers the screens and states that the audit identified as redesign candidates:

1. **People:** first-use onboarding state, person list, relationship context, recent activity, and primary `Log gift` action.
2. **Exchanges:** searchable/filterable timeline, clear given/received badges, grouped dates, and visible actions.
3. **Person detail:** primary net balance, period filter, event summaries, expanded gift records, and contextual `Log gift`.
4. **Log gift:** person selection, direction choice, occasion, date, item, amount, validation, and save feedback.
5. **Analysis:** period scope, defined net balance, ranking bars, label comparison, and empty filtered state.
6. **Backup:** export status, import preview, and recovery copy.
7. **Recovery:** delete confirmation and undo toast as explicit interaction states.

## Implementation order for Flutter

1. Introduce shared design tokens and semantic state components in the theme layer.
2. Add a global/contextual `Log gift` flow that accepts an optional person id.
3. Replace custom gesture controls with native accessible controls and add semantics for expansion, direction, and results.
4. Rework gift/person cards to separate primary content from actions and support wrapping at large text sizes.
5. Promote backup/import into a visible surface and add import preview/status copy.
6. Add history search/filter/grouping and improve analysis hierarchy.
7. Run TalkBack, VoiceOver, keyboard traversal, dark mode, 200% text, narrow phone, landscape, and tablet checks.

## Validation checklist

- A first-time user can add a person and log a gift without being told which tab to use.
- A returning user can find an exchange by person, date, or occasion.
- Given, received, and balanced remain distinguishable without color.
- A user understands exactly what deleting a person removes and can undo it reliably.
- Export/import state is discoverable and explains whether existing data is preserved.
- All core controls are reachable with screen readers, keyboard/switch input, and large text.
- The same labels and action hierarchy appear on both iOS and Android.
