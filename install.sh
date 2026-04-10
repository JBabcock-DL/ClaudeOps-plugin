#!/usr/bin/env bash
# =============================================================================
# install.sh — DL Agent Workflow Plugin Installer (Unix/macOS)
# =============================================================================
#
# USAGE
#   From the root of your target repo, run:
#
#     bash path/to/ClaudeOps-plugin/install.sh [--force]
#
#   The script copies the plugin's skills and templates into the current
#   working directory (your target repo).
#
# OPTIONS
#   --force   Overwrite files that already exist at the destination.
#             Without this flag, existing files are skipped with a warning.
#
# WHAT IT INSTALLS
#   skills/*        →  .claude/skills/*
#   templates/*     →  .github/templates/*
#
# PREREQUISITES
#   - bash    (you are already running it)
#   - git     must be on PATH (target dir should be a git repo)
#   - gh      GitHub CLI must be on PATH (required for /create-ticket workflow)
#
# =============================================================================

set -e

# ---------------------------------------------------------------------------
# Resolve script location so the script can be run from any directory
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SKILLS_SRC="${SCRIPT_DIR}/skills"
PLUGIN_TEMPLATES_SRC="${SCRIPT_DIR}/templates"
TARGET_DIR="$(pwd)"
SKILLS_DEST="${TARGET_DIR}/.claude/skills"
TEMPLATES_DEST="${TARGET_DIR}/.github/templates"

FORCE=false

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
for arg in "$@"; do
  case "${arg}" in
    --force)
      FORCE=true
      ;;
    --help|-h)
      sed -n '2,/^# ====/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: ${arg}" >&2
      echo "Usage: bash install.sh [--force]" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Helper: print a coloured status line
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ---------------------------------------------------------------------------
# Step 1 — Validate prerequisites
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}DL Agent Workflow Plugin — Installer${RESET}"
echo "======================================"
echo ""
info "Checking prerequisites..."

MISSING=0

for cmd in git gh bash; do
  if command -v "${cmd}" > /dev/null 2>&1; then
    ok "${cmd} found at $(command -v "${cmd}")"
  else
    error "${cmd} is not on PATH. Please install it before running this script."
    MISSING=1
  fi
done

if [ "${MISSING}" -eq 1 ]; then
  echo ""
  error "One or more prerequisites are missing. Aborting."
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 2 — Validate source directories
# ---------------------------------------------------------------------------
echo ""
info "Validating plugin source directories..."

if [ ! -d "${PLUGIN_SKILLS_SRC}" ]; then
  error "Plugin skills directory not found: ${PLUGIN_SKILLS_SRC}"
  exit 1
fi

if [ ! -d "${PLUGIN_TEMPLATES_SRC}" ]; then
  error "Plugin templates directory not found: ${PLUGIN_TEMPLATES_SRC}"
  exit 1
fi

ok "Skills source:    ${PLUGIN_SKILLS_SRC}"
ok "Templates source: ${PLUGIN_TEMPLATES_SRC}"
ok "Install target:   ${TARGET_DIR}"

# ---------------------------------------------------------------------------
# Step 3 — Create destination directories if needed
# ---------------------------------------------------------------------------
echo ""
info "Preparing destination directories..."

mkdir -p "${SKILLS_DEST}"
mkdir -p "${TEMPLATES_DEST}"

ok "Directories ready."

# ---------------------------------------------------------------------------
# Helper: copy a single file with --force / skip logic
# ---------------------------------------------------------------------------
copy_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "${dest}")"

  if [ -f "${dest}" ]; then
    if [ "${FORCE}" = true ]; then
      cp "${src}" "${dest}"
      ok "Overwritten: ${dest}"
    else
      warn "Skipped (already exists): ${dest}  — rerun with --force to overwrite"
    fi
  else
    cp "${src}" "${dest}"
    ok "Installed:  ${dest}"
  fi
}

# ---------------------------------------------------------------------------
# Step 4 — Copy skills
# ---------------------------------------------------------------------------
echo ""
info "Installing skills into ${SKILLS_DEST} ..."

SKILLS_INSTALLED=0
SKILLS_SKIPPED=0

while IFS= read -r -d '' src_file; do
  # Compute the path relative to the skills source root
  rel="${src_file#${PLUGIN_SKILLS_SRC}/}"
  dest_file="${SKILLS_DEST}/${rel}"

  if [ -f "${dest_file}" ] && [ "${FORCE}" = false ]; then
    SKILLS_SKIPPED=$((SKILLS_SKIPPED + 1))
  else
    SKILLS_INSTALLED=$((SKILLS_INSTALLED + 1))
  fi

  copy_file "${src_file}" "${dest_file}"
done < <(find "${PLUGIN_SKILLS_SRC}" -type f -print0)

# ---------------------------------------------------------------------------
# Step 5 — Copy templates
# ---------------------------------------------------------------------------
echo ""
info "Installing templates into ${TEMPLATES_DEST} ..."

TEMPLATES_INSTALLED=0
TEMPLATES_SKIPPED=0

while IFS= read -r -d '' src_file; do
  rel="${src_file#${PLUGIN_TEMPLATES_SRC}/}"
  dest_file="${TEMPLATES_DEST}/${rel}"

  if [ -f "${dest_file}" ] && [ "${FORCE}" = false ]; then
    TEMPLATES_SKIPPED=$((TEMPLATES_SKIPPED + 1))
  else
    TEMPLATES_INSTALLED=$((TEMPLATES_INSTALLED + 1))
  fi

  copy_file "${src_file}" "${dest_file}"
done < <(find "${PLUGIN_TEMPLATES_SRC}" -type f -print0)

# ---------------------------------------------------------------------------
# Step 6 — Summary
# ---------------------------------------------------------------------------
echo ""
echo "--------------------------------------"
echo -e "${BOLD}Install Summary${RESET}"
echo "--------------------------------------"
info "Skills:    ${SKILLS_INSTALLED} installed, ${SKILLS_SKIPPED} skipped"
info "Templates: ${TEMPLATES_INSTALLED} installed, ${TEMPLATES_SKIPPED} skipped"
if [ "${SKILLS_SKIPPED}" -gt 0 ] || [ "${TEMPLATES_SKIPPED}" -gt 0 ]; then
  warn "Some files were skipped because they already exist."
  warn "Rerun with --force to overwrite all existing files."
fi
echo ""

# ---------------------------------------------------------------------------
# Post-install checklist
# ---------------------------------------------------------------------------
echo -e "${BOLD}Post-Install Checklist${RESET}"
echo "======================================"
echo ""
echo "  1. Open .github/templates/workflow.md in your editor."
echo "     Replace every [CONFIGURE: ...] placeholder with your real values:"
echo ""
echo "     a. GitHub Project node ID"
echo "        — Go to your GitHub Project → Settings → copy the project URL"
echo "        — Run: gh api graphql -f query='{ viewer { projectsV2(first:10) { nodes { id title } } } }'"
echo "        — Paste the node ID (starts with PVT_)"
echo ""
echo "     b. Status field node ID"
echo "        — Run: gh api graphql -f query='{ node(id: \"<PROJECT_ID>\") { ... on ProjectV2 { fields(first:20) { nodes { ... on ProjectV2SingleSelectField { id name } } } } } }'"
echo "        — Paste the field ID (starts with PVTSSF_)"
echo ""
echo "     c. Status option IDs (one per status: Todo, In Progress, In Review, etc.)"
echo "        — Same query as above; each option inside the field has its own ID"
echo ""
echo "     d. Repo owner / GitHub username"
echo "        — Replace [CONFIGURE: owner] with your GitHub username or org name"
echo ""
echo "     e. GitHub Project board name"
echo "        — Replace [CONFIGURE: your GitHub Project board name] with the display name"
echo ""
echo "  2. In Claude Code, run:"
echo "        /create-ticket wo \"Test ticket\""
echo "     to verify the workflow loads and the slash commands are recognized."
echo ""
echo "  3. Commit the newly installed files:"
echo "        git add .claude/skills .github/templates"
echo "        git commit -m \"chore: install dl-agent-workflow plugin\""
echo ""
echo -e "${GREEN}Installation complete.${RESET}"
echo ""
