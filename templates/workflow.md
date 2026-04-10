# claude-ops — Agent Workflow Context

This document describes how this project is structured and how work is tracked. All agents operating in this repo should follow this workflow.

---

## Project Goal

<!-- ADD YOUR GOAL HERE — describe what this project is building or solving -->
[ADD YOUR GOAL HERE]

All work is managed through GitHub Issues synced to the **claude-ops** GitHub Project board.

---

## Repository Structure

```
.github/
├── templates/               # Ticket templates and agent workflow context
│   ├── workflow.md          # This file — agent context document
│   ├── bug_report.md        # Template for bug tickets
│   └── work_order.md        # Template for feature/work order tickets
└── Sprint {N}/              # One folder per sprint
    └── {TICKET-ID}-{slug}/  # One folder per ticket
        ├── ticket.md        # The ticket definition (synced to GitHub Issues)
        ├── plan.md          # Implementation approach and step checklist
        ├── research/        # Data, findings, reference docs (.md, .json, etc.)
        └── scripts/         # Any automation, tooling, or helper scripts
```

---

## Ticket Types

| Type | Label | Template | Naming |
|---|---|---|---|
| Bug | `bug` | `bug_report.md` | `BUG-{N}-{slug}` |
| Work Order | `work-order` | `work_order.md` | `WO-{N}-{slug}` |

---

## Ticket Lifecycle

1. **Create ticket** — `/create-ticket` creates the folder, `ticket.md`, stub `plan.md`, GitHub issue, and syncs to the board (status: **Context Backlog**)
2. **Research** *(optional, recommended for unfamiliar work)* — `/research` investigates the problem domain and writes findings to `research/`; moves ticket to **In Research**
3. **Plan** — `/plan` enters plan mode for interactive review, writes the approved plan to `plan.md` (including a `## Build Agents` section defining parallel phases), and moves ticket to **In Planning**
4. **Build** — `/build` reads the `## Build Agents` section, moves ticket to **In Build**, and spawns build agents in parallel phases; agents within a phase run simultaneously, phases run sequentially. Individual build skills (`/code-build`, `/doc-build`, `/script-build`, `/api-build`, `/figma-build`) can be used directly for single-domain tickets.
5. **Verify** — `/vqa` runs a QA pass; moves ticket to **In Verification** → **Completed**

> Skip research for well-understood, mechanical tickets where requirements are unambiguous.

---

## GitHub Project

<!-- CONFIGURE: Replace all values in this section after running /project-start or creating your GitHub Project board manually. -->

- **Project name:** [CONFIGURE: your GitHub Project board name]
- **Project ID:** `[CONFIGURE: GitHub Project node ID — looks like PVT_kwHOD9B30s4BTj7z — find it with: gh project list --owner YOUR_USERNAME]`
- **Owner:** `[CONFIGURE: your GitHub username or org — e.g. my-org or myusername]`
- **Status field ID:** `[CONFIGURE: the node ID of the Status field — looks like PVTSSF_lAHOD9B30s4BTj7zzhAyGKQ — find it with: gh project field-list NUMBER --owner YOUR_USERNAME --format json]`

### Status Options

<!-- CONFIGURE: Replace each option ID with the actual singleSelectOptionId values from your project board.
     Find them with: gh project field-list NUMBER --owner YOUR_USERNAME --format json | jq '.fields[] | select(.name=="Status") | .options' -->

| Status | Option ID |
|---|---|
| Context Backlog | `[CONFIGURE: option ID for Context Backlog status]` |
| In Research | `[CONFIGURE: option ID for In Research status]` |
| In Planning | `[CONFIGURE: option ID for In Planning status]` |
| In Build | `[CONFIGURE: option ID for In Build status]` |
| In Verification | `[CONFIGURE: option ID for In Verification status]` |
| Completed | `[CONFIGURE: option ID for Completed status]` |

---

## Key Commands

```bash
# Create a GitHub issue
gh issue create --repo [CONFIGURE: owner/repo] --title "..." --label "..." --body "..."

# Add issue to project board
gh project item-add [CONFIGURE: project number — integer, e.g. 1] --owner [CONFIGURE: owner] --url https://github.com/[CONFIGURE: owner/repo]/issues/{N}

# Move issue to a status column
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "[CONFIGURE: Project ID — e.g. PVT_kwHOD9B30s4BTj7z]"
    itemId: "{PVTI_...}"
    fieldId: "[CONFIGURE: Status field ID — e.g. PVTSSF_lAHOD9B30s4BTj7zzhAyGKQ]"
    value: { singleSelectOptionId: "[CONFIGURE: status option ID]" }
  }) {
    projectV2Item { id }
  }
}'

# List issues in the project
gh project item-list [CONFIGURE: project number] --owner [CONFIGURE: owner]
```

---

## MCP Integrations

MCP (Model Context Protocol) servers extend what agents can do within this workflow — connecting to external tools, APIs, and platforms without leaving the ticket lifecycle. Any MCP-driven work should still be tied to a ticket.

### General conventions for MCP work
- Reference any external resource URLs (files, boards, APIs) in `ticket.md` under **References**
- Document what was read, written, or changed via MCP in `plan.md` after completion
- MCP tool calls are treated as implementation steps — they belong in the work phase, after a plan exists

### Available MCP servers

#### Figma (`mcp__claude_ai_Figma__*`)
Read designs, write to the Figma canvas, manage variables and component code connections.

Use when a work order involves:
- Reading a Figma design to inform implementation
- Writing components, frames, or variables back to a Figma file
- Generating diagrams in FigJam
- Managing Code Connect mappings between Figma and the codebase

<!-- ADD YOUR MCP SERVERS HERE
#### [Server Name] (`mcp__<server>__*`)
Brief description of what it connects to and what it can do.

Use when a work order involves:
- ...
-->

---

## Conventions

- Ticket IDs are sequential per type (`BUG-001`, `BUG-002`, `WO-001`, `WO-002`)
- Sprint folders are named `Sprint {N}` — do not use dates
- All `ticket.md` files include a `github_issue` frontmatter field linking to the GitHub issue number
- `plan.md` is always a stub when first created — fill it in before starting work
