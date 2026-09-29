# skills

A personal library of agent skills for detecting and refactoring code smells — fast triage, deep per-category analysis, and an agent-facing coding standard that prevents smells before they're written.

Each skill is a self-contained `SKILL.md` file that works with **Claude Code**, **Cowork**, and **GitHub Copilot** from the same file format — `name` and `description` are required by both.

## Skills

| Skill | Description |
|---|---|
| [smell-guard](./smell-guard/) | Agent-facing coding standard — prevents smells from being introduced while code is being written, with stack rules for Angular, NestJS, Express, MongoDB, and MSSQL |
| [smell-scanner](./smell-scanner/) | Fast triage pass across all five code smell categories — rates each and routes to the right focused skill |
| [smell-bloaters](./smell-bloaters/) | Deep analysis of Bloater smells — Long Method, Large Class, Primitive Obsession, Long Parameter List, Data Clumps |
| [smell-dispensables](./smell-dispensables/) | Deep analysis of Dispensable smells — Duplicate Code, Dead Code, Lazy Class, Comments, Speculative Generality |
| [smell-couplers](./smell-couplers/) | Deep analysis of Coupler smells — Feature Envy, Inappropriate Intimacy, Message Chains, Middle Man |
| [smell-oo-abusers](./smell-oo-abusers/) | Deep analysis of OO Abuser smells in JS/TS — Switch Statements, Temporary Field, Refused Bequest, Alternative Classes |
| [smell-change-preventers](./smell-change-preventers/) | Deep analysis of Change Preventer smells — Divergent Change, Shotgun Surgery, Parallel Inheritance Hierarchies |

## How to install

Clone this repo and run the installer from its root:

```bash
./install.sh
```

It asks three questions:

1. **What to install**
   - **All skills (recommended)**: the scanner group and the guard together
   - **Scanner**: smell-scanner plus its five deep-dive skills, for analyzing existing code
   - **Guard**: smell-guard, the coding standard that stops smells being written
   - **Individual skills**: pick from a list
2. **Which agent**: Claude Code or GitHub Copilot
3. **Where**: global, or a project you name

| | Global: every project on this machine, nothing to commit | Project: one repo, commit it to share with your team |
|---|---|---|
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` | `<project>/.claude/skills/<name>/SKILL.md` |
| **GitHub Copilot** | `~/.copilot/skills/<name>/SKILL.md` | `<project>/.github/skills/<name>/SKILL.md` |

Both agents discover skills in these locations automatically. They pick the right one from your
prompt and the skill's `description`. See each skill's README for example phrases, and the
[GitHub docs](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
for more on Copilot skills.

### Flags

Skip the menu by passing the same choices as flags:

```bash
./install.sh --claude  --global all                        # recommended
./install.sh --copilot --global scanner
./install.sh --copilot --project --dir ~/code/app guard     # project: pass its path with --dir
./install.sh --claude  --project --dir ~/code/app all
./install.sh --claude  --global smell-bloaters smell-couplers

./install.sh --list    # skills and groups
./install.sh --help
```

Groups are defined in [suites.txt](./suites.txt).

### By hand

Each skill is one file. Copy it into `<skills dir>/<name>/SKILL.md`, using the table above:

```bash
mkdir -p ~/.claude/skills/smell-scanner
cp smell-scanner/SKILL.md ~/.claude/skills/smell-scanner/
```

### Cowork

1. Download `SKILL.md` from the skill's folder
2. Open Settings → Skills → Install from file
3. Trigger it by describing what you want

## Tuning the smell suite

By default the smell skills treat your project's frameworks, libraries, and generated
scaffold as the clean baseline. They never suggest swapping libraries, and they don't report
scaffold patterns as smells. You can adjust that in two ways.

**Per request (analysis skills only).** Ask to "include the scaffold", "audit the template",
or run a "full scan". Scaffold patterns are then reported as findings prefixed `[baseline]`,
which is useful when you maintain the template itself. smell-guard has no per-request
switch, so it never refactors generated code unless you ask for that directly.

**Per project (all smell skills).** Add a section to `CLAUDE.md` (Claude Code) or
`.github/copilot-instructions.md` (Copilot). Both are loaded automatically, so everyone on
the team gets the same behavior:

```markdown
## Smell baseline
- baseline: scaffold            # scaffold (default) | none — none = treat all code as team code
- ignore: src/generated/**, **/*.spec.ts
- conventions:                  # standard here, even if it looks like a smell
  - Business logic lives in services; schemas stay data-only
- enforce:                      # conventions the team decided to change — treat as rules
  - Statuses are enums, never plain strings
```

| Key | Analysis skills | smell-guard |
|---|---|---|
| `baseline: none` | Report scaffold patterns as `[baseline]` findings | Scaffold conventions stop overriding its rules. It still won't refactor existing code unless asked |
| `ignore` | Never analyzed or mentioned | Never edited unless you name the path |
| `conventions` | Never reported | Followed as standard |
| `enforce` | Violations are normal findings | Applied to new code. Existing violations are flagged, not rewritten |

Request wording beats project settings, and project settings beat the defaults. No setting
makes a skill replace a framework or library. That only comes up if you explicitly ask about
library choice.

## File format

`SKILL.md` uses YAML frontmatter with the same keys required by both Claude Code and Copilot:

```yaml
---
name: skill-name          # required by Claude Code and Copilot
description: >            # required by Claude Code and Copilot
  Natural-language description of when to use this skill …
allowed-tools:            # optional — Copilot only, pre-approves tools without confirmation
  - shell
---

Markdown instructions for the agent…
```

This means a single `SKILL.md` works in both environments with no changes.

## Repo layout

```
skill-name/
├── README.md             # Human-readable docs: what it does, how to trigger it, example output
├── SKILL.md              # Canonical skill file — works in Claude Code, Cowork, and Copilot
└── evals/
    └── evals.json        # Test cases used during development

.github/skills/
└── skill-name/
    └── SKILL.md          # Copy of skill-name/SKILL.md — enables Copilot in this repo itself
```

## Adding a new skill

1. Create `skill-name/SKILL.md` with `name` and `description` frontmatter and markdown instructions
2. Add `skill-name/README.md` and `skill-name/evals/evals.json`
3. Copy `SKILL.md` → `.github/skills/skill-name/SKILL.md`
4. Add a row to the Skills table above
