# dl-agent-workflow

A Claude Code plugin that provides a structured agent workflow for managing software work in Claude Code. Tickets sync to your choice of backend — **GitHub Issues + a GitHub Project board**, or **Jira Cloud via the Atlassian MCP**. Work is organized into sprint folders under `.github/`, each ticket gets a `ticket.md` and a `plan.md`, and a set of 12 skills covers the full lifecycle from raw context intake through ticket creation, research, planning, implementation (code, docs, scripts, APIs, Figma), and QA verification.

Tickets come in three flavors:

- **`bug`** — a defect to fix
- **`work-order`** — a feature / enhancement / deliverable
- **`context`** — a bulk dump of raw information (designer notes, research transcripts, meeting dumps, Figma comments) that gets triaged into a `bug` or `work-order` later via `/create-ticket promote` or `/create-backlog`

---

## Prerequisites

Before installing, make sure you have:

- **Claude Code** desktop app or CLI (latest version)
- **Git** and a repo for your project

Then, depending on which ticket backend you plan to use:

### If you'll use the **GitHub** backend
- A GitHub repo for your project
- **GitHub CLI** (`gh`) installed and authenticated: `gh auth login`

### If you'll use the **Jira** backend
- A Jira Cloud site you have access to
- An existing Jira project (the plugin does not create Jira projects — create it in Jira first)
- The **Atlassian MCP server** installed and authenticated in Claude Code (Settings → Extensions → MCP Servers → Atlassian). The plugin uses the official Atlassian Remote MCP to create, read, and label Jira issues.

---

## Install the Plugin

### From Claude Code Desktop

1. Open Claude Code and go to **Settings → Extensions**
2. Click **Add Plugin** and enter the GitHub repo:
   ```
   JBabcock-DL/ClaudeOps-plugin
   ```
3. Click **Install** — Claude Code will pull the plugin and register all 11 skills

### From the Command Line

```bash
claude plugin install JBabcock-DL/ClaudeOps-plugin
```

The skills are immediately available as `/dl-agent-workflow:<skill-name>` in any Claude Code session (e.g. `/dl-agent-workflow:create-ticket`).

---

## Start a New Project

Once the plugin is installed, open Claude Code in the root of your new repo and run:

```
/project-start "Your Project Name"
```

You'll be asked, via `AskUserQuestion`, to pick a **ticket backend**:

1. **GitHub** — GitHub Issues + a GitHub Project board
2. **Jira** — Jira Cloud via the Atlassian MCP

Then the agent will:

1. Scaffold the `.github/` folder structure and sprint layout
2. Copy all workflow templates and skill files into the repo
3. Create a `CLAUDE.md` at the repo root

Then, depending on the backend you chose:

### GitHub branch
4. Create GitHub labels (`bug`, `work-order`) via `gh`
5. Create a GitHub Project board named after your project
6. Configure the board's Status field with the 6 workflow columns (Context Backlog → In Research → In Planning → In Build → In Review → Completed)
7. Write all project IDs (board ID, field ID, status option IDs) into `.github/templates/workflow.md`

### Jira branch
4. List your accessible Atlassian sites and ask which to use
5. List visible Jira projects and ask which should back this workflow (the project must already exist)
6. Ask which Jira issue types map to our `bug` and `work-order` ticket types
7. Write the cloud ID, site URL, project key, project name, and issue-type mappings into `.github/templates/workflow.md`

Workflow phases (Context Backlog → In Research → In Planning → In Build → In Review → Completed) are tracked as `phase:*` labels on each Jira issue — no Jira workflow / admin changes required.

When it finishes, your repo is fully wired — tickets you create will sync to the chosen backend automatically.

---

## Skills

| Skill | Invoke | Description |
|---|---|---|
| `project-start` | `/project-start "Name"` | Scaffolds the workflow system in a new repo and wires it up to a GitHub Project board or a Jira project |
| `new-agent` | `/new-agent` | Spins up a new agent session — collects sprint/ticket/role context, orients via the handoff doc, then invokes the right skill to start work |
| `create-ticket` | `/create-ticket wo "Title"`, `/create-ticket bug "Title"`, or `/create-ticket ctx "Title"` — also `/create-ticket promote CTX-###` | Creates a ticket (bug / work order / context) locally and syncs it to the active backend. `promote` converts a context ticket into a bug or work-order in place. |
| `create-backlog` | `/create-backlog [sprint-number]` | Walks every unpromoted context ticket in a sprint, classifies each into a bug or work-order with the user's confirmation, and delegates to `create-ticket promote` to perform the mutation |
| `research` | `/research` | Investigates a ticket's problem domain and writes findings to `research/` |
| `plan` | `/plan` | Writes or refines `plan.md` using Claude's native plan mode |
| `build` | `/build` | Spawns parallel build agents across all domains defined in `plan.md` |
| `code-build` | `/code-build` | Executes code implementation work |
| `doc-build` | `/doc-build` | Writes or updates documentation |
| `script-build` | `/script-build` | Writes automation or shell scripts |
| `api-build` | `/api-build` | Builds API integrations or Claude API-powered features |
| `figma-build` | `/figma-build` | Executes Figma canvas work |
| `vqa` | `/vqa` | Runs a visual and functional QA pass on a completed ticket |

---

## Workflow Overview

```
                ┌──────────────────────────────┐
                │  (optional) bulk context in  │
                │        /create-ticket ctx    │
                │               ↓              │
                │   /create-backlog triages    │
                │   CTX-* → BUG-### or WO-###  │
                └──────────────────────────────┘
                              ↓
create-ticket (bug | wo) → research (optional) → plan → build → vqa
```

Each ticket lives in `.github/Sprint {N}/{TICKET-ID}-{slug}/` with a `ticket.md`, `plan.md`, and optional `research/` and `scripts/` folders. All tickets are linked to a remote issue — a GitHub Issue tracked on the Project board, or a Jira issue labeled with a `phase:*` label and `claude-ops`.

See `.github/templates/workflow.md` (written into your repo by `/project-start`) for the full agent context document, including the chosen backend, board / project IDs, status (or label) configuration, and key commands / MCP tools.
