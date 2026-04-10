---
name: project-start
description: Initialize a new project repo with the full claude-ops workflow structure — folder layout, templates, GitHub labels, and project board. Use when starting a brand new project that should follow this workflow.
argument-hint: "[project-name]"
context: fork
agent: general-purpose
---

You are initializing a new project using the claude-ops workflow system.

Project name: $ARGUMENTS

Read this file first to understand the full system you are replicating:
.github/templates/workflow.md

Then scaffold the following in the current working directory:

1. Folder structure:
   - .github/templates/
   - .github/Sprint 1/
   - .claude/skills/create-ticket/
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

2. Copy all template files from .github/templates/ into the new project's .github/templates/

3. Copy all skill SKILL.md files from .claude/skills/ into the new project's .claude/skills/

4. Create a CLAUDE.md in the repo root with:
   - Project name
   - Pointer to .github/templates/workflow.md as the source of truth
   - Note that skills are available in .claude/skills/

5. GitHub setup (using gh CLI):
   - Create label: bug (#d73a4a)
   - Create label: work-order (#0075ca)
   - Create a new GitHub Project named "$ARGUMENTS" for the repo owner
   - Determine the new project's **number** (integer) and **owner login** (user or org), e.g. `gh project list --owner <OWNER_LOGIN> --format json` and match on `title` / `number`

6. **You** (the agent) must update `.github/templates/workflow.md` in place—this is not a separate script. Treat the following as your task prompt:

   - Run `gh repo view --json owner,nameWithOwner` from the **new repo root** and record `owner.login` and `nameWithOwner` for the **Key Commands** section.
   - Run `gh project view <PROJECT_NUMBER> --owner <OWNER_LOGIN> --format json` and read `title`, `id` (Project node id), and `number`.
   - Run `gh project field-list <PROJECT_NUMBER> --owner <OWNER_LOGIN> --format json`. Locate the **Status** field (`type` is `ProjectV2SingleSelectField`): capture its field `id`, and for each option whose `name` aligns with Context Backlog, In Research, In Planning, In Build, In Verification, and Completed, capture that option's `id`. If the board uses different labels, map sensibly or ask the user before writing.
   - Open `.github/templates/workflow.md` and **edit the file**: replace every `[CONFIGURE: ...]` placeholder under **## GitHub Project** and inside the **Key Commands** `bash` block with the real values from the JSON above (project title, `PVT_…` project id, owner, status field id, each status option id, project number, full `owner/repo`). Use the exact string values returned by `gh`; do not invent IDs.
   - Re-read the updated sections and confirm there are **no** remaining `[CONFIGURE:` tokens in **## GitHub Project** or that **Key Commands** block before you finish.

7. Report back:
   - Folder structure created
   - GitHub labels created
   - Project board name, number, and node id
   - Confirmation that `.github/templates/workflow.md` was edited and the GitHub Project / Key Commands placeholders are fully resolved
   - Reminder: do not create tickets until that workflow file has no unresolved `[CONFIGURE: ...]` in those sections
