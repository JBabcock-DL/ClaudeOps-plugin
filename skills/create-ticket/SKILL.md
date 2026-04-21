---
name: create-ticket
description: Create a new bug, work order, or context ticket locally and sync it to the active ticket backend — or promote an existing context ticket into a bug / work-order. Use when creating a new ticket, dropping raw context, or converting a CTX ticket into a concrete unit of work.
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

Before doing anything, read `.github/templates/workflow.md`. From it, read the **Backend:** field under **## Ticket Backend**. Record it as `BACKEND` with value `github` or `jira`. If the **Backend:** placeholder is still unresolved (`[CONFIGURE: github | jira]`), stop and tell the user to finish `/project-start` first.

---

## Mode A — Create

Read the template that matches the ticket type:
- `bug` → `.github/templates/bug_report.md`
- `wo`  → `.github/templates/work_order.md`
- `ctx` → `.github/templates/context.md`

### Collect missing context

Parse $ARGUMENTS for ticket type ($0) and title ($1). For any value not provided, ask the user using AskUserQuestion before proceeding:

- **Type** — "What type of ticket is this?"
  1. `bug` — a defect to fix
  2. `wo` — a work order (feature / enhancement / deliverable)
  3. `ctx` — raw context from a designer / researcher / meeting, to triage later
- **Title** — "What is the ticket title?" (For `ctx` tickets, a loose summary is fine — this becomes the folder slug.)

Do not proceed until both values are confirmed.

### Execute the create flow

1. Determine the current sprint folder and the next sequential ticket ID for the chosen type by scanning `.github/Sprint */` for existing `BUG-*`, `WO-*`, or `CTX-*` folders. Each type has its own independent counter.
   - `bug` → `BUG-{N}`
   - `wo`  → `WO-{N}`
   - `ctx` → `CTX-{N}`
2. Generate the ticket slug from the title (lowercase, hyphenated, max 5 words).
3. Create the folder: `.github/Sprint {N}/{TICKET-ID}-{slug}/`
4. Write `ticket.md` using the correct template.
   - For `bug` and `wo`: populate Requirements / Success Criteria / etc. as best you can from the title; leave sections the user should fill in marked with TODO checkboxes.
   - For `ctx`: keep the dump-friendly structure; do NOT invent Requirements / Success Criteria. The user (or `/create-backlog`) will fill in Raw Notes, Source, and Assets & Links.
   - Frontmatter by backend:
     - **GitHub:** `github_issue: TBD`, `project_item_id: TBD`, plus `type: {bug|work-order|context}`
     - **Jira:** `jira_issue: TBD`, `jira_issue_id: TBD`, plus `type: {bug|work-order|context}`
5. Write a stub `plan.md` **only for `bug` and `wo`**. For `ctx` tickets, do NOT create `plan.md` — planning is meaningless until the ticket is promoted.

### Sync to the remote backend

Execute **only** the branch matching `BACKEND`. The label / issue-type for the new issue is determined by the ticket type:

| Ticket type | Label | Jira issue-type source in workflow.md |
|---|---|---|
| `bug` | `bug` | **Issue type — Bug** |
| `wo` | `work-order` | **Issue type — Work Order** |
| `ctx` | `context` | **Issue type — Context** |

#### Backend: GitHub

1. Create the GitHub issue using `gh` CLI with the correct label. The issue title must be prefixed with the ticket ID: `{TICKET-ID}: {title}` (e.g. `WO-001: Configure project goal in workflow.md`, `CTX-002: Designer dump for checkout flow`).
2. Capture the issue number and update the `github_issue` field in `ticket.md`.
3. Add the issue to the project board using the **project number** and **owner** from the **Ticket Tracker — GitHub** section of `workflow.md`; capture the returned project item ID (`PVTI_...`).
4. Update the `project_item_id` field in `ticket.md` with the captured project item ID.
5. Set the Status field to **Context Backlog** using the Project ID, status field ID, and Context Backlog option ID from `workflow.md` (same single-select mutation shown in the **Key Commands (GitHub)** block).

#### Backend: Jira

All Jira work goes through the **Atlassian MCP server**. Before calling any MCP tool, browse the MCP tool descriptors for the `atlassian` server and confirm the exact tool names available. If the Atlassian MCP requires authentication, call its `mcp_auth` tool first and stop until authentication succeeds.

1. From `workflow.md` **Ticket Tracker — Jira** section, read `cloudId`, `projectKey`, and the correct issue-type name for the ticket type (table above).
2. Create the Jira issue using the MCP's `createJiraIssue` tool (confirm the exact tool name against the MCP descriptor). The summary must be prefixed with the ticket ID: `{TICKET-ID}: {title}`.
   Include these labels on creation:
   - `claude-ops`
   - One of `bug`, `work-order`, or `context` (matching the type)
   - `phase:context-backlog`
   Use the rendered ticket.md body (without frontmatter) as the issue description. Prefer plain text / wiki markup over ADF.
3. Capture the returned `key` (e.g. `PROJ-123`) and `id` from the MCP response. Update the `jira_issue` and `jira_issue_id` frontmatter fields in `ticket.md` accordingly.
4. Do **not** transition the Jira Status field. Phase tracking is done entirely through the `phase:*` label set in step 2.

### Report back (create mode)

- Ticket folder path
- Ticket type, ID, and title
- Backend used
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
4. Replace the body of `ticket.md` with the correct template (`bug_report.md` or `work_order.md`), **migrating the salient content** from the CTX body:
   - **Source** and **Raw Notes** → merged into **Additional Context** (bug) or the top of **Problem Story** / **Hypothesis** (work order).
   - **Observed Problems / Opportunities** → seed entries for **Requirements**.
   - **Assets & Links** → **References**.
   - **Related Tickets** → **References**.
   - Preserve the original CTX body verbatim at the bottom under a collapsible `<details><summary>Original context capture (CTX-###)</summary>…</details>` block so nothing is lost.
5. Update frontmatter on the new ticket.md:
   - Change `type:` to `bug` or `work-order`.
   - Keep the existing remote IDs (`github_issue` / `project_item_id`, or `jira_issue` / `jira_issue_id`) — the remote issue is not re-created.
   - Add `promoted_from: CTX-###`.
6. Keep the old CTX **number reserved** — do not reuse `CTX-###` later. (Since we renamed the folder, no CTX-### folder will exist anymore; leave a tombstone in `.github/Sprint {N}/CTX-###-PROMOTED.md` containing a single line: `Promoted to {BUG|WO}-### on {YYYY-MM-DD}. See ./{new-folder}/ticket.md.`)
7. Update the remote issue to reflect the new type and ID.

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
