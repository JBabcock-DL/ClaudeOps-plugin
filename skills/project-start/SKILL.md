---
name: project-start
description: Initialize a new project repo with the full claude-ops workflow structure — folder layout, templates, and either a GitHub Project board or a Jira project as the ticket backend. Use when starting a brand new project that should follow this workflow.
argument-hint: "[project-name]"
context: fork
agent: general-purpose
---

You are initializing a new project using the claude-ops workflow system.

Project name: $ARGUMENTS

## Collect missing context

If $ARGUMENTS is empty, ask the user using AskUserQuestion:

- **Project name** — "What is the name of this project?"

Then ask the user using AskUserQuestion:

- **Project goal** — "What is the goal of this project? This will be written into workflow.md as the source-of-truth description for all agents working in this repo."

Then ask the user using AskUserQuestion **before any backend work**:

- **Ticket backend** — "Which ticket backend should this project use?"
  1. **GitHub** — GitHub Issues + a GitHub Project board (requires `gh` CLI authenticated)
  2. **Jira** — Jira Cloud via the Atlassian MCP server in Claude Code (requires the Atlassian MCP to be installed and authenticated)

Do not proceed until all three values (name, goal, backend) are confirmed.

Record the chosen backend as the variable `BACKEND` with value `github` or `jira` for the rest of this skill. You will use it to branch steps 5 and 6 below.

If `memory.md` already exists in the current working directory (e.g. resuming a partial setup), read it first, then read:
.github/templates/workflow.md — to understand the full system you are replicating

Then scaffold the following in the current working directory:

1. Folder structure:
   - .github/templates/
   - .github/Sprint 1/
   - .claude/skills/new-agent/
   - .claude/skills/create-ticket/
   - .claude/skills/create-backlog/
   - .claude/skills/research/
   - .claude/skills/plan/
   - .claude/skills/build/
   - .claude/skills/code-build/
   - .claude/skills/doc-build/
   - .claude/skills/script-build/
   - .claude/skills/api-build/
   - .claude/skills/figma-build/
   - .claude/skills/project-start/
   - .claude/skills/vqa/

2. Copy all template files from .github/templates/ into the new project's .github/templates/ — the full set is `workflow.md`, `bug_report.md`, `work_order.md`, `context.md`, and `agent-handoff.md`. Confirm all five files land in the new repo.

2b. Copy `memory.md` from the claude-ops plugin **package root** (the directory that contains this skill's `skills/`, `templates/`, and `README.md` — the same place you are copying from, not from `.github/templates/`) into the **new repository root** as `memory.md`. The shipped plugin includes this file; always place it in new scaffolds so sessions can keep short project facts and save context and tokens.

3. Copy all skill SKILL.md files from .claude/skills/ into the new project's .claude/skills/

3a. Write `.claude/settings.json` in the new project root. The permissions list depends on the chosen backend:

   - If `BACKEND` is `github`, pre-authorize all `gh` CLI commands:
     ```json
     {
       "permissions": {
         "allow": [
           "Bash(gh *)"
         ]
       }
     }
     ```
   - If `BACKEND` is `jira`, write an empty-but-valid permissions file — all Jira work goes through MCP tool calls which follow Claude Code's MCP permission model, not `Bash`:
     ```json
     {
       "permissions": {
         "allow": []
       }
     }
     ```

4. Create a `CLAUDE.md` in the new repo root. The user must not need to remind Claude to read `memory.md`—bake the rules in here. Use this exact structure, substituting the project name and `BACKEND`:

   ```markdown
   # {PROJECT_NAME}

   **Ticket backend:** {BACKEND} (IDs, commands, and phase mapping live in `memory.md` Quick reference and `.github/templates/workflow.md`.)

   ## Agent rules (claude-ops) — do not require the user to ask

   1. If `memory.md` exists in this repository root, read it at the start of any ticket- or workflow-related work, then read `.github/templates/workflow.md` for the full spec.
   2. Update `memory.md` when you establish or change something durable: backend facts, default git strategy, team conventions, MCP/tool setup, or recurring mistakes to avoid. Keep entries short. Never replace per-ticket `plan.md` or `ticket.md` with `memory.md`.
   3. Workflow skills are in `.claude/skills/`. Use the slash commands from your README (e.g. `create-ticket`, `create-backlog`, `research`, `plan`, `build`, `vqa`).

   ## Where to look

   - `memory.md` — short cross-ticket running memory
   - `.github/templates/workflow.md` — structure, ticket lifecycle, GitHub or Jira keys, commands
   - `.github/templates/agent-handoff.md` — copy-paste prompt for new agent sessions
   ```

   Replace `{PROJECT_NAME}` with the project name from `$ARGUMENTS` and `{BACKEND}` with `github` or `jira` from the user's choice. Do not omit the **Agent rules** section.

4b. **Prime `memory.md`** in the new repo root: set **Quick reference** (project one-liner, `BACKEND`, default branch) and **This repo is:** to match the new project, so the first real session can read a filled `memory.md` without manual user instructions.

---

## 5. Backend-specific setup

Execute **only** the branch matching the chosen `BACKEND`.

### 5 · Option A — GitHub backend (`BACKEND == github`)

Using the `gh` CLI:

- Create label: bug (#d73a4a)
- Create label: work-order (#0075ca)
- Create label: context (#6f42c1)
- Create a new GitHub Project named "$ARGUMENTS" for the repo owner
- Determine the new project's **number** (integer) and **owner login** (user or org), e.g. `gh project list --owner <OWNER_LOGIN> --format json` and match on `title` / `number`

5a-A. **Set up custom status columns** on the new project board — the default GitHub Project board has generic options (Todo, In Progress, Done) that do NOT match our workflow. You must replace them with the correct statuses using the GitHub GraphQL API:

   - Run `gh project field-list <PROJECT_NUMBER> --owner <OWNER_LOGIN> --format json` to get the Status field's node ID (`PVTSSF_...`). The Status field has `"type": "ProjectV2SingleSelectField"`.
   - Call `gh api graphql` with the `updateProjectV2Field` mutation to replace all options with the 6 workflow statuses. Use this exact shape:

   ```
   gh api graphql -f query='
   mutation {
     updateProjectV2Field(input: {
       fieldId: "<STATUS_FIELD_ID>"
       singleSelectOptions: [
         { name: "Context Backlog", color: BLUE,   description: "" }
         { name: "In Research",     color: PURPLE, description: "" }
         { name: "In Planning",     color: YELLOW, description: "" }
         { name: "In Build",        color: ORANGE, description: "" }
         { name: "In Review", color: RED,    description: "" }
         { name: "Completed",       color: GREEN,  description: "" }
       ]
     }) {
       projectV2Field {
         ... on ProjectV2SingleSelectField {
           id
           options { id name }
         }
       }
     }
   }'
   ```

   - Parse the returned `options` array from the mutation response. For each option, record its `id` keyed by `name`. These are the IDs you will write into `workflow.md` — do not re-query; use the mutation response directly.

### 5 · Option B — Jira backend (`BACKEND == jira`)

All Jira work goes through the **Atlassian MCP server** in Claude Code. Before doing anything, browse the MCP tool descriptors for the `atlassian` server and confirm the exact tool names available. The typical tools are listed in `templates/workflow.md` under "Ticket Tracker — Jira". If the Atlassian MCP requires authentication, call its `mcp_auth` tool first and stop until authentication succeeds.

- Call `getAccessibleAtlassianResources` (or the equivalent) to list cloud IDs the user has access to. If more than one, AskUserQuestion: "Which Atlassian site should this project use?" — list each site's name + URL as options. Record the chosen `cloudId` and `siteUrl`.

- Call `getVisibleJiraProjects` (or the equivalent) for that cloud. AskUserQuestion: "Which Jira project should back this workflow?" — list each project's `name (KEY)` as an option. The official Atlassian Remote MCP does not expose project creation; the user must have pre-created the Jira project. If the list is empty, stop and tell the user to create a Jira project first, then rerun `/project-start`.

- Record the chosen `projectKey` (e.g. `PROJ`) and `projectName`.

- Determine the Jira **issue types** available in that project (e.g. via `getJiraProjectIssueTypes` or by reading the project metadata from `getVisibleJiraProjects`). AskUserQuestion once for each of our three ticket types, listing the available issue types as options:
  1. "Which Jira issue type should map to our **bug** ticket type?" — record as `bugIssueType` (default: `Bug` if present)
  2. "Which Jira issue type should map to our **work-order** ticket type?" — record as `workOrderIssueType` (default: `Task` if present, else `Story`)
  3. "Which Jira issue type should map to our **context** ticket type? (This is a staging bucket for raw notes that are later promoted.)" — record as `contextIssueType` (default: `Task` if present — it's fine to reuse the same type as work orders, since labels disambiguate)

- **Labels, not statuses.** Do not attempt to modify the Jira project's workflow or Status field — that requires Jira admin permissions and is project-specific. Workflow phases are tracked via labels on each issue:
  - `phase:context-backlog`, `phase:in-research`, `phase:in-planning`, `phase:in-build`, `phase:in-review`, `phase:completed`
  - Every ticket also gets a `claude-ops` label plus exactly one of `bug`, `work-order`, or `context`
  No pre-creation of labels is required — Jira creates labels on first use.

- **Do not create GitHub labels or a GitHub Project** on this branch. Skip step 5a-A entirely.

---

## 6. Populate workflow.md

**You** (the agent) must update `.github/templates/workflow.md` in place—this is not a separate script. Treat the following as your task prompt.

First, open `.github/templates/workflow.md` and replace the `[CONFIGURE: github | jira]` placeholder next to **Backend:** with the actual `BACKEND` value.

Replace the `[ADD YOUR GOAL HERE]` placeholder under **## Project Goal** with the project goal provided by the user.

Then execute **only** the sub-branch matching `BACKEND`.

### 6 · Option A — GitHub backend

- Run `gh repo view --json owner,nameWithOwner` from the **new repo root** and record `owner.login` and `nameWithOwner` for the **Key Commands** section.
- Run `gh project view <PROJECT_NUMBER> --owner <OWNER_LOGIN> --format json` and read `title`, `id` (Project node id), and `number`.
- Use the Status field ID and the 6 option IDs captured from the mutation in step 5a-A — do not run field-list again.
- Open `.github/templates/workflow.md` and **edit the file**: replace every `[CONFIGURE: ...]` placeholder under **## Ticket Tracker — GitHub** and inside its **Key Commands (GitHub)** `bash` block with the real values (project title, `PVT_…` project id, owner, status field id, each status option id, project number, full `owner/repo`). Use the exact string values returned by `gh`; do not invent IDs.
- Replace the entire **## Ticket Tracker — Jira** section body with:

  ```
  **N/A** — this project uses the GitHub backend; see the GitHub section above.
  ```

- Re-read the updated sections and confirm there are **no** remaining `[CONFIGURE:` tokens in **## Ticket Tracker — GitHub**, and no `[ADD YOUR GOAL HERE]` placeholder remaining, before you finish.

### 6 · Option B — Jira backend

- Open `.github/templates/workflow.md` and **edit the file**: replace every `[CONFIGURE: ...]` placeholder under **## Ticket Tracker — Jira** with the real values captured in step 5 · Option B:
  - `Cloud ID` → captured `cloudId`
  - `Site URL` → captured `siteUrl`
  - `Project key` → captured `projectKey`
  - `Project name` → captured `projectName`
  - `Issue type — Bug` → captured `bugIssueType`
  - `Issue type — Work Order` → captured `workOrderIssueType`
  - `Issue type — Context` → captured `contextIssueType`
  - The JQL example at the bottom of the section: replace `[CONFIGURE: PROJ]` with the captured `projectKey`.
- Replace the entire **## Ticket Tracker — GitHub** section body (everything from the first bullet through the end of the **Key Commands (GitHub)** code block) with:

  ```
  **N/A** — this project uses the Jira backend; see the Jira section below.
  ```

- Re-read the updated sections and confirm there are **no** remaining `[CONFIGURE:` tokens in **## Ticket Tracker — Jira**, no `[CONFIGURE: github | jira]` token next to **Backend:**, and no `[ADD YOUR GOAL HERE]` placeholder remaining, before you finish.

---

## 7. Create three starter tickets

Do this only after step 6 is complete and `workflow.md` has no unresolved `[CONFIGURE: ...]` tokens in the **active** tracker section.

Use the Skill tool exactly as follows — do not invent titles, do not create issues yourself, do not add anything to the board yourself. The `create-ticket` skill handles all of that and will branch on the backend value it reads from `workflow.md`.

First call — pass this argument string exactly:
```
wo "Configure project goal in workflow.md"
```

Wait for it to complete and confirm a ticket folder was created under `.github/Sprint 1/` before continuing.

Second call — pass this argument string exactly:
```
bug "Sample bug report"
```

Wait for it to complete and confirm a second ticket folder was created before continuing.

Third call — pass this argument string exactly:
```
ctx "Sample context capture"
```

Wait for it to complete. All three tickets must appear in `.github/Sprint 1/` with a `ticket.md` and a synced remote issue reference (either `github_issue` + `project_item_id` for GitHub, or `jira_issue` + `jira_issue_id` for Jira) before you proceed to step 8. The `bug` and `wo` tickets should also have a `plan.md`; the `ctx` ticket must NOT have a `plan.md` — context tickets are not planned until promoted.

---

## 8. Report back

- Folder structure created
- `CLAUDE.md` written with **Agent rules** (read/update `memory.md` without user prompting) and `memory.md` primed per step 4b
- Chosen backend (`github` or `jira`)
- **If GitHub:** labels created (`bug`, `work-order`, `context`), project board name, number, and node id, and the status field + option IDs written into workflow.md
- **If Jira:** cloud ID, site URL, Jira project key + name, and the bug / work-order / context issue-type mappings written into workflow.md
- Confirmation that `.github/templates/workflow.md` was edited and the **active** tracker section has no unresolved `[CONFIGURE: ...]` placeholders, and the inactive tracker section has been replaced with the **N/A** pointer
- Reminder: do not create tickets until that workflow file has no unresolved `[CONFIGURE: ...]` in the active section

### Manual step required — board view

- **GitHub backend:** GitHub's API does not expose a mutation for creating project views. After setup is complete, the user must add the Board view manually:
    1. Open the project on GitHub
    2. Click **+ New view** (tab row at the top)
    3. Select **Board**
    The 6 status columns will appear automatically since the Status field is already configured.
- **Jira backend:** If the user wants a kanban view grouped by workflow phase, have them create a board in Jira with swimlanes or columns grouped by **Label**, showing the six `phase:*` labels in order: `phase:context-backlog`, `phase:in-research`, `phase:in-planning`, `phase:in-build`, `phase:in-review`, `phase:completed`. A JQL filter of `project = <KEY> AND labels = "claude-ops"` scopes the board to this workflow's tickets.
