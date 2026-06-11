# Figma design truth (build + VQA)

Every skill that **implements** or **verifies** UI work (`/build`, `/code-build`, `/figma-build`, `/plan`, `/review`) must treat the **live Figma file** as the authoritative design spec when the ticket references a Figma node or file.

**`research/` and `plan.md` are supporting context only** — never the source of truth for layout, typography, color tokens, copy, component variants, or spacing. If research/plan contradict Figma, **Figma wins**.

---

## When this applies

A ticket **has a Figma surface** unless its **Figma VQA Checklist** body is exactly:

`**N/A — no Figma artifact (backend / API / infra ticket).**`

(or the bug-template equivalent)

Otherwise, any of these signals mean Figma grounding is **mandatory**:

- **Figma VQA Checklist → Figma source** has `file_key` and/or `node_id`
- **Design reference** table has a Figma URL, file key, or node ID
- **References** or archived **`context/CTX-*`** capture links to `figma.com/design/...`
- Any `figma.com` URL appears anywhere in `ticket.md` or the archived context capture

---

## Resolve `file_key` + `node_id`

Search in this order; stop at the first complete pair:

1. **`ticket.md` → Figma VQA Checklist → Figma source** table (`file_key`, `node_id`)
2. **`ticket.md` → Design reference** table
3. **Archived context capture** (`context/CTX-*/ticket.md`) → **Design reference**
4. Parse from any `figma.com/design/<fileKey>/...?node-id=<nodeId>` URL in the ticket (convert `-` to `:` in node IDs)

If a ticket has a Figma surface but `file_key` or `node_id` cannot be resolved, **hard stop** — ask the user to fill the Figma source block or paste the URL. Do not implement or VQA UI from prose alone.

---

## Figma MCP pull (design truth snapshot)

Before writing or changing UI code, and again at `/review`, pull fresh data from the Figma MCP server available in the runtime. Browse MCP tool descriptors first; common tool names:

| Purpose | Typical tool name |
| --- | --- |
| Hierarchy, copy, Code Connect hints, token bindings | `get_design_context` |
| Variable / token definitions on the node | `get_variable_defs` |
| Reference screenshot | `get_screenshot` |
| Explicit dimensions / auto-layout | `get_metadata` |

**Claude Code** may prefix tools as `mcp__claude_ai_Figma__*`. **Cursor** uses the `plugin-figma-figma` MCP server with the same logical names.

### Persist the build-time snapshot

After the pull, write **`{ticket-folder}/research/figma-design-truth.md`** with:

```markdown
# Figma design truth — {TICKET-ID}

Captured at: {ISO-8601 date}
file_key: {key}
node_id: {id}
Deep link: {url}

## Source
Pulled via Figma MCP at build time. **Authoritative over plan.md and research/*.**

## Design context summary
<!-- Key layout, auto-layout, hierarchy from get_design_context -->

## Tokens / variables
<!-- From get_variable_defs — exact token names, not paraphrased -->

## Copy (exact)
<!-- Every TEXT node label, placeholder, CTA — verbatim -->

## Code Connect / components
<!-- Mapped components and props from design context -->

## Screenshot
<!-- Relative path: research/figma-design-truth.png -->
```

Save the screenshot as **`research/figma-design-truth.png`** (build) or refresh **`research/figma-source.png`** (review per `/review` skill).

**Do not skip the MCP pull** because `research/` or `plan.md` already describe the UI. Those may be incomplete or stale.

---

## Authority order (strict)

1. **Live Figma MCP read** (current file state)
2. **Archived context capture** (`context/CTX-*/ticket.md`) — full dev-handoff scaffold
3. **`ticket.md` Design reference + Requirements** — migrated summary
4. **`research/*.md`** — investigation notes only
5. **`plan.md`** — execution checklist only; **never** invent visual specs not grounded in 1–3

---

## `/build` orchestrator obligations

When the ticket has a Figma surface:

1. Resolve `file_key` + `node_id` per above — hard stop if unresolved.
2. **Before spawning any build agent**, run the Figma MCP pull and write `research/figma-design-truth.md` + `research/figma-design-truth.png`.
3. Inject into **every** spawned agent prompt:
   - Resolved `file_key`, `node_id`, deep link
   - Path to `research/figma-design-truth.md`
   - Explicit instruction: *"Figma MCP design truth is authoritative. Do not implement UI from plan.md or research/ alone. Re-read figma-design-truth.md before each UI step."*
4. For **`code-build`** agents, add: *"First assigned UI step: confirm figma-design-truth.md exists; if absent, pull Figma MCP before writing code."*

If the orchestrator cannot reach Figma MCP, **stop** and report — do not spawn UI build agents blind.

---

## `/code-build` obligations

When assigned steps touch UI (components, pages, styles, tokens, copy):

1. Read `research/figma-design-truth.md` if present.
2. If missing and the ticket has a Figma surface, **pull Figma MCP first** and write the snapshot — then implement.
3. Map implementation to **exact token names**, **exact copy**, and **Code Connect targets** from the snapshot — not from plan prose.
4. In `plan.md` **Notes**, record any intentional deviation from Figma with the Figma value vs built value.

Non-UI steps (API, infra, pure logic) may skip the MCP pull.

---

## `/review` obligations

1. **Re-pull Figma MCP at review time** — do not reuse `figma-design-truth.md` from build as the comparison baseline without confirming the file still matches (prefer fresh `get_design_context` + `get_variable_defs`).
2. Fill assertion table **Design (Figma)** columns from the **fresh MCP pull**, not from research or plan.
3. Fill **Build (implemented)** from actual source files / rendered DOM — not from what plan.md claims was built.
4. Any row where research/plan disagrees with Figma: mark using **Figma** as Design column truth; if build matches research but not Figma, result is **FAIL**.

---

## `/plan` obligations

When the ticket has a Figma surface:

1. Pull Figma MCP (or read an existing `figma-design-truth.md` if fresh) before writing UI-related steps.
2. Reference `file_key` / `node_id` in **Dependencies & Tools** and in relevant **Steps**.
3. First step in any **`code-build`** UI phase should be: *"Read `research/figma-design-truth.md`; refresh from Figma MCP if missing or stale."*
4. Do not paraphrase design specs in the plan — point agents at the Figma node and the design-truth snapshot.
