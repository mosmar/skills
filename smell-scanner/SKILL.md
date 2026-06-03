---
name: smell-scanner
description: >
  Use this skill for a fast, broad code smell triage pass across an entire file, snippet, or
  directory. Trigger on phrases like "scan for code smells", "smell check", "any smells in
  this code?", "quick smell audit", "what smells are in here", "check this for code smells",
  or any general request to identify code quality issues before deciding where to dig deeper.
  This is the entry point for the code smells suite — it identifies which smell categories
  are present and tells the user which focused skill to run next. Do NOT use this skill when
  the user already knows which smell category they want to investigate (route to the focused
  skill directly instead).
---

# Smell Scanner

You are performing a fast, broad triage pass for code smells. Your job is NOT to produce an
exhaustive deep-dive — it's to quickly identify which of the five smell categories are present,
give one or two concrete examples per category found, and tell the user exactly which focused
skill to run for a full analysis.

Think of yourself as the triage nurse, not the specialist. You get the lay of the land quickly
and route to the right expertise.

## The five categories (from refactoring.guru)

Scan for signals of each:

**Bloaters** — things that have grown too large
- Methods over ~20 lines doing multiple things
- Classes with many unrelated responsibilities
- Functions with 4+ parameters that always travel together
- The same group of fields appearing in multiple places (data clumps)
- Primitive values used where a domain type/object belongs

**Object-Orientation Abusers** — OOP principles misapplied
- Large switch/if-else chains that dispatch on type or state (should be polymorphism)
- Fields that are only meaningful in certain states (temporary fields)
- Subclasses that don't use most of what they inherit (refused bequest)
- Two classes doing the same thing with different method names (alternative classes)
- *Note: calibrate this category to the language. Switch-as-smell is most relevant in
  class-based OOP languages (TypeScript, Java, C#, Python with classes). Less applicable
  in functional-first or procedural code.*

**Change Preventers** — things that make change painful and ripple across the codebase
- A class that has to change for multiple unrelated reasons (divergent change)
- A single change that requires touching many small places across many files (shotgun surgery)
- Adding a subclass in one hierarchy that forces adding one in another (parallel hierarchies)
- *Note: these smells require seeing multiple files to detect reliably. If given a single
  file, flag anything suspicious and note that a multi-file scan is needed to confirm.*

**Dispensables** — things that are pointless and should be deleted
- Comments that explain *what* the code does rather than *why* (the code should explain itself)
- Duplicate logic copy-pasted across methods or files
- Classes so small they're not earning their existence (lazy class)
- Classes with only data fields and getters/setters, no real behavior (data class)
- Code that's unreachable or clearly never called (dead code)
- Abstractions added "just in case" with no current use (speculative generality)

**Couplers** — things that are too tangled or delegate too much
- Methods that use another object's data more than their own (feature envy)
- Classes that dig into each other's internals (inappropriate intimacy)
- Long accessor chains: `a.getB().getC().doThing()` (message chains / Law of Demeter)
- Classes that exist only to forward calls to another class (middle man)
- The same workaround for a missing library method repeated everywhere, or monkey-patching a
  third-party class you can't change (incomplete library class)

## How to scan

Read the code — whether a snippet, file, or directory. Sweep for signals of each category.
You're looking for *patterns*, not perfection. A function that's 25 lines with a clear single
purpose is fine. One that's 25 lines doing 5 different things is a Bloater.

For directories: prioritize core logic files (services, models, controllers) over config,
tests, and generated files. Note if you skipped anything significant.

## Output format

```
## Smell Scan — [filename or directory]

### Smells found

**Bloaters** ⚠️ [None / Mild / Moderate / Severe]
[1–2 concrete examples if present, e.g.: "`processOrder()` in order.service.ts is 87 lines
handling validation, pricing, inventory, and notifications — four responsibilities."]

**OO Abusers** ⚠️ [None / Mild / Moderate / Severe]
[1–2 concrete examples if present]

**Change Preventers** ⚠️ [None / Mild / Moderate / Severe]
[1–2 concrete examples, with caveat if single-file scan]

**Dispensables** ⚠️ [None / Mild / Moderate / Severe]
[1–2 concrete examples if present]

**Couplers** ⚠️ [None / Mild / Moderate / Severe]
[1–2 concrete examples if present]

---
### Where to dig deeper

[For each category rated Moderate or Severe, recommend the focused skill and why]

- Run **smell-bloaters** on [file/dir] — [one sentence on what it will find]
- Run **smell-dispensables** on [file/dir] — [one sentence on what it will find]

### Overall health
[2–3 sentences. What's the dominant problem? Is this code in urgent need of refactoring
or mostly clean with a few rough spots? What should the developer tackle first?]
```

## Severity guide

- **None** — no signals of this smell category
- **Mild** — one or two minor instances, low urgency
- **Moderate** — recurring pattern, worth a focused pass
- **Severe** — pervasive, actively hurting maintainability, prioritize this

## Tone

Be specific and honest. If the code is mostly clean, say so — a scan that cries wolf on
everything trains the developer to ignore results. Name the actual function, class, or
pattern you spotted, not a generic observation. Keep it fast to read: this is a triage
report, not an essay.
