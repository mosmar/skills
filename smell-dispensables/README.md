# smell-dispensables

Deep-dive analysis of Dispensable code smells — unnecessary code whose removal makes the
codebase cleaner, faster to navigate, and easier to maintain. The unifying fix: delete it.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

## The six Dispensable smells

Based on the [refactoring.guru Dispensables catalog](https://refactoring.guru/refactoring/smells/dispensables):

| Smell | Signal | Fix |
|---|---|---|
| **Comments** | Explains *what* code does, not *why*; section dividers; commented-out code | Rename Method/Variable, Extract Method, delete |
| **Duplicate Code** | Same logic in multiple places; copy-pasted with minor variations | Extract Method, Form Template Method |
| **Lazy Class** | Class with one method, wraps one call, barely justifies existing | Inline Class, Collapse Hierarchy |
| **Data Class** | Only fields/getters/setters, behavior lives in callers | Move Method, Encapsulate Field |
| **Dead Code** | Never called, unreachable, commented-out, always-ignored params | Delete |
| **Speculative Generality** | "Just in case" abstractions, unused hooks, params always at default | Collapse Hierarchy, Remove Parameter, Inline Class |

## When to use it

Run after `smell-scanner` rates Dispensables as Moderate or Severe, or directly when you
suspect unnecessary code — a file that feels cluttered, duplicate logic you've noticed, an
abstraction layer that doesn't seem to do anything, or code that's been marked TODO for
months.

## How to trigger it

### Claude Code / Cowork

- *"Do a dispensables analysis on this module"*
- *"What can I delete from this file?"*
- *"smell-scanner said Dispensables were Moderate, run the focused pass"*
- *"We have a lot of duplicate logic in these services"*
- *"This abstraction layer feels unnecessary"*
- *"There's a bunch of dead code in here, help me find it"*

### GitHub Copilot (cloud agent)

- *"Use the smell-dispensables skill on src/services/"*

## Output

A findings report ordered by cleanup effort — dead code and comments first (pure removals),
then duplicates, then structural dispensables:

```
## Dispensables Analysis — report.service.ts

### Summary
Three smells dominate: near-identical cache/fetch logic duplicated across three methods,
seven what-not-why comments, and two speculative features that are clearly unused. The
duplicate logic is the highest-value fix — one Extract Method eliminates ~30 lines.

### Findings

#### Duplicate Code — getUserReports / getAdminReports / getTeamReports
- **Location**: `report.service.ts`, lines 14–42
- **Why it's dispensable**: All three methods are identical except for the cache key prefix
  and the SQL filter column. A bug fix or TTL change must be applied three times.
- **Refactoring**: Extract Method — create a private `fetchWithCache(cacheKey, query, param)`
  and call it from all three. Reduces ~30 lines to ~5.
- **Effort**: Low

#### Dead Code — getTenantReports() always throws
- **Location**: `report.service.ts`, lines 44–46
- **Why it's dispensable**: The method body is `throw new Error('Not implemented')`.
  It's dead at runtime and signals unfinished work.
- **Refactoring**: Delete it. The TODO comment is captured in version control history.
- **Effort**: Low

#### Speculative Generality — fetchReports() with 6 params for one use case
- **Location**: `report.service.ts`, lines 48–54
- **Why it's dispensable**: Only handles `entityType === 'user'` and returns `[]` for
  everything else. Five of its six parameters go unused. The generality it was built for
  doesn't exist yet.
- **Refactoring**: Delete it. If multi-entity support is ever needed, design it then with
  real requirements.
- **Effort**: Low
...

---
### Cleanup order
1. Delete commented-out getUserReportsV1 and getTenantReports — zero risk
2. Delete fetchReports — verify no external callers first
3. Extract fetchWithCache() and consolidate the three report methods
4. Remove what-not-why comments — the code is readable without them
```

## Part of the code smells suite

Run `smell-scanner` first for a broad triage. This skill goes deep on Dispensables.

## Installing

### Claude Code

```bash
cp SKILL.md ~/.claude/skills/smell-dispensables.md
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

```bash
mkdir -p .github/skills/smell-dispensables
curl -o .github/skills/smell-dispensables/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/smell-dispensables/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Two test cases: TypeScript report service with 3-way duplication + speculative code; Python models with triplicated address dataclasses + single-impl abstract base |
