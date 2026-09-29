#!/usr/bin/env bash
# install.sh — install skills from this repo for Claude Code or GitHub Copilot, globally or per project
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: install.sh [PLATFORM] [SCOPE] [WHAT...]

Run with no arguments for an interactive menu.

PLATFORM
      --claude        Claude Code
      --copilot       GitHub Copilot

SCOPE
      --global        Every project on this machine, nothing to commit
      --project       One project: the current directory, or --dir DIR
      --dir DIR       Project directory to install into (implies --project)

WHAT (default: all)
  all                 Every skill in this repo (recommended)
  scanner             smell-scanner plus its five deep-dive skills
  guard               smell-guard, the coding standard that prevents smells
  <skill>...          One or more individual skills, e.g. smell-bloaters

OTHER
  -l, --list          List available skills, then exit
  -h, --help          Show this help

WHERE SKILLS LAND  (each skill in <dir>/<name>/SKILL.md)
                --global              --project
  --claude      ~/.claude/skills      <project>/.claude/skills
  --copilot     ~/.copilot/skills     <project>/.github/skills

EXAMPLES
  ./install.sh                                          # interactive menu
  ./install.sh --claude --global all                    # everything, Claude Code, every project
  ./install.sh --copilot --project scanner              # scanner suite into this repo
  ./install.sh --copilot --project --dir ~/code/app guard
  ./install.sh --claude --global smell-bloaters smell-couplers
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

contains() {
  local needle="$1"; shift
  for e in "$@"; do [[ "$e" == "$needle" ]] && return 0; done
  return 1
}

# Where skills land. Usage: root_dir PLATFORM SCOPE [PROJECT_DIR]
root_dir() {
  local project="${3:-$PROJECT_DIR}"
  case "$1:$2" in
    claude:global)   echo "$HOME/.claude/skills" ;;
    claude:project)  echo "$project/.claude/skills" ;;
    copilot:global)  echo "$HOME/.copilot/skills" ;;
    copilot:project) echo "$project/.github/skills" ;;
  esac
}

tilde() { echo "${1/#$HOME/~}"; }

# Numbered menu; sets CHOICE to the picked number. Usage: choose PROMPT DEFAULT OPTION...
choose() {
  local prompt="$1" default="$2" reply i=1
  shift 2
  echo ""
  echo "$prompt"
  for opt in "$@"; do echo "  $i) $opt"; i=$((i + 1)); done
  while true; do
    read -r -p "  Choice${default:+ [$default]}: " reply || die "No input"
    reply="${reply:-$default}"
    if [[ "$reply" =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= $# )); then
      CHOICE="$reply"
      return
    fi
    warn "Enter a number from 1 to $#"
  done
}

ask_project_dir() {
  local default="" reply
  [[ "$PROJECT_DIR" != "$REPO_DIR" ]] && default="$PROJECT_DIR"
  echo ""
  while true; do
    read -r -p "Project directory${default:+ [$(tilde "$default")]}: " reply || die "No input"
    reply="${reply:-$default}"
    reply="${reply/#\~/$HOME}"
    if [[ -n "$reply" && -d "$reply" ]]; then
      PROJECT_DIR="$reply"
      return
    fi
    warn "Enter the path to an existing directory"
  done
}

pick_individual() {
  local reply n bad i=1
  echo ""
  echo "Which skills? (space-separated numbers)"
  for s in "${AVAILABLE[@]}"; do echo "  $i) $s"; i=$((i + 1)); done
  while true; do
    read -r -p "  Choice: " reply || die "No input"
    SELECTED=()
    bad=0
    for n in $reply; do
      if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#AVAILABLE[@]} )); then
        SELECTED+=("${AVAILABLE[n - 1]}")
      else
        bad=1
      fi
    done
    [[ $bad -eq 0 && ${#SELECTED[@]} -gt 0 ]] && return
    warn "Enter one or more numbers from 1 to ${#AVAILABLE[@]}"
  done
}

# ── argument parsing ──────────────────────────────────────────────────────────

PLATFORM=""
SCOPE=""
PROJECT_DIR="$(pwd)"
DIR_SET=0
SELECTED=()
NO_ARGS=0; [[ $# -eq 0 ]] && NO_ARGS=1

AVAILABLE=()
while IFS= read -r s; do AVAILABLE+=("$s"); done < <(list_skills)
[[ ${#AVAILABLE[@]} -gt 0 ]] || die "No skills found in $REPO_DIR"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)  PLATFORM="claude"; shift ;;
    --copilot) PLATFORM="copilot"; shift ;;
    --global)  SCOPE="global"; shift ;;
    --project) SCOPE="project"; shift ;;
    --dir)
      [[ $# -ge 2 ]] || die "--dir needs a directory"
      PROJECT_DIR="$2"; DIR_SET=1; shift 2 ;;
    -p|--platform|-t|--target|--suite|--no-deps)
      die "$1 was replaced. Use --claude/--copilot, --global/--project [--dir DIR], and all|scanner|guard|<skill>. See --help." ;;
    -l|--list)
      echo "Skills:"; printf '  %s\n' "${AVAILABLE[@]}"
      echo ""; echo "Groups:"
      echo "  all: ${AVAILABLE[*]}"
      for s in $(list_suites); do echo "  $s: $(suite_skills "$s")"; done
      exit 0 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "Unknown option: $1" ;;
    *)  SELECTED+=("$1"); shift ;;
  esac
done

if [[ $DIR_SET -eq 1 ]]; then
  [[ "$SCOPE" != "global" ]] || die "--dir only applies to --project"
  SCOPE="project"
fi

# ── fill in missing choices ───────────────────────────────────────────────────

MENU_USED=0

if [[ ${#SELECTED[@]} -eq 0 ]]; then
  if [[ $NO_ARGS -eq 1 && -t 0 ]]; then
    MENU_USED=1
    choose "What do you want to install?" 1 \
      "All skills (recommended)" \
      "Scanner — smell-scanner plus its five deep-dive skills" \
      "Guard — smell-guard, the coding standard that prevents smells" \
      "Pick individual skills"
    case "$CHOICE" in
      1) SELECTED=(all) ;;
      2) SELECTED=(scanner) ;;
      3) SELECTED=(guard) ;;
      4) pick_individual ;;
    esac
  else
    SELECTED=(all)
  fi
fi

if [[ -z "$PLATFORM" ]]; then
  [[ -t 0 ]] || die "Choose a platform: --claude or --copilot. See --help."
  MENU_USED=1
  choose "Which agent?" "" "Claude Code" "GitHub Copilot"
  case "$CHOICE" in 1) PLATFORM="claude" ;; 2) PLATFORM="copilot" ;; esac
fi

ASK_DIR=0
if [[ -z "$SCOPE" ]]; then
  [[ -t 0 ]] || die "Choose a scope: --global or --project. See --help."
  MENU_USED=1
  choose "Install where?" 1 \
    "Global — every project on this machine, nothing to commit  ($(tilde "$(root_dir "$PLATFORM" global)"))" \
    "A project — commit it to share with your team  ($(root_dir "$PLATFORM" project "<project>"))"
  case "$CHOICE" in 1) SCOPE="global" ;; 2) SCOPE="project"; ASK_DIR=1 ;; esac
fi

# Running from this repo's root is the documented way to install, so "current directory" means
# this repo — ask for the real project instead
if [[ "$SCOPE" == "project" && $DIR_SET -eq 0 && "$PROJECT_DIR" == "$REPO_DIR" ]]; then
  [[ -t 0 ]] || die "--project installs into the current directory, which is this skills repo. Add --dir <project>."
  ASK_DIR=1
fi
if [[ $ASK_DIR -eq 1 && $DIR_SET -eq 0 ]]; then
  MENU_USED=1
  ask_project_dir
fi

if [[ "$SCOPE" == "project" ]]; then
  [[ -d "$PROJECT_DIR" ]] || die "Project directory not found: $PROJECT_DIR"
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
fi

ROOT="$(root_dir "$PLATFORM" "$SCOPE")"

# ── resolve skill list ────────────────────────────────────────────────────────

SKILLS=()
for s in "${SELECTED[@]}"; do
  if [[ "$s" == "all" ]]; then
    SKILLS+=("${AVAILABLE[@]}")
  elif members="$(suite_skills "$s")" && [[ -n "$members" ]]; then
    for m in $members; do SKILLS+=("$m"); done
  else
    contains "$s" "${AVAILABLE[@]}" || die "Unknown skill '$s'. Run --list to see available skills."
    SKILLS+=("$s")
  fi
done

# De-duplicate, preserving order
DEDUPED=()
for s in "${SKILLS[@]}"; do
  contains "$s" ${DEDUPED[@]+"${DEDUPED[@]}"} || DEDUPED+=("$s")
done
SKILLS=("${DEDUPED[@]}")

# A suite's entry-point skill hands off to the rest of the suite; flag it when they're missing
for suite in $(list_suites); do
  members="$(suite_skills "$suite")"
  entry="${members%% *}"
  contains "$entry" "${SKILLS[@]}" || continue
  for m in $members; do
    if ! contains "$m" "${SKILLS[@]}"; then
      warn "$entry hands off to the rest of the '$suite' group. Install '$suite' to get them all."
      break
    fi
  done
done

# ── install ───────────────────────────────────────────────────────────────────

case "$PLATFORM" in claude) platform_name="Claude Code" ;; copilot) platform_name="GitHub Copilot" ;; esac
case "$SCOPE" in global) scope_name="global (every project)" ;; project) scope_name="project ($(tilde "$PROJECT_DIR"))" ;; esac

echo ""
echo "Platform : $platform_name"
echo "Scope    : $scope_name"
echo "Target   : $(tilde "$ROOT")"
echo "Skills   : ${SKILLS[*]}"
echo ""

if [[ $MENU_USED -eq 1 ]]; then
  read -r -p "Proceed? [Y/n] " reply || die "No input"
  [[ "$reply" =~ ^[Nn] ]] && { echo "Cancelled."; exit 0; }
  echo ""
fi

for skill in "${SKILLS[@]}"; do
  src="$REPO_DIR/$skill/SKILL.md"
  [[ -f "$src" ]] || { warn "SKILL.md not found for '$skill' — skipping"; continue; }

  dest_dir="$ROOT/$skill"
  dest="$dest_dir/SKILL.md"

  if [[ "$PLATFORM" == "claude" && -f "$ROOT/$skill.md" ]]; then
    warn "$skill — old flat file $(tilde "$ROOT/$skill.md") found. Claude Code reads $skill/SKILL.md, so delete the old file."
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
  ok "$skill — done  ($(tilde "$dest"))"
done

echo ""
echo "All done."
echo ""
echo "Next steps:"
case "$PLATFORM:$SCOPE" in
  copilot:project) echo "  1. Commit and push .github/skills/ so everyone on the repo gets the skills" ;;
  claude:project)  echo "  1. Commit .claude/skills/ so everyone on the project gets the skills" ;;
  *:global)        echo "  1. Nothing to commit. The skills are available in every project on this machine" ;;
esac
echo "  2. Trigger a skill by describing what you want. See each skill's README for example phrases"
