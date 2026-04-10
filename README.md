# dl-agent-workflow

A Claude Code plugin that provides a structured agent workflow for managing software work across GitHub Issues, a GitHub Project board, and Claude Code. Work is organized into sprint folders under `.github/`, each ticket gets a `ticket.md` and a `plan.md`, and a set of 10 skills covers the full lifecycle from ticket creation through research, planning, implementation (code, docs, scripts, APIs, Figma), and QA verification.

## Skills

| Skill | Description |
|---|---|
| `create-ticket` | Creates a new bug or work order ticket locally and syncs it to the GitHub Project board |
| `research` | Runs a research agent on a ticket to investigate domain knowledge before work begins |
| `plan` | Writes or refines `plan.md` for a ticket using Claude's native plan mode |
| `build` | Orchestrates the full build phase by spawning parallel build agents across all required domains |
| `code-build` | Executes code implementation work defined in `plan.md` |
| `doc-build` | Writes or updates documentation defined in `plan.md` |
| `script-build` | Writes automation or shell scripts defined in `plan.md` |
| `api-build` | Builds API integrations or Claude API-powered features defined in `plan.md` |
| `figma-build` | Executes Figma canvas work defined in `plan.md` |
| `project-start` | Scaffolds the full workflow system in a new repo (folder layout, templates, GitHub labels, project board) |
| `vqa` | Runs a visual and functional QA pass on a completed ticket |

## Setup

**Claude Code marketplace:** add [JBabcock-DL/ClaudeOps-plugin](https://github.com/JBabcock-DL/ClaudeOps-plugin), then run `/plugin install dl-agent-workflow@claudeops-plugin`. Details are in [INSTALL.md](./INSTALL.md).

See [INSTALL.md](./INSTALL.md) for prerequisites, manual install scripts, and post-install configuration steps.
