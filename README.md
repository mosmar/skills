# skills

A personal library of Claude agent skills for developer workflows — code analysis, documentation, reporting, and more.

Each skill is a self-contained prompt bundle that extends Claude's behavior for a specific task. Install them in [Cowork](https://claude.ai) or Claude Code to trigger them by name or natural language.

## Skills

| Skill | Description |
|---|---|
| [tech-debt-tracker](./tech-debt-tracker/) | Audits code for technical debt across quality, security, dependencies, and test coverage |

## How to install a skill

1. Open the skill's folder and download the `.skill` file
2. In Cowork or Claude Code, open Settings → Skills → Install from file
3. The skill is now available — trigger it by describing what you want (see each skill's README for example phrases)

## Structure

Each skill follows this layout:

```
skill-name/
├── README.md       # Human-readable docs: what it does, how to use it, example output
├── SKILL.md        # The skill definition Claude reads at runtime
└── evals/
    └── evals.json  # Test cases used during development
```

## Adding a new skill

Skills are built using the [skill-creator](https://docs.claude.ai) workflow inside Cowork. To add one here:

1. Build and test the skill in Cowork
2. Package it as a `.skill` file
3. Create a new folder in this repo named after the skill
4. Drop in `SKILL.md`, `evals/evals.json`, and a `README.md`
5. Add a row to the table above
