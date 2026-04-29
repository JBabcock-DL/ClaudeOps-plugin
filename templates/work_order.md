---
name: Work Order
about: Agile ticket for features, enhancements, or design-system work — structured so research, planning, build, and VQA agents can run without tribal knowledge
labels: work-order
---

<!--
WO tickets use the full scaffold below when created via `/create-ticket`, `/doc-handoff`-style enrichment, or human authoring.
Stages: 🔍 Research → 📋 Planning → 🛠️ Build → ✅ VQA — each section tells agents what to produce or validate at that gate.
-->

## Goal

<!--
One paragraph: what shipped state looks like — product outcome + engineering outcome (routes live, parity with design where applicable).
-->

---

## Problem story

<!--
As a [persona], I want [capability] so that [outcome].

Optional: Problem — [pain today]. Opportunity — [what changes if we ship this].
-->

## Hypothesis (optional)

<!--
We believe [intervention] for [persona] will [measurable outcome].

We'll know we're right when [signal].
-->

---

## User stories

<!--
Scrum-style slices the build agent can implement independently. Checkbox or numbering is fine.

Example:
- As a shopper, I can save payment methods so checkout is faster on return visits.

Add “Out of MVP” stories under ### Deferred if helpful.
-->

- [ ] <!-- story 1 -->

## Design reference *(when UI work applies)*

| | |
| --- | --- |
| **Figma** | <!-- deep link --> |
| **File key** | <!-- optional --> |
| **Node ID** | <!-- optional --> |
| **Frame / scope** | <!-- e.g. Checkout — payment methods --> |

**Screenshot / preview:** <!-- MCP asset URL, PNG, or “see link” -->

*If purely API / backend WO, replace this block with **N/A — no Figma artifact** and point to specs below.*

---

## Requirements

<!-- Break down so `/plan` can map tasks without re-interviewing the designer. -->

### Functional

<!-- Numbered bullets: flows, validations, persistence, integrations, toggles -->

1. <!-- … -->

### Visual / UX

<!-- Typography, spacing, breakpoints, responsive rules, tokens — tie to DS variables -->

- <!-- … -->

### Technical / architectural

<!--
Stack anchors: routes, services, repos, queues, schemas, env flags. Code Connect or component targets if applicable.
-->

- <!-- … -->

---

## Acceptance criteria *(definition of done)*

- [ ] <!-- testable criterion -->
- [ ] <!-- … -->

## Out of scope

<!-- Deliberately excluded: future phases, platform variants, integrations not in this WO -->

-

---

## Testing & verification

### Functional QA

-

### Visual / design QA

-

### Accessibility *(WCAG AA where applicable)*

-

### Telemetry / observability *(if needed)*

-

---

## 🔍 Ready for `/research`

<!--
Research agent: fill **`research/`** with findings — unknowns addressed here unblock planning.

Suggested outputs:
-

Open questions *(delete when answered)*:

-
-->

-

## 📋 Ready for `/plan`

<!--
Planning agent: `plan.md` should cite sections above — no orphaned scope.

Unresolved dependencies:

-
-->

-

## 🛠️ Ready for `/build`

<!--
Build agents: prerequisites before implementation

-
-->

-

## References

<!-- Links to tickets, RFCs, Confluence, metrics dashboards, Slack threads -->

-
