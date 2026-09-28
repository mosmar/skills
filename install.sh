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
  -p, --platform STR  copilot (default), copilot-global, or claude
      --suite NAME    Install every skill in a suite (see suites.txt), e.g. smell
      --no-deps       Don't auto-install a suite when its entry-point skill is named
  -l, --list          List available skills and suites, then exit
  -h, --help          Show this help

SKILLS
  Space-separated skill names to install. Omit to install all available skills.

EXAMPLES
  # Install all skills into the current project (Copilot)
  ./install.sh

  # Install all skills into your GitHub profile repo
  ./install.sh --target ~/code/your-username

  # Install a whole suite (smell-scanner plus its five deep-dive skills)
  ./install.sh --suite smell

  # Install a specific skill
  ./install.sh log-writer

  # Install multiple skills into a given directory
  ./install.sh --target ~/code/myproject log-writer tech-debt-tracker

  # Install all skills for Claude Code (global)
  ./install.sh --platform claude --target ~/.claude/skills

  # Install all skills as personal Copilot skills, available in every repo
  ./install.sh --platform copilot-global --target ~/.copilot/skills

GITHUB COPILOT — where to point --target
  Project-level  : the root of any git repository
                   skills land in  <repo>/.github/skills/<name>/SKILL.md
  User profile   : the root of your personal profile repository
                   (github.com/<username>/<username> or a dedicated skills repo)
                   skills land in  <repo>/.github/skills/<name>/SKILL.md

GITHUB COPILOT — PERSONAL (GLOBAL), use --platform copilot-global
  Global         : ~/.copilot/skills        (available in every repo, nothing to commit)
  skills land in  <dir>/<name>/SKILL.md

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

# suites.txt lines look like "name: skill skill ..."; print the skills for a suite
suite_skills() {
  local line
  line="$(grep -E "^$1:" "$REPO_DIR/suites.txt" 2>/dev/null | head -n 1)" || true
  [[ -n "$line" ]] && echo $(echo "${line#*:}")
}

list_suites() {
  grep -E '^[A-Za-z0-9_-]+:' "$REPO_DIR/suites.txt" 2>/dev/null | cut -d: -f1
}

# ── argument parsing ──────────────────────────────────────────────────────────

TARGET="$(pwd)"
PLATFORM="copilot"
SELECTED=()
NO_DEPS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)   TARGET="$2"; shift 2 ;;
    -p|--platform) PLATFORM="$2"; shift 2 ;;
    --suite)
      [[ $# -ge 2 ]] || die "--suite needs a name"
      members="$(suite_skills "$2")"
      [[ -n "$members" ]] || die "Unknown suite '$2'. Run --list to see available suites."
      for m in $members; do SELECTED+=("$m"); done
      shift 2 ;;
    --no-deps)     NO_DEPS=1; shift ;;
    -l|--list)
      echo "Available skills:"; list_skills | sed 's/^/  /'
      echo ""; echo "Available suites (--suite NAME):"
      for s in $(list_suites); do echo "  $s: $(suite_skills "$s")"; done
      exit 0 ;;
    -h|--help)     usage; exit 0 ;;
    -*) die "Unknown option: $1" ;;
    *)  SELECTED+=("$1"); shift ;;
  esac
done

[[ "$PLATFORM" =~ ^(copilot|copilot-global|claude)$ ]] || die "Platform must be 'copilot', 'copilot-global', or 'claude'"

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

  # Naming a suite's entry-point skill pulls in the rest of the suite
  if [[ $NO_DEPS -eq 0 ]]; then
    for suite in $(list_suites); do
      members="$(suite_skills "$suite")"
      entry="${members%% *}"
      for s in "${SKILLS[@]}"; do
        if [[ "$s" == "$entry" ]]; then
          for m in $members; do SKILLS+=("$m"); done
          break
        fi
      done
    done
  fi

  # De-duplicate, preserving order
  DEDUPED=()
  for s in "${SKILLS[@]}"; do
    dup=0
    for d in ${DEDUPED[@]+"${DEDUPED[@]}"}; do
      [[ "$d" == "$s" ]] && { dup=1; break; }
    done
    [[ $dup -eq 1 ]] || DEDUPED+=("$s")
  done
  SKILLS=("${DEDUPED[@]}")
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
  elif [[ "$PLATFORM" == "copilot-global" ]]; then
    dest_dir="$TARGET/$skill"
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
elif [[ "$PLATFORM" == "copilot-global" ]]; then
  echo ""
  echo "Next steps:"
  echo "  1. Nothing to commit — these skills are now available in every repo"
  echo "  2. Trigger a skill by describing what you want in a Copilot chat"
fi
