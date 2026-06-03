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

### GitHub Copilot (cloud agent)

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

### Claude Code

```bash
# Global — available in every project
cp SKILL.md ~/.claude/skills/smell-scanner.md

# Project-specific
mkdir -p .claude/skills
cp SKILL.md .claude/skills/smell-scanner.md
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

```bash
mkdir -p .github/skills/smell-scanner
curl -o .github/skills/smell-scanner/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/smell-scanner/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Three test cases: over-loaded service, switch-statement notifier, legacy utils file |
