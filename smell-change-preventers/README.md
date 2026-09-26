# smell-change-preventers

Deep-dive analysis of Change Preventer smells — structural problems that make every future
change more expensive than it should be. Requires multiple files to be genuinely useful.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

## The three Change Preventer smells

Based on the [refactoring.guru Change Preventers catalog](https://refactoring.guru/refactoring/smells/change-preventers):

| Smell | Signal | Fix |
|---|---|---|
| **Divergent Change** | One class changes for many unrelated reasons | Extract Class — one class per reason to change |
| **Shotgun Surgery** | One logical change touches 5+ files | Move Method/Field, consolidate scattered logic |
| **Parallel Inheritance Hierarchies** | Adding a subclass in hierarchy A forces one in hierarchy B | Merge hierarchies, move behavior into one |

## Why this skill needs multiple files

Change Preventers are patterns that only become visible across a codebase. A single file
can reveal *suspects* — a class that handles multiple concerns, a type defined in multiple
places — but confirming the blast radius of a change requires seeing how the files relate.
**Always provide a directory or a set of related files for best results.**

When given a single file, this skill will flag what it can and clearly mark findings as
"suspected" vs. "confirmed."

## When to use it

Run after `smell-scanner` rates Change Preventers as Moderate or Severe, or when you
notice yourself touching many files for a single logical change — adding a field, supporting
a new variant, or enabling a new channel.

## How to trigger it

### Claude Code / Cowork

- *"Change preventers analysis on src/users/"*
- *"Every time I add a new field I touch 6 files — what's wrong?"*
- *"smell-scanner flagged Change Preventers, run the focused pass"*
- *"Do a shotgun surgery analysis on these files"*
- *"These two class hierarchies always grow together — is that a problem?"*

### GitHub Copilot (VS Code agent mode / cloud agent)

Copilot picks the skill automatically from its `description`, so natural phrasing works. You can also name the skill to invoke it explicitly.

- *"Change preventers analysis on src/users/"*
- *"Every time I add a new field I touch 6 files — check #codebase for what's wrong"*
- *"smell-scanner flagged Change Preventers, run the smell-change-preventers focused pass"*
- *"Do a shotgun surgery analysis on #file:src/users/user.service.ts and #file:src/users/user.controller.ts"*
- *"These two class hierarchies always grow together — is that a problem?"*
- *"Use the smell-change-preventers skill on src/"*

## Output

A structural diagnosis with a concrete hypothetical change trace showing exactly how many
files would need to change today vs. after refactoring:

```
## Change Preventers Analysis — src/users/

### Structure overview
Five files implement the User concept: model (interface), DTO (response shape), mapper
(model↔DTO), validator (field rules), repository (DB queries). Each encodes all the same
User fields independently.

### Smells found

#### Shotgun Surgery — adding a User field touches 5 files
- **Scope**: user.model.ts, user.dto.ts, user.mapper.ts, user.validator.ts, user.repository.ts
- **The pattern**: Every User field is declared and handled independently in each layer.
  There is no single source of truth for what a User contains.
- **The cost**: Adding `phoneNumber` to User requires editing all five files plus any
  test fixtures — a 5-file change for a 1-field addition.
- **Refactoring**: Consolidate — either collapse the DTO/Mapper layers (use the model
  directly, or generate from it), or centralize field definitions so they flow through
  automatically.
- **Effort**: High
- **Confidence**: Confirmed

---
### Hypothetical change trace
Adding `phoneNumber: string` to User **today**: edit user.model.ts → user.dto.ts →
user.mapper.ts → user.validator.ts → user.repository.ts = 5 files.

After consolidating DTO and Mapper: edit user.model.ts → user.repository.ts = 2 files.

### Refactoring order
1. Remove the DTO layer if the API contract allows — the model often suffices
2. If the DTO must stay, generate it from the model rather than maintaining it in parallel
3. Move the role validation constant from validator into the model type definition
```

## Respects your stack

- **Never swaps frameworks or libraries.** Fixes use what the project already has — it won't
  suggest replacing Mongoose or an ORM, or migrating Express to NestJS.
- **Generated scaffold code is the clean baseline.** If your project came from an org
  template or generator, the structure it produces isn't reported as a smell, so a fresh
  project comes out clean and every project built from the scaffold stays consistent.
- **Separates convention from cost** — files a change must touch because of the standard
  layering are listed apart from the extra edits that are the actual smell.
- **Convention notes, not findings.** If an existing convention itself looks like a smell,
  it's mentioned separately — unrated and outside the refactoring order — so your team can
  decide whether to change the standard.

## Part of the code smells suite

Run `smell-scanner` first for a broad triage. This skill goes deep on Change Preventers.

## Installing

### Claude Code

```bash
cp SKILL.md ~/.claude/skills/smell-change-preventers.md
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

```bash
mkdir -p .github/skills/smell-change-preventers
curl -o .github/skills/smell-change-preventers/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/smell-change-preventers/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Two test cases: User across 5 thin layers (Shotgun Surgery); Notification + Handler parallel hierarchies |
