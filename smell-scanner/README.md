# smell-scanner

The entry point for the code smells suite. Does a fast triage pass across all five smell
categories and tells you which focused skill to run next.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

## When to use it

Run this first when you're not sure what kind of smells are present. It sweeps all five
categories from the [refactoring.guru taxonomy](https://refactoring.guru/refactoring/smells),
rates each one (None / Mild / Moderate / Severe), and routes you to the right focused skill.
It's fast and cheap — use it as a first pass before deciding where to go deep.

If you already know which smell category you're dealing with, skip this and go straight to
the focused skill.

## How to trigger it

### Claude Code / Cowork

- *"Scan this file for code smells"*
- *"Quick smell audit on my service layer"*
- *"Any smells in this code?"*
- *"Smell check before I refactor this"*

Works with pasted snippets, single files, or a whole directory.

### GitHub Copilot (VS Code agent mode / cloud agent)

Copilot picks the skill automatically from its `description`, so natural phrasing works. You can also name the skill to invoke it explicitly.

- *"Scan #file:src/services/order.service.ts for code smells"*
- *"Quick smell audit on src/services/"*
- *"Any smells in #selection?"*
- *"Smell check #codebase before I refactor this"*
- *"Use the smell-scanner skill on src/services/"*
- *"Run a smell scan on this file"*

## Output

A structured triage report — one severity rating per category, one or two concrete examples
if smells are present, and explicit routing recommendations:

```
## Smell Scan — order.service.ts

### Smells found

**Bloaters** ⚠️ Severe
`processOrder()` is 60+ lines handling validation, pricing, payment, inventory, and
notifications — five responsibilities in one method. Also takes 7 parameters.

**OO Abusers** ⚠️ None

**Change Preventers** ⚠️ Mild
Single file — run a multi-file scan to confirm, but `processOrder` touching 4 services
suggests changes may ripple.

**Dispensables** ⚠️ Mild
Inline SQL scattered through business logic rather than in a repository layer.

**Couplers** ⚠️ Moderate
`processOrder` both delegates to services AND queries the database directly — inconsistent
abstraction level, coupling to two things at once.

---
### Where to dig deeper

- Run **smell-bloaters** — the 7-param, 60-line method is the dominant issue
- Run **smell-couplers** — mixed abstraction levels worth a focused pass

### Overall health
The core logic file has significant bloat that's making it hard to test and change.
Bloaters are the priority — splitting processOrder will naturally resolve some of
the coupling issues too.
```

## Respects your stack

- **Never swaps frameworks or libraries.** Fixes use what the project already has — it won't
  suggest replacing Mongoose or an ORM, or migrating Express to NestJS.
- **Generated scaffold code is the clean baseline.** If your project came from an org
  template or generator, the structure it produces isn't reported as a smell, so a fresh
  project comes out clean and every project built from the scaffold stays consistent.
- **Framework patterns don't count toward ratings** — thin controllers, data-shaped
  schemas and DTOs, per-feature layering, and reducers are expected.
- **Convention notes, not findings.** If an existing convention itself looks like a smell,
  it's mentioned separately — unrated and outside the refactoring order — so your team can
  decide whether to change the standard.
- **Tunable.** Ask for a "full scan" or "audit the template" to see scaffold patterns as
  `[baseline]` findings, or set project-wide rules with a `## Smell baseline` section — see
  [Tuning the smell suite](../README.md#tuning-the-smell-suite).

## The full suite

This skill is part of a five-skill deep-dive suite:

| Skill | Category | Root cause |
|---|---|---|
| [smell-bloaters](../smell-bloaters/) | Bloaters | Things too big — decompose |
| [smell-oo-abusers](../smell-oo-abusers/) | OO Abusers | OOP misapplied — use the language properly |
| [smell-change-preventers](../smell-change-preventers/) | Change Preventers | Hard to change — isolate responsibility |
| [smell-dispensables](../smell-dispensables/) | Dispensables | Unnecessary code — delete it |
| [smell-couplers](../smell-couplers/) | Couplers | Overtangled — move responsibility |

## Installing

The scanner recommends running its five sibling skills, so install them together. Naming
`smell-scanner` (or using `--suite smell`) installs the whole suite from the repo root:

```bash
# Claude Code — global
./install.sh --platform claude --target ~/.claude/skills --suite smell

# Claude Code — project-specific
./install.sh --platform claude --target .claude/skills --suite smell

# GitHub Copilot — into the current project's .github/skills/
./install.sh --suite smell
```

Use `--no-deps` to install `smell-scanner` on its own.

### Manual install (single skill)

Copy each of the six `SKILL.md` files — the scanner alone will point you at skills you
don't have.

- **Claude Code:** `cp <skill>/SKILL.md ~/.claude/skills/<skill>.md`
- **Cowork:** Settings → Skills → Install from file, once per skill
- **Copilot:** place each at `.github/skills/<skill>/SKILL.md`

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Three test cases: over-loaded service, switch-statement notifier, legacy utils file |
