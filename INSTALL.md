# dl-agent-workflow — Installation Guide

## Prerequisites

Before installing, verify the following tools are available in your PATH:

- **`gh`** — GitHub CLI ([install guide](https://cli.github.com/manual/installation)); must be authenticated (`gh auth login`)
- **`git`** — Git SCM ([install guide](https://git-scm.com/downloads))
- **Claude Code** — Anthropic's CLI ([install guide](https://docs.anthropic.com/claude-code)); must be initialized in the target repo

---

## Install

### Unix / macOS (bash)

Run this from the root of the repo where you cloned `claude-ops`:

```bash
bash plugin/install.sh
```

To overwrite existing files in the target repo:

```bash
bash plugin/install.sh --force
```

### Windows (PowerShell)

Run from the root of the repo where you cloned `claude-ops`:

```powershell
.\plugin\install.ps1
```

To overwrite existing files in the target repo:

```powershell
.\plugin\install.ps1 -Force
```

---

## What the install scripts do

Both scripts perform the same steps:

1. Verify `gh`, `git`, and `claude` are on PATH
2. Copy `plugin/skills/` → `.claude/skills/` (10 skill folders)
3. Copy `plugin/templates/` → `.github/templates/` (4 template files)
4. Print a post-install checklist

Files are not overwritten unless `--force` / `-Force` is passed.

---

## Post-install configuration

After running the install script, configure `workflow.md` for your repo. Open `.github/templates/workflow.md` and replace every `[CONFIGURE: ...]` placeholder with the real value for your GitHub Project.

### Step 1 — Set your repo owner and project number

Find your project number:

```bash
gh project list --owner YOUR_USERNAME
```

Replace:
- `[CONFIGURE: your GitHub username or org ...]` → your GitHub username or org (e.g. `my-org`)
- `[CONFIGURE: project number ...]` → the integer project number (e.g. `1`)
- `[CONFIGURE: owner/repo]` → `your-org/your-repo`

### Step 2 — Get the Project node ID (Project ID)

```bash
gh project list --owner YOUR_USERNAME --format json | jq '.projects[] | select(.number==YOUR_PROJECT_NUMBER) | .id'
```

Replace `[CONFIGURE: GitHub Project node ID ...]` with the result (looks like `PVT_kwHOD9B30s4BTj7z`).

### Step 3 — Get the Status field ID

```bash
gh project field-list YOUR_PROJECT_NUMBER --owner YOUR_USERNAME --format json
```

Find the field named `Status` and copy its `id` value (looks like `PVTSSF_lAHOD9B30s4BTj7zzhAyGKQ`).

Replace `[CONFIGURE: the node ID of the Status field ...]` with that value.

### Step 4 — Get the status option IDs

```bash
gh project field-list YOUR_PROJECT_NUMBER --owner YOUR_USERNAME --format json \
  | jq '.fields[] | select(.name=="Status") | .options'
```

This returns a list of `{ id, name }` objects. Match each name to its ID and replace the six placeholders in the Status Options table:

| Placeholder | Status name |
|---|---|
| `[CONFIGURE: option ID for Context Backlog status]` | Context Backlog |
| `[CONFIGURE: option ID for In Research status]` | In Research |
| `[CONFIGURE: option ID for In Planning status]` | In Planning |
| `[CONFIGURE: option ID for In Build status]` | In Build |
| `[CONFIGURE: option ID for In Verification status]` | In Verification |
| `[CONFIGURE: option ID for Completed status]` | Completed |

### Step 5 — Set your project board name

Replace `[CONFIGURE: your GitHub Project board name]` with the display name of your board (e.g. `My Project`).

---

## Verify the install

After configuration, open a Claude Code session in your repo and run:

```
/create-ticket wo "Test ticket"
```

If the skill is recognized and a ticket folder is created under `.github/Sprint 1/`, the install is working.

To confirm all 10 skills are available, check that the following directories exist under `.claude/skills/`:

```
create-ticket  research  plan  build  code-build  doc-build  script-build  api-build  figma-build  vqa
```

> Note: Skills are namespaced as `dl-agent-workflow:skill-name` in Claude Code. You can invoke them directly (e.g. `/dl-agent-workflow:create-ticket`) or configure local aliases.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `gh: command not found` | Install the GitHub CLI and run `gh auth login` |
| `claude: command not found` | Install Claude Code and initialize it in the repo |
| Skills not recognized after install | Restart Claude Code; confirm `.claude/skills/` was populated |
| `workflow.md` still has `[CONFIGURE]` after editing | Save the file and reload; check for typos in replaced values |
