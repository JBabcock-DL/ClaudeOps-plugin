# Project memory (claude-ops)

<!-- This file is part of the dl-agent workflow. See CLAUDE.md (repo root) for mandatory read/update rules. -->

## Instructions for agents (obligatory when this file exists)

You **must** do this without the user having to ask:

1. **Read this file** at the start of any session, subagent, or skill run that does ticket or repo work, **before** deep-diving a single ticket—unless the user is only doing an unrelated one-off. Then read `.github/templates/workflow.md` for the full spec.
2. **Update this file** when you learn something stable and reusable: backend IDs, Jira/phase quirks, team git preference, “always use” commands, or a mistake to avoid. Keep each bullet short; do not paste whole tickets or long plans here.
3. **Do not** move `plan.md` / `ticket.md` / `research/` content into here—`memory.md` is for **cross-ticket** facts only.

---

## Quick reference

- **Project goal (one line):** *or “see `workflow.md` → Project Goal”*
- **Ticket backend:** `github` | `jira` — *from `workflow.md` **## Ticket Backend** → Backend***
- **Default branch / PR target:** *e.g. `main`*
- **Current sprint folder:** *e.g. `.github/Sprint 1/` (update when a new sprint starts)*
- **Stack / runtimes (if this is an app repo):** *e.g. Node 22, pnpm, test runner*
- **This repo is:** *application codebase | `dl-agent-workflow` plugin / template only | monorepo — adjust behavior accordingly*

---

## Where everything lives (paths)

- **Global workflow + IDs:** `.github/templates/workflow.md` (GitHub Project / field IDs, `gh` snippets; or Jira cloud, project key, phase labels, MCP hints)
- **Handoff / new sessions:** `.github/templates/agent-handoff.md`
- **Per ticket:** `.github/Sprint {N}/{TICKET-ID}-{slug}/ticket.md` + `plan.md` + optional `research/`, `scripts/`
- **Skills (slash commands):** `.claude/skills/{skill}/SKILL.md` — *after `/project-start` these are the copies in this repo; developing the plugin may use a marketplace path instead*

---

## Ticket types & guards

| Type     | ID prefix  | `plan.md`   | `research` | Notes |
|----------|------------|-------------|------------|--------|
| Bug      | `BUG-###`  | yes (stub+) | common     | |
| Work order | `WO-###` | yes (stub+) | common     | |
| Context  | `CTX-###`  | **no** until promoted | often | **Intake only**—promote with `/create-ticket promote CTX-###` or `/create-backlog` before `/research`, `/plan`, `/build`, `/vqa` |

---

## Lifecycle & phases (order)

1. **Intake (optional):** `/create-ticket ctx` → raw notes  
2. **Triage (optional):** `/create-backlog` or `/create-ticket promote` → `bug` or `wo`  
3. **Create (if needed):** `/create-ticket` bug|wo  
4. **Research (optional):** `/research`  
5. **Plan:** `/plan` — `plan.md` must gain `## Build Agents` with parallel phases for `/build`  
6. **Build:** `/build` (or domain skills: `code-build`, `doc-build`, `script-build`, `api-build`, `figma-build`)  
7. **Verify:** `/vqa`  
8. **Onboarding / fresh session:** `/new-agent` (optional)

**Phases (conceptual order):** Context Backlog → In Research → In Planning → In Build → In Review → Completed  

- **GitHub:** single **Status** field on the Project (column IDs in `workflow.md`)  
- **Jira:** `phase:*` **labels** (not Status)—see `workflow.md` Jira table  

---

## Build & git (saves context on repeat runs)

- **`/build` orchestrator** reads `## Build Agents` in `plan.md` and spawns domain agents in **phased parallel** (all domains in a phase in parallel; phases sequential).
- **Git strategy** (asked at `/build` or per domain skill if run alone):
  - **`branch-per-agent`:** each domain uses `{TICKET-ID}/{code|docs|scripts|api|figma}` or combined tickets per agent section—follow the skill. Needs **separate worktrees** for safe parallel work.
  - **`main`:** work on current branch; **do not** auto-commit/PR; user reviews uncommitted files.
- Record a **default preference** for this team below if you use `/build` often:

  - **Default git strategy for this repo:** *branch-per-agent | main*  
  - **Worktrees:** *yes, default in Claude Code | no*  

---

## MCP & external tools (names only, no secrets)

- **GitHub:** `gh` CLI; Board mutations per `workflow.md` **Key Commands (GitHub)**
- **Jira / Confluence:** Atlassian MCP (tool names in server descriptor)
- **Figma (optional):** Figma MCP for canvas; map URL in `ticket.md` **References**
- **Other (project-specific):** *e.g. Datadog, Sentry, Linear*

---

## Conventions (this repo’s agreements)

- *Branch naming, commit style, i18n, “definition of done,” CODEOWNERS, etc.*

---

## Phrases, products, and acronyms

- *Glossary for agents new to the domain—one line each.*

---

## Do not repeat (dead ends, incidents, or decisions)

- *One line each—what went wrong and what we do instead.*

---

## Changelog (optional)

- *YYYY-MM-DD — what changed in memory or in workflow setup (not per-ticket work).*
