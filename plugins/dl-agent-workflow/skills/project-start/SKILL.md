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
   - .claude/skills/figma-build/
   - .claude/skills/research/
   - .claude/skills/vqa/
   - .claude/skills/project-start/

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
   - Note the project ID and update workflow.md with the correct values

6. Report back:
   - Folder structure created
   - GitHub labels created
   - Project board name and ID
   - Reminder to update workflow.md with the new project's GitHub Project IDs before creating tickets
