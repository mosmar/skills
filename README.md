# skills

A personal library of agent skills for developer workflows — code analysis, documentation, reporting, and more.

Each skill is a self-contained `SKILL.md` file that works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent) from the same file format — `name` and `description` are required by both.

## Skills

| Skill | Description |
|---|---|
| [tech-debt-tracker](./tech-debt-tracker/) | Audits code for technical debt across quality, security, dependencies, and test coverage |
| [log-writer](./log-writer/) | Adds or improves logging using production best practices — right levels, structured output, context, no sensitive data |
| [prompt-sharpener](./prompt-sharpener/) | Turns a vague Copilot ask into a tight, ready-to-paste prompt — fewer round trips, fewer premium requests burned |
| [context-trimmer](./context-trimmer/) | Extracts the minimum viable code slices across files for a specific question — reduces token consumption on multi-file asks |

## How to install a skill

### Claude Code
Copy `SKILL.md` to a skills directory Claude Code watches:

```bash
# Global — available in every project
cp skill-name/SKILL.md ~/.claude/skills/skill-name.md

# Project-specific — only in that project
mkdir -p .claude/skills
cp skill-name/SKILL.md .claude/skills/skill-name.md
```

Claude Code discovers skills in both locations automatically. Trigger by describing what you want — see each skill's README for example phrases.

### Cowork
1. Download `SKILL.md` from the skill's folder
2. Open Settings → Skills → Install from file
3. Trigger it by describing what you want

### GitHub Copilot (cloud agent)
Copy the `SKILL.md` into `.github/skills/<skill-name>/` in your project:

```bash
mkdir -p .github/skills/tech-debt-tracker
curl -o .github/skills/tech-debt-tracker/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/tech-debt-tracker/SKILL.md
```

Copilot automatically discovers skills in `.github/skills/` and selects the right one based on your prompt and the skill's `description`. See the [GitHub docs](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills) for details.

## File format

`SKILL.md` uses YAML frontmatter with the same keys required by both Claude Code and the Copilot cloud agent:

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
