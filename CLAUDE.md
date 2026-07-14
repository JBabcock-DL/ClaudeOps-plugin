# claude-ops (labs-agent-workflow)

This repository ships the **labs-agent-workflow** plugin for Claude Code. Consumer projects that run `/project-start` get their own `CLAUDE.md` and `memory.md` with the same **agent rules** below, customized with their project name and backend.

## Agent rules — no user prompt required

Claude and subagents must follow this without the user having to type “read memory” or “update memory”:

1. **At the start of work** in this repo (or in any project using this workflow), if `memory.md` exists in the **repository root**, read it **first**, then resolve and read **`workflow.md`** per **`skills/conventions/01-plugin-root-and-templates.md`** (consumer **`.github/templates/workflow.md`** wins when present; otherwise **`PLUGIN_ROOT/templates/workflow.md`**).
2. **After** completing `/project-start` configuration, a successful backend change, a new team convention, or any discovery worth carrying to the next session, **update `memory.md`** with short, durable bullets. Never paste full `plan.md` or ticket bodies here.
3. Use **tickets** (`.github/Sprint {N}/…/`) for per-unit work; use **`memory.md`** only for project-wide, repeating facts and preferences.

**Primary spec:** **`workflow.md`** — resolve path per **`skills/conventions/01-plugin-root-and-templates.md`**  
**Handoff / session bootstrap:** **`agent-handoff.md`** (same resolution rules) and **`memory.md`** (this repo), or copies under **`.github/templates/`** in consumer projects after **`/project-start`**.

For plugin **development** (editing `skills/`, `templates/`), also follow this file and keep `memory.md` aligned with real plugin behavior as it evolves.
