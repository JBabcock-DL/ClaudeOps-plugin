# dl-agent-workflow

A Claude Code plugin that provides a structured agent workflow for managing software work across GitHub Issues, a GitHub Project board, and Claude Code. Work is organized into sprint folders under `.github/`, each ticket gets a `ticket.md` and a `plan.md`, and a set of 11 skills covers the full lifecycle from ticket creation through research, planning, implementation (code, docs, scripts, APIs, Figma), and QA verification.

---

## Prerequisites

Before installing, make sure you have:

- **Claude Code** desktop app or CLI (latest version)
- **Git** and a GitHub repo for your project
- **GitHub CLI** (`gh`) installed and authenticated: `gh auth login`

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

Once the plugin is installed, open Claude Code in the root of your new GitHub repo and run:

```
/project-start "Your Project Name"
```

The agent will:

1. Scaffold the `.github/` folder structure and sprint layout
2. Copy all workflow templates and skill files into the repo
3. Create a `CLAUDE.md` at the repo root
4. Create GitHub labels (`bug`, `work-order`) via `gh`
5. Create a GitHub Project board named after your project
6. Configure the board's Status field with the 6 workflow columns (Context Backlog → In Research → In Planning → In Build → In Verification → Completed)
7. Write all project IDs (board ID, field ID, status option IDs) into `.github/templates/workflow.md`

When it finishes, your repo is fully wired — tickets you create will sync to the board automatically.

---

## Skills

| Skill | Invoke | Description |
|---|---|---|
| `project-start` | `/project-start "Name"` | Scaffolds the workflow system in a new repo |
| `new-agent` | `/new-agent` | Spins up a new agent session — collects sprint/ticket/role context, orients via the handoff doc, then invokes the right skill to start work |
| `create-ticket` | `/create-ticket wo "Title"` or `/create-ticket bug "Title"` | Creates a ticket locally and syncs it to the GitHub Project board |
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
create-ticket → research (optional) → plan → build → vqa
```

Each ticket lives in `.github/Sprint {N}/{TICKET-ID}-{slug}/` with a `ticket.md`, `plan.md`, and optional `research/` and `scripts/` folders. All tickets are linked to a GitHub Issue and tracked on the Project board.

See `.github/templates/workflow.md` (written into your repo by `/project-start`) for the full agent context document, including board IDs, status column IDs, and key `gh` commands.
