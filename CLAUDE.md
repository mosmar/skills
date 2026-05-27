# skills repo — Claude Code context

This is a personal library of agent skills that work in both **Claude Code** and **GitHub Copilot** (cloud agent) from the same `SKILL.md` file.

## Repo layout

```
skill-name/
├── README.md             # Human-facing docs: what it does, how to trigger it, example output
├── SKILL.md              # Canonical skill file — the source of truth
└── evals/
    └── evals.json        # Test cases used during development

.github/skills/
└── skill-name/
    └── SKILL.md          # Mirror of skill-name/SKILL.md — enables Copilot in this repo itself
```

## Key convention: keep .github/skills/ in sync

`.github/skills/<name>/SKILL.md` is always an **exact copy** of `<name>/SKILL.md`. Whenever you edit a canonical `SKILL.md`, immediately copy it to the mirror:

```bash
cp skill-name/SKILL.md .github/skills/skill-name/SKILL.md
```

Never edit the `.github/skills/` copy directly — always edit the canonical file and copy.

## SKILL.md format

```yaml
---
name: skill-name          # required by Claude Code and Copilot
description: >            # required by Claude Code and Copilot
  Natural-language description of when to use this skill. Written for
  the agent's skill-selector — phrase it like "Use this skill when…"
allowed-tools:            # optional — Copilot only
  - shell
---

Markdown instructions for the agent…
```

- `name` and `description` are required by both platforms; everything else is optional.
- Keep the description detailed enough to trigger reliably on natural language — it is used for semantic matching.

## Adding a new skill

1. Create `skill-name/` with `SKILL.md`, `README.md`, and `evals/evals.json`.
2. Mirror it: `cp skill-name/SKILL.md .github/skills/skill-name/SKILL.md`
3. Add a row to the Skills table in the root `README.md`.
4. Commit both the canonical file and the mirror together.

## Skill install paths for Claude Code

| Scope | Path | Notes |
|---|---|---|
| Global (all projects) | `~/.claude/skills/<name>.md` | Available everywhere |
| Project-specific | `.claude/skills/<name>.md` | Only in that project |

Both paths are auto-discovered by Claude Code; no restart required.

## evals.json schema

```json
{
  "skill_name": "skill-name",
  "evals": [
    {
      "id": 0,
      "prompt": "User message that should trigger the skill",
      "expected_output": "Description of what a correct response looks like",
      "files": []
    }
  ]
}
```

`files` is an array of `{ "path": "...", "content": "..." }` objects for any fixture files the eval needs.
