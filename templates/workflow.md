# claude-ops — Agent Workflow Context

This document describes how this project is structured and how work is tracked. All agents operating in this repo should follow this workflow.

---

## Project Goal

<!-- ADD YOUR GOAL HERE — describe what this project is building or solving -->
[ADD YOUR GOAL HERE]

## Ticket Backend

<!-- CONFIGURE: set to either `github` or `jira` during /project-start. Agents must read this field to know which backend to use. -->

**Backend:** `[CONFIGURE: github | jira]`

Exactly one of the two **Ticket Tracker** sections below applies, based on the backend above. The other section is marked N/A.

---

## Repository Structure

```
CLAUDE.md                  # Created by /project-start — instructs agents to read/update memory.md without user prompting
memory.md                  # Short running memory to save agent context (see Conventions)
.github/
├── templates/             # Ticket templates and agent workflow context
│   ├── workflow.md        # This file — agent context document
│   ├── bug_report.md      # Template for bug tickets
│   ├── work_order.md      # Template for work order tickets
│   ├── context.md         # Template for context tickets
│   └── agent-handoff.md   # Prompt block for new agent sessions
└── Sprint {N}/            # One folder per sprint
    └── {TICKET-ID}-{slug}/  # One folder per ticket (BUG-###, WO-###, or CTX-###)
        ├── ticket.md        # The ticket definition (synced to the backend)
        ├── plan.md          # Implementation approach and step checklist (not created for CTX tickets until promoted)
        ├── research/        # Data, findings, reference docs (.md, .json, etc.)
        └── scripts/         # Any automation, tooling, or helper scripts
```

### memory.md and CLAUDE.md (recommended)

- **`CLAUDE.md`** at the repository root (created by `/project-start`) tells Claude to **read `memory.md` first** and **update it** when durable facts change—**the user should not have to repeat those instructions.** Keep the **Agent rules** block when editing that file.
- **`memory.md`** holds short, project-level facts: backend choice, default branch, stack, build/git defaults, naming conventions, integration pointers, and “do not repeat” notes. Read it at session start, then `workflow.md` for the full spec. This keeps sessions cheaper on context and tokens.
- `ticket.md` / `plan.md` remain the source of truth for a single unit of work; do not duplicate per-ticket steps into `memory.md`.

---

## Ticket Types

| Type | Label | Template | Naming | Lifecycle |
|---|---|---|---|---|
| Bug | `bug` | `bug_report.md` | `BUG-{N}-{slug}` | Full lifecycle (create → research → plan → build → vqa) |
| Work Order | `work-order` | `work_order.md` | `WO-{N}-{slug}` | Full lifecycle (create → research → plan → build → vqa) |
| Context | `context` | `context.md` | `CTX-{N}-{slug}` | Triage-only — holding pen for raw notes / design context; must be promoted to `bug` or `work-order` before research / planning / building |

Each type has its own sequential numbering (`BUG-001`, `BUG-002`, `WO-001`, `CTX-001`, etc.).

### Context tickets

Context tickets are an intake format for **bulk raw information** — designer notes, research transcripts, meeting dumps, Figma comments, Slack threads, customer interviews, analytics observations. They intentionally skip the Requirements / Success Criteria structure of bug and work-order tickets so nothing blocks people (or agents) from dropping context in quickly.

A context ticket stays in **Context Backlog** until it is **promoted** into the correct type:
- `/create-ticket promote {CTX-ID}` — interactively promote a single CTX ticket into a `bug` or `work-order`
- `/create-backlog` — bulk-triage every unpromoted CTX ticket in the current sprint, classifying each into a `bug` or `work-order` (with user confirmation per ticket)

The `/research`, `/plan`, `/build`, and `/vqa` skills refuse to run on an un-promoted `CTX-*` ticket and will point the user at `/create-ticket promote` or `/create-backlog` first.

---

## Ticket Lifecycle

0. **Intake (optional)** — `/create-ticket ctx "..."` drops raw context into a CTX ticket without forcing structure. CTX tickets are triaged later via `/create-ticket promote {CTX-ID}` (single) or `/create-backlog` (batch), which converts each into a `bug` or `work-order` with the next sequential ID of that type.
1. **Create ticket** — `/create-ticket` creates the folder, `ticket.md`, stub `plan.md` (bug / work-order only), remote issue, and syncs to the board (status: **Context Backlog**)
2. **Research** *(optional, recommended for unfamiliar work)* — `/research` investigates the problem domain and writes findings to `research/`; moves ticket to **In Research**
3. **Plan** — `/plan` enters plan mode for interactive review, writes the approved plan to `plan.md` (including a `## Build Agents` section defining parallel phases), and moves ticket to **In Planning**
4. **Build** — `/build` reads the `## Build Agents` section, moves ticket to **In Build**, and spawns build agents in parallel phases; agents within a phase run simultaneously, phases run sequentially. Individual build skills (`/code-build`, `/doc-build`, `/script-build`, `/api-build`, `/figma-build`) can be used directly for single-domain tickets.
5. **Verify** — `/vqa` runs a QA pass; moves ticket to **In Review** → **Completed**

> Skip research for well-understood, mechanical tickets where requirements are unambiguous.

The six workflow phases are:

| Phase | Meaning |
|---|---|
| Context Backlog | Ticket created, not yet started |
| In Research | Discovery / investigation underway |
| In Planning | plan.md being drafted or refined |
| In Build | Build agents executing the plan |
| In Review | VQA pass in progress |
| Completed | Verified, done |

These phases are stored on each ticket:
- **GitHub backend** → as the Status single-select field on the Project board
- **Jira backend** → as a `phase:<name>` label on each Jira issue (e.g. `phase:in-build`), because Jira workflow transitions depend on project-level configuration we cannot assume. The Jira Status field is left at whatever default the project workflow provides.

---

## Ticket Tracker — GitHub

<!-- CONFIGURE: Fill this section only if Backend is `github`. If Backend is `jira`, replace this entire section with: "**N/A** — this project uses the Jira backend; see the Jira section below." -->

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
| In Review | `[CONFIGURE: option ID for In Review status]` |
| Completed | `[CONFIGURE: option ID for Completed status]` |

### Key Commands (GitHub)

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

## Ticket Tracker — Jira

<!-- CONFIGURE: Fill this section only if Backend is `jira`. If Backend is `github`, replace this entire section with: "**N/A** — this project uses the GitHub backend; see the GitHub section above." -->

All Jira operations go through the **Atlassian MCP server** available to Claude Code (official Atlassian Remote MCP). Agents discover exact tool names through the MCP descriptor / tool list — do NOT shell out or call the Jira REST API directly.

- **Cloud ID:** `[CONFIGURE: Atlassian cloud ID — obtained from getAccessibleAtlassianResources]`
- **Site URL:** `[CONFIGURE: https://your-site.atlassian.net]`
- **Project key:** `[CONFIGURE: e.g. PROJ]`
- **Project name:** `[CONFIGURE: human-readable Jira project name]`
- **Issue type — Bug:** `[CONFIGURE: Jira issue type name mapped to our "bug" ticket type, e.g. Bug]`
- **Issue type — Work Order:** `[CONFIGURE: Jira issue type name mapped to our "work-order" ticket type, e.g. Task or Story]`
- **Issue type — Context:** `[CONFIGURE: Jira issue type name mapped to our "context" ticket type, e.g. Task — used as a staging bucket that is later promoted]`

### Phase Labels (Jira)

Phases are tracked as **labels** on each Jira issue (not Status), so no workflow customization is required in the target Jira project. Exactly one `phase:*` label should be set at a time — when transitioning phases, remove the previous `phase:*` label and add the new one.

| Phase | Label |
|---|---|
| Context Backlog | `phase:context-backlog` |
| In Research | `phase:in-research` |
| In Planning | `phase:in-planning` |
| In Build | `phase:in-build` |
| In Review | `phase:in-review` |
| Completed | `phase:completed` |

In addition, every ticket created by this workflow gets a `claude-ops` label for easy JQL filtering, plus exactly one type label: `bug`, `work-order`, or `context`. When a context ticket is promoted via `/create-ticket promote` or `/create-backlog`, the `context` label is removed and replaced with `bug` or `work-order`, and the Jira `issuetype` field is updated accordingly.

### Key Operations (Jira)

Use the Atlassian MCP tools. Typical tool names on the official Atlassian Remote MCP:

| Operation | MCP tool (typical name — confirm via the MCP tool descriptors before calling) |
|---|---|
| List cloud IDs | `getAccessibleAtlassianResources` |
| List Jira projects on a cloud | `getVisibleJiraProjects` |
| Create a Jira issue | `createJiraIssue` |
| Read a Jira issue | `getJiraIssue` |
| Edit fields / labels on a Jira issue | `editJiraIssue` |
| Transition a Jira issue's Status (if desired) | `transitionJiraIssue` |
| Search issues (by label, JQL) | `searchJiraIssuesUsingJql` |

Phase-transition pattern (in pseudocode — replace with actual MCP tool call):

```
# Move ticket to a new phase
current = getJiraIssue(issueKey)
newLabels = [l for l in current.labels if not l.startswith("phase:")] + ["phase:in-build"]
editJiraIssue(issueKey, { labels: newLabels })
```

JQL to list all claude-ops tickets currently in build:

```
project = [CONFIGURE: PROJ] AND labels = "claude-ops" AND labels = "phase:in-build"
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

#### Atlassian (Jira / Confluence)
Used as the ticket backend when **Backend** above is set to `jira`. Also available on `github`-backed projects for reading or cross-posting to a Jira/Confluence workspace when a ticket references one.

Use when a ticket involves:
- Creating, reading, or updating Jira issues
- Transitioning Jira issue phase labels
- Reading or writing Confluence pages that the ticket references

<!-- ADD YOUR MCP SERVERS HERE
#### [Server Name] (`mcp__<server>__*`)
Brief description of what it connects to and what it can do.

Use when a work order involves:
- ...
-->

---

## Conventions

- `CLAUDE.md` at the repository root (from `/project-start`) must keep its **Agent rules** so Claude reads and updates `memory.md` without the user asking. **`memory.md`** holds short, project-wide facts; update it when something stable and reusable changes. Do not use either file to replace `ticket.md` or `plan.md` for a specific ticket
- Ticket IDs are sequential per type (`BUG-001`, `BUG-002`, `WO-001`, `WO-002`, `CTX-001`, `CTX-002`) and are always prefixed onto the remote issue title
- When a `CTX-###` ticket is promoted, the folder is renamed to the next `BUG-###` or `WO-###` in sequence, the ticket body is re-templated, and the remote issue is relabeled / retyped in place. The ticket.md frontmatter records `promoted_from: CTX-###` so history is preserved.
- Sprint folders are named `Sprint {N}` — do not use dates
- All `ticket.md` files include frontmatter fields for the remote issue:
  - **GitHub backend**: `github_issue` (issue number) and `project_item_id` (PVTI_…)
  - **Jira backend**: `jira_issue` (issue key, e.g. `PROJ-123`) and `jira_issue_id` (numeric id returned by the MCP)
- `plan.md` is always a stub when first created — fill it in before starting work
