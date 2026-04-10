<#
.SYNOPSIS
    DL Agent Workflow Plugin Installer (Windows / PowerShell)

.DESCRIPTION
    Copies the plugin's skills and templates into the current working directory
    (your target repo).

    Skills are installed to:    .claude\skills\
    Templates are installed to: .github\templates\

    Without -Force, files that already exist at the destination are skipped
    with a warning.  Use -Force to overwrite them.

.PARAMETER Force
    Overwrite files that already exist at the destination.

.EXAMPLE
    # From your target repo root:
    powershell -ExecutionPolicy Bypass -File path\to\ClaudeOps-plugin\install.ps1

    # Overwrite any existing files:
    powershell -ExecutionPolicy Bypass -File path\to\ClaudeOps-plugin\install.ps1 -Force

.NOTES
    Prerequisites:
      - git   must be on PATH (target directory should be a git repo)
      - gh    GitHub CLI must be on PATH (required for /create-ticket workflow)
#>

[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
$ScriptDir          = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PluginBundle       = Join-Path $ScriptDir 'plugins\dl-agent-workflow'
$PluginSkillsSrc    = Join-Path $PluginBundle 'skills'
$PluginTemplatesSrc = Join-Path $PluginBundle 'templates'
$TargetDir          = (Get-Location).Path
$SkillsDest         = Join-Path $TargetDir '.claude\skills'
$TemplatesDest      = Join-Path $TargetDir '.github\templates'

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------
function Write-Info  { param([string]$Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "DL Agent Workflow Plugin -- Installer" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "======================================"
Write-Host ""

# ---------------------------------------------------------------------------
# Step 1 -- Validate prerequisites
# ---------------------------------------------------------------------------
Write-Info "Checking prerequisites..."

$Missing = $false

foreach ($Cmd in @('git', 'gh')) {
    $Found = Get-Command $Cmd -ErrorAction SilentlyContinue
    if ($Found) {
        Write-Ok "$Cmd found at $($Found.Source)"
    } else {
        Write-Err "$Cmd is not on PATH. Please install it before running this script."
        $Missing = $true
    }
}

if ($Missing) {
    Write-Host ""
    Write-Err "One or more prerequisites are missing. Aborting."
    exit 1
}

# ---------------------------------------------------------------------------
# Step 2 -- Validate source directories
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "Validating plugin source directories..."

if (-not (Test-Path $PluginSkillsSrc -PathType Container)) {
    Write-Err "Plugin skills directory not found: $PluginSkillsSrc"
    exit 1
}

if (-not (Test-Path $PluginTemplatesSrc -PathType Container)) {
    Write-Err "Plugin templates directory not found: $PluginTemplatesSrc"
    exit 1
}

Write-Ok "Skills source:    $PluginSkillsSrc"
Write-Ok "Templates source: $PluginTemplatesSrc"
Write-Ok "Install target:   $TargetDir"

# ---------------------------------------------------------------------------
# Step 3 -- Create destination directories
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "Preparing destination directories..."

New-Item -ItemType Directory -Path $SkillsDest    -Force | Out-Null
New-Item -ItemType Directory -Path $TemplatesDest -Force | Out-Null

Write-Ok "Directories ready."

# ---------------------------------------------------------------------------
# Helper: copy a single file with -Force / skip logic
# ---------------------------------------------------------------------------
function Copy-PluginFile {
    param(
        [string]$Src,
        [string]$Dest,
        [bool]$Overwrite
    )

    $DestDir = Split-Path -Parent $Dest
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }

    if (Test-Path $Dest -PathType Leaf) {
        if ($Overwrite) {
            Copy-Item -Path $Src -Destination $Dest -Force
            Write-Ok "Overwritten: $Dest"
            return 'installed'
        } else {
            Write-Warn "Skipped (already exists): $Dest  -- rerun with -Force to overwrite"
            return 'skipped'
        }
    } else {
        Copy-Item -Path $Src -Destination $Dest -Force
        Write-Ok "Installed:  $Dest"
        return 'installed'
    }
}

# ---------------------------------------------------------------------------
# Step 4 -- Copy skills
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "Installing skills into $SkillsDest ..."

$SkillsInstalled = 0
$SkillsSkipped   = 0

Get-ChildItem -Path $PluginSkillsSrc -Recurse -File | ForEach-Object {
    $RelPath  = $_.FullName.Substring($PluginSkillsSrc.Length).TrimStart('\', '/')
    $DestFile = Join-Path $SkillsDest $RelPath

    $Result = Copy-PluginFile -Src $_.FullName -Dest $DestFile -Overwrite $Force.IsPresent
    if ($Result -eq 'installed') { $SkillsInstalled++ } else { $SkillsSkipped++ }
}

# ---------------------------------------------------------------------------
# Step 5 -- Copy templates
# ---------------------------------------------------------------------------
Write-Host ""
Write-Info "Installing templates into $TemplatesDest ..."

$TemplatesInstalled = 0
$TemplatesSkipped   = 0

Get-ChildItem -Path $PluginTemplatesSrc -Recurse -File | ForEach-Object {
    $RelPath  = $_.FullName.Substring($PluginTemplatesSrc.Length).TrimStart('\', '/')
    $DestFile = Join-Path $TemplatesDest $RelPath

    $Result = Copy-PluginFile -Src $_.FullName -Dest $DestFile -Overwrite $Force.IsPresent
    if ($Result -eq 'installed') { $TemplatesInstalled++ } else { $TemplatesSkipped++ }
}

# ---------------------------------------------------------------------------
# Step 6 -- Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--------------------------------------"
Write-Host "Install Summary" -ForegroundColor White
Write-Host "--------------------------------------"
Write-Info "Skills:    $SkillsInstalled installed, $SkillsSkipped skipped"
Write-Info "Templates: $TemplatesInstalled installed, $TemplatesSkipped skipped"
if ($SkillsSkipped -gt 0 -or $TemplatesSkipped -gt 0) {
    Write-Warn "Some files were skipped because they already exist."
    Write-Warn "Rerun with -Force to overwrite all existing files."
}
Write-Host ""

# ---------------------------------------------------------------------------
# Post-install checklist
# ---------------------------------------------------------------------------
Write-Host "Post-Install Checklist" -ForegroundColor White
Write-Host "======================================"
Write-Host ""
Write-Host "  1. Open .github\templates\workflow.md in your editor."
Write-Host "     Replace every [CONFIGURE: ...] placeholder with your real values:"
Write-Host ""
Write-Host "     a. GitHub Project node ID"
Write-Host "        -- Go to your GitHub Project -> Settings -> copy the project URL"
Write-Host "        -- Run: gh api graphql -f query='{ viewer { projectsV2(first:10) { nodes { id title } } } }'"
Write-Host "        -- Paste the node ID (starts with PVT_)"
Write-Host ""
Write-Host "     b. Status field node ID"
Write-Host "        -- Run: gh api graphql -f query='{ node(id: ""<PROJECT_ID>"") { ... on ProjectV2 { fields(first:20) { nodes { ... on ProjectV2SingleSelectField { id name } } } } } }'"
Write-Host "        -- Paste the field ID (starts with PVTSSF_)"
Write-Host ""
Write-Host "     c. Status option IDs (one per status: Todo, In Progress, In Review, etc.)"
Write-Host "        -- Same query as above; each option inside the field has its own ID"
Write-Host ""
Write-Host "     d. Repo owner / GitHub username"
Write-Host "        -- Replace [CONFIGURE: owner] with your GitHub username or org name"
Write-Host ""
Write-Host "     e. GitHub Project board name"
Write-Host "        -- Replace [CONFIGURE: your GitHub Project board name] with the display name"
Write-Host ""
Write-Host "  2. In Claude Code, run:"
Write-Host "        /create-ticket wo `"Test ticket`""
Write-Host "     to verify the workflow loads and the slash commands are recognized."
Write-Host ""
Write-Host "  3. Commit the newly installed files:"
Write-Host "        git add .claude/skills .github/templates"
Write-Host "        git commit -m `"chore: install dl-agent-workflow plugin`""
Write-Host ""
Write-Host "Installation complete." -ForegroundColor Green
Write-Host ""
