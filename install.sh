#!/usr/bin/env bash
# install.sh — install skills from this repo into a Copilot or Claude Code target directory
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: install.sh [OPTIONS] [SKILL...]

Install skills into a target directory for GitHub Copilot or Claude Code.

OPTIONS
  -t, --target DIR    Destination directory (default: current working directory)
  -p, --platform STR  copilot (default) or claude
  -l, --list          List available skills and exit
  -h, --help          Show this help

SKILLS
  Space-separated skill names to install. Omit to install all available skills.

EXAMPLES
  # Install all skills into the current project (Copilot)
  ./install.sh

  # Install all skills into your GitHub profile repo
  ./install.sh --target ~/code/your-username

  # Install a specific skill
  ./install.sh log-writer

  # Install multiple skills into a given directory
  ./install.sh --target ~/code/myproject log-writer tech-debt-tracker

  # Install all skills for Claude Code (global)
  ./install.sh --platform claude --target ~/.claude/skills

GITHUB COPILOT — where to point --target
  Project-level  : the root of any git repository
                   skills land in  <repo>/.github/skills/<name>/SKILL.md
  User profile   : the root of your personal profile repository
                   (github.com/<username>/<username> or a dedicated skills repo)
                   skills land in  <repo>/.github/skills/<name>/SKILL.md

CLAUDE CODE — where to point --target
  Global         : ~/.claude/skills          (available in every project)
  Project-local  : <project>/.claude/skills  (available in that project only)
  skills land in  <dir>/<name>.md
EOF
}

info()    { printf '\033[1;34m  →\033[0m  %s\n' "$*"; }
ok()      { printf '\033[1;32m  ✓\033[0m  %s\n' "$*"; }
warn()    { printf '\033[1;33m  !\033[0m  %s\n' "$*" >&2; }
die()     { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

list_skills() {
  for dir in "$REPO_DIR"/*/; do
    skill="$(basename "$dir")"
    [[ -f "$dir/SKILL.md" ]] && echo "$skill"
  done
}

# ── argument parsing ──────────────────────────────────────────────────────────

TARGET="$(pwd)"
PLATFORM="copilot"
SELECTED=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)   TARGET="$2"; shift 2 ;;
    -p|--platform) PLATFORM="$2"; shift 2 ;;
    -l|--list)     echo "Available skills:"; list_skills | sed 's/^/  /'; exit 0 ;;
    -h|--help)     usage; exit 0 ;;
    -*) die "Unknown option: $1" ;;
    *)  SELECTED+=("$1"); shift ;;
  esac
done

[[ "$PLATFORM" =~ ^(copilot|claude)$ ]] || die "Platform must be 'copilot' or 'claude'"

# ── resolve skill list ────────────────────────────────────────────────────────

AVAILABLE=()
while IFS= read -r s; do AVAILABLE+=("$s"); done < <(list_skills)

[[ ${#AVAILABLE[@]} -gt 0 ]] || die "No skills found in $REPO_DIR"

if [[ ${#SELECTED[@]} -eq 0 ]]; then
  SKILLS=("${AVAILABLE[@]}")
else
  SKILLS=()
  for s in "${SELECTED[@]}"; do
    found=0
    for a in "${AVAILABLE[@]}"; do
      [[ "$a" == "$s" ]] && { found=1; break; }
    done
    [[ $found -eq 1 ]] || die "Unknown skill '$s'. Run --list to see available skills."
    SKILLS+=("$s")
  done
fi

# ── install ───────────────────────────────────────────────────────────────────

echo ""
echo "Platform : $PLATFORM"
echo "Target   : $TARGET"
echo "Skills   : ${SKILLS[*]}"
echo ""

for skill in "${SKILLS[@]}"; do
  src="$REPO_DIR/$skill/SKILL.md"
  [[ -f "$src" ]] || { warn "SKILL.md not found for '$skill' — skipping"; continue; }

  if [[ "$PLATFORM" == "copilot" ]]; then
    dest_dir="$TARGET/.github/skills/$skill"
    dest="$dest_dir/SKILL.md"
  else
    dest_dir="$TARGET"
    dest="$dest_dir/$skill.md"
  fi

  mkdir -p "$dest_dir"

  if [[ -f "$dest" ]]; then
    if cmp -s "$src" "$dest"; then
      ok "$skill — already up to date"
      continue
    fi
    info "$skill — updating"
  else
    info "$skill — installing"
  fi

  cp "$src" "$dest"
  ok "$skill — done  ($dest)"
done

echo ""
echo "All done."

if [[ "$PLATFORM" == "copilot" ]]; then
  echo ""
  echo "Next steps:"
  echo "  1. Commit and push the .github/skills/ directory to GitHub"
  echo "  2. Copilot will discover the skills automatically — no restart needed"
  echo "  3. Trigger a skill by describing what you want in a Copilot chat"
fi
