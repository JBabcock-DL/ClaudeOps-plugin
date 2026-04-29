---
name: create-ticket
description: Create a new bug, work order, or context ticket in the active ticket backend (GitHub or Jira) first, then write the local sprint folder and ticket.md — or promote an existing context ticket into a bug / work-order. Use when creating a new ticket, dropping raw context, or converting a CTX ticket into a concrete unit of work.
argument-hint: "[bug|wo|ctx|promote] [title-in-quotes | CTX-###]"
context: fork
agent: general-purpose
---

You are managing a ticket for the claude-ops project.

Arguments received: $ARGUMENTS

There are **two modes** for this skill. Determine which one by inspecting $ARGUMENTS:

- **Create mode** — `$0` is one of `bug`, `wo`, `ctx`. `$1` is the ticket title.
- **Promote mode** — `$0` is `promote`. `$1` is a CTX ticket ID (e.g. `CTX-001`) or a full ticket folder path.

If neither maps cleanly, ask the user using AskUserQuestion which mode they want:

- "What do you want to do?"
  1. **Create a new ticket** — bug, work order, or context
  2. **Promote a context ticket** — convert a CTX-### into a bug or work-order

---

## Path resolution (`create-ticket`)

**`REPO_ROOT`** — Root where **`.github/Sprint */`** ticket folders will be created (working directory / workspace root unless the user scoped another path).

Resolve **`workflow.md`**, **`bug_report.md`**, **`work_order.md`**, and **`context.md`** using **`skills/conventions/01-plugin-root-and-templates.md`** — shared by all **`labs-agent-workflow`** skills (**no machine-specific paths**).

---

Before doing anything else, read **`{REPO_ROOT}/memory.md`** if it exists.

Then resolve and read **`workflow.md`** using the convention in **`skills/conventions/01-plugin-root-and-templates.md`**:

- Prefer **`{REPO_ROOT}/.github/templates/workflow.md`** when it exists
- Otherwise fall back to the bundled plugin copy at **`{PLUGIN_ROOT}/templates/workflow.md`**

Missing repo-local `workflow.md` is fine — the bundled template is used — but an **unconfigured Backend** blocks **create mode** (see Mode A).

From the resolved **`workflow.md`**, read the **Backend:** field under **## Ticket Backend** and normalize it (strip surrounding backticks or quotes). Record the result as **`BACKEND`** when it is exactly **`github`** or **`jira`**.

If this run revealed a durable fact for **Quick reference** (e.g. confirmed backend quirks), update **`memory.md`** — per **`CLAUDE.md`** in **`REPO_ROOT`** if present, without the user having to ask.

---

## Mode A — Create

### Backend requirement (before prompts or files)

**Create mode** must sync to GitHub or Jira **before** any local sprint folder or **`ticket.md`** exists, so the repo never ends up with a lone `CTX-*` / `BUG-*` / `WO-*` tree while the backend is still unset.

If **`BACKEND`** is not exactly **`github`** or **`jira`** (including when the value is still **`[CONFIGURE: github | jira]`**), **stop immediately**. Do not run AskUserQuestion for type/title, do not resolve sprint folders, and do not write **`ticket.md`**. Tell the user:

- **`workflow.md`** is missing a real **Ticket Backend** (same rule as **`skills/conventions/01-plugin-root-and-templates.md`** and **`create-backlog`**).
- Run **`/project-start`** in **`{REPO_ROOT}`**, or create/edit **`{REPO_ROOT}/.github/templates/workflow.md`** from the bundled **`templates/workflow.md`** and set **Backend** plus the active **Ticket Tracker** section (GitHub or Jira) with real IDs.
- Re-run **`/create-ticket`** after that — the skill will create the **remote** issue first, then the local folder.

### Collect missing context (order matters)

Parse $ARGUMENTS for ticket type ($0) and title ($1). For any value not provided, ask the user using AskUserQuestion **in this order** — do not collect long-form or “extra detail for devs” before **Type** is known, because **Type** selects the template (`bug_report.md` vs `work_order.md` vs `context.md`) and drives where information belongs.

- **Type** — "What type of ticket is this?"
  1. `bug` — a defect to fix
  2. `wo` — a work order (feature / enhancement / deliverable)
  3. `ctx` — raw context from a designer / researcher / meeting, to triage later
- **Title** — "What is the ticket title?" (For `ctx` tickets, a loose summary is fine — this becomes the folder slug.)

Do not proceed until both values are confirmed.

### Optional: additional information for developers

**After** Type and Title are fixed, if the user has **not** already given a complete ticket body (e.g. via slash-command paste or upstream skill passing prose), ask **once** for any **additional** context for the people who will implement or triage the ticket. Fold the answer into the correct sections of the chosen template (e.g. **Notes for build agent**, **Additional Context**, **Raw Notes**, **Requirements** subsections) instead of front-loading a type-agnostic dump.

Upstream skills (e.g. `/dev-handoff` delegating here) must **choose ticket type before** prompting for this kind of add-on detail, so the scaffold matches the ticket shape.

### Read the template

Read the template that matches the ticket type (resolve basename per `skills/conventions/01-plugin-root-and-templates.md`):

- `bug` → `bug_report.md`
- `wo`  → `work_order.md`
- `ctx` → `context.md`

### Invocation

Use whichever shape your runtime exposes:

- **Slash-command:** `/create-ticket {ctx|wo|bug} "{title}"` — when prompted for the ticket body, paste the composed Markdown body. **`workflow.md`** already resolved above supplies **Backend** (GitHub vs Jira).
- **Skill-proxy:** **`Read`** this **`SKILL.md`** from **`PLUGIN_ROOT`** and execute **Execute the create flow** below inline.

### Execute the create flow

Do **not** create the sprint folder or write **`ticket.md`** until **after** the remote issue exists and you have captured its IDs (steps 1–3 prepare content; step 4 is remote; steps 5–7 write local files).

1. Determine the current sprint folder and the next sequential ticket ID for the chosen type by scanning `.github/Sprint */` for existing `BUG-*`, `WO-*`, or `CTX-*` folders. Each type has its own independent counter.
   - `bug` → `BUG-{N}`
   - `wo`  → `WO-{N}`
   - `ctx` → `CTX-{N}`
2. Generate the ticket slug from the title (lowercase, hyphenated, max 5 words).
3. **Compose the ticket body** (everything below the YAML frontmatter) as you would for **`ticket.md`** — but keep it **in memory only** until you write **`ticket.md`** in step 6:
   - For `bug` and `wo`: populate Requirements / Success Criteria / etc. as best you can from the title; leave sections the user should fill in marked with TODO checkboxes.
   - For `ctx`: use **`context.md`**. It includes a **design-handoff scaffold** (Goal, Design reference, Requirements, Acceptance criteria, …). When the intake is a **structured design→engineering handoff** (e.g. `/dev-handoff`, Figma MCP, explicit user choice), **populate that scaffold by default** from the design source — include Requirements and Acceptance criteria when they are grounded in the frame/spec; do not strip them. When the intake is **unstructured** (meetings, transcripts), keep Requirements / Acceptance criteria minimal or `TBD` and rely on Source / Raw Notes — **do not invent** scoped requirements the source material does not support. The user (or `/create-backlog`) completes or trims sections before promotion.
   - This body string (no frontmatter) is what you pass to **`gh issue create --body`** or to the Jira issue description.

4. **Sync to the remote backend first** — execute **only** the branch matching `BACKEND`. The label / issue-type for the new issue is determined by the ticket type:

| Ticket type | Label | Jira issue-type source in workflow.md |
|---|---|---|
| `bug` | `bug` | **Issue type — Bug** |
| `wo` | `work-order` | **Issue type — Work Order** |
| `ctx` | `context` | **Issue type — Context** |

#### Backend: GitHub

1. Create the GitHub issue using `gh` CLI with the correct label. The issue title must be prefixed with the ticket ID: `{TICKET-ID}: {title}` (e.g. `WO-001: Configure project goal in workflow.md`, `CTX-002: Designer dump for checkout flow`). Use the composed body from step 3 as `--body`.
2. Capture the issue number for frontmatter (`github_issue`).
3. Add the issue to the project board using the **project number** and **owner** from the **Ticket Tracker — GitHub** section of `workflow.md`; capture the returned project item ID (`PVTI_...`) for `project_item_id`.
4. Set the Status field to **Context Backlog** using the Project ID, status field ID, and Context Backlog option ID from `workflow.md` (same single-select mutation shown in the **Key Commands (GitHub)** block).

#### Backend: Jira

All Jira work goes through the **Atlassian MCP server**. Before calling any MCP tool, browse the MCP tool descriptors for the `atlassian` server and confirm the exact tool names available. If the Atlassian MCP requires authentication, call its `mcp_auth` tool first and stop until authentication succeeds.

1. From `workflow.md` **Ticket Tracker — Jira** section, read `cloudId`, `projectKey`, and the correct issue-type name for the ticket type (table above).
2. Create the Jira issue using the MCP's `createJiraIssue` tool (confirm the exact tool name against the MCP descriptor). The summary must be prefixed with the ticket ID: `{TICKET-ID}: {title}`.
   Include these labels on creation:
   - `claude-ops`
   - One of `bug`, `work-order`, or `context` (matching the type)
   - `phase:context-backlog`
   Use the composed body from step 3 as the issue description. Prefer plain text / wiki markup over ADF.
3. Capture the returned `key` (e.g. `PROJ-123`) and `id` from the MCP response for `jira_issue` and `jira_issue_id` frontmatter.
4. Do **not** transition the Jira Status field. Phase tracking is done entirely through the `phase:*` label set in step 2.

### Write local files (after remote IDs exist)

5. Create the folder: `.github/Sprint {N}/{TICKET-ID}-{slug}/`
6. Write **`ticket.md`** with YAML frontmatter filled from the remote response, then the composed body from step 3:
   - **GitHub:** `github_issue:`, `project_item_id:`, plus `type: {bug|work-order|context}`
   - **Jira:** `jira_issue:`, `jira_issue_id:`, plus `type: {bug|work-order|context}`
7. Write a stub **`plan.md`** **only for `bug` and `wo`**. For `ctx` tickets, do **not** create **`plan.md`** — planning is meaningless until the ticket is promoted.

If the remote sync in step 4 fails, **do not** create the sprint folder or **`ticket.md`** (fix the backend / credentials / network, then re-run **`/create-ticket`**).

### Report back (create mode)

- Ticket folder path
- Ticket type, ID, and title
- Backend used (`github` or `jira`)
- **If GitHub:** the GitHub issue URL and the project item ID
- **If Jira:** the Jira issue key, the full Jira URL (`<siteUrl>/browse/<KEY>`), and the labels applied
- If `ctx`: remind the user that this ticket is in intake and must be promoted via `/create-ticket promote {CTX-ID}` or `/create-backlog` before research / plan / build / vqa will run on it.

---

## Mode B — Promote (`/create-ticket promote CTX-###`)

This mode converts an existing **context** ticket into a `bug` or `work-order`, keeping the remote issue in place (relabel / retype) and preserving history via a `promoted_from` frontmatter field.

### Locate the source CTX ticket

Parse `$1`. It can be:
- A ticket ID like `CTX-001` — scan `.github/Sprint */` for the matching `CTX-001-*` folder.
- A full folder path like `.github/Sprint 1/CTX-001-designer-dump`.

If `$1` is empty or not found, AskUserQuestion: "Which context ticket should I promote?" and list every unpromoted `CTX-*` folder found under `.github/Sprint */` (skipping any whose ticket.md already has `promoted_to:` in frontmatter).

Read the located `.github/Sprint {N}/CTX-###-{slug}/ticket.md`. Note the current `github_issue` + `project_item_id` **or** `jira_issue` + `jira_issue_id` frontmatter.

### Ask for the target type

Even if the CTX ticket has a hint in **Proposed Ticket Type**, confirm with the user via AskUserQuestion:

- "Promote `CTX-### — {title}` to which type?"
  1. `bug`
  2. `wo`
  3. `cancel — leave it as context`

Also AskUserQuestion for a **clean title**:

- "What title should the promoted ticket have?" — default to the current CTX title with the `CTX-###:` prefix stripped.

### Execute the promote flow

1. Compute the next sequential ID for the chosen target type (scan `BUG-*` or `WO-*` folders across `.github/Sprint */`).
2. Generate a new slug from the (possibly refined) title.
3. Rename the folder: `.github/Sprint {N}/CTX-###-{old-slug}/` → `.github/Sprint {N}/{BUG|WO}-###-{new-slug}/`.
4. Replace the body of `ticket.md` with the correct template (`bug_report.md` or `work_order.md`) using **`skills/conventions/01-plugin-root-and-templates.md`**, **migrating the salient content** from the CTX body:
   - **Goal**, **Design reference**, **Requirements** (all subsections), **Acceptance criteria**, **Out of scope**, and **Notes for build agent** — when present (design-handoff `context.md`), map into **Requirements** / **Success Criteria** / **References** as appropriate for the target template; do not drop actionable bullets.
   - **Source** and **Raw Notes** → merged into **Additional Context** (bug) or the top of **Problem Story** / **Hypothesis** (work order), unless already folded into Requirements above.
   - **Observed Problems / Opportunities** → seed entries for **Requirements**.
   - **Assets & Links** → **References**.
   - **Related Tickets** → **References**.
   - Preserve the original CTX body verbatim at the bottom under a collapsible `<details><summary>Original context capture (CTX-###)</summary>…</details>` block so nothing is lost.
5. Update frontmatter on the new ticket.md:
   - Change `type:` to `bug` or `work-order`.
   - Keep the existing remote IDs (`github_issue` / `project_item_id`, or `jira_issue` / `jira_issue_id`) — the remote issue is not re-created.
   - Add `promoted_from: CTX-###`.
6. Keep the old CTX **number reserved** — do not reuse `CTX-###` later. (Since we renamed the folder, no CTX-### folder will exist anymore; leave a tombstone in `.github/Sprint {N}/CTX-###-PROMOTED.md` containing a single line: `Promoted to {BUG|WO}-### on {YYYY-MM-DD}. See ./{new-folder}/ticket.md.`)
7. Update the remote issue to reflect the new type and ID — **only if** **`BACKEND`** is **`github`** or **`jira`** (from **`workflow.md`**) **and** the ticket’s remote ID fields are not **`TBD`**. Otherwise **skip** the GitHub/Jira subsections below and report that the local promote finished without a remote update (configure **`workflow.md`** and real remote IDs before expecting the tracker to match).

#### Backend: GitHub

- Rename the issue title using `gh issue edit {github_issue} --title "{NEW-ID}: {title}"`.
- Remove the `context` label and add `bug` or `work-order`:
  `gh issue edit {github_issue} --remove-label context --add-label {bug|work-order}`
- Replace the issue body with the new ticket.md body via `gh issue edit {github_issue} --body "..."`.
- Leave the project board Status on **Context Backlog** — the promoted ticket is now ready for the normal lifecycle starting at `/research` or `/plan`.

#### Backend: Jira

Use the Atlassian MCP.

- Update the issue summary to `{NEW-ID}: {title}` via `editJiraIssue`.
- Update labels: remove `context`, add `bug` or `work-order` (keep `claude-ops` and `phase:context-backlog`).
- Update the `issuetype` field on the Jira issue to the mapped issue-type name from `workflow.md` for the new ticket type (e.g. the value of **Issue type — Bug**). If the target issue type is in a different **issue type scheme** and `editJiraIssue` refuses the update, fall back gracefully: leave the Jira issue type as-is, keep the `bug` / `work-order` label as the authoritative type signal, and report this as a note in the final output.
- Replace the description with the new ticket.md body.

### Report back (promote mode)

- Source: `CTX-### — {old title}`
- Target: `{BUG|WO}-### — {new title}`
- New folder path
- Backend used
- **If GitHub:** issue URL (unchanged), confirmation that labels and title were updated
- **If Jira:** issue key (unchanged), confirmation that labels, summary, and (if successful) issue type were updated; any fallback notes
- Recommended next step: `/research` (for unfamiliar problems) or `/plan` (if scope is clear)
