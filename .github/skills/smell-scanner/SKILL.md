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

## Respect the project baseline

The project's frameworks, libraries, and generated scaffold are the standard you measure
against — not the subject of the review. Teams move between projects built from the same
scaffold, so consistency with it outweighs any individual refactoring.

- **Never recommend replacing a framework or library.** Don't suggest swapping the data layer
  (Mongoose, TypeORM, Prisma, Sequelize, knex, mssql), the web framework (Express, NestJS,
  Angular), or the validation, logging, HTTP, state-management, or test library — and never an
  architecture migration such as Express → NestJS. Every fix you point toward must use what the
  project already has.
- **Generated scaffold code is the clean baseline.** If the project was generated from an
  organization template or CLI, the structure it produces — per-feature module / controller /
  service / DTO / schema files, gateway wiring, standard folders, base classes, placeholder
  files — is not a finding, even where it resembles a smell. A freshly generated project should
  scan clean.
- **Recognizing the baseline.** Look for conventions documented in `CLAUDE.md`,
  `.github/copilot-instructions.md`, or a README / standards doc; patterns repeated uniformly
  across every feature or service; and, when git history is available, files unchanged since
  the initial generated commit. When unsure whether a pattern is convention, treat it as
  convention and say so.
- **Findings target what the team built on top.** Judge added code against the baseline's own
  shape — a service that has grown well past the scaffold's pattern is a finding; the pattern
  itself is not.
- **Convention notes, not findings.** If a baseline convention itself looks like a smell, you
  may mention it under *Convention notes* in the report: one or two lines on the tradeoff, no
  severity, and no routing to a focused skill. Changing a convention — or anything that would
  require a different library — is a standards decision for the team, because it affects
  consistency across every project built from the same scaffold. Say so.

### Controls

Teams can adjust the baseline two ways. Request wording beats project settings, which beat
the defaults above.

- **Baseline audit mode.** If the user asks to "include the scaffold", "audit the template",
  "ignore the baseline", or run a "full scan", report baseline patterns as normal findings
  (they count toward the category ratings), prefixed `[baseline]` so readers know the fix
  belongs in the template or the team standard, not one project. Convention notes fold into the findings. Still don't recommend
  replacing a framework or library unless the user explicitly asks about library choice —
  and even then, frame it as an org standards decision.
- **Project settings.** If `CLAUDE.md` or `.github/copilot-instructions.md` has a
  `## Smell baseline` section, honor it:
  - `baseline: none` — behave as in audit mode for every request.
  - `ignore:` — paths or globs you never analyze or mention.
  - `conventions:` — extra patterns that are standard in this project; never report them.
  - `enforce:` — conventions the team decided to change; report violations as normal
    findings, not convention notes.

## How to scan

Read the code — whether a snippet, file, or directory. Sweep for signals of each category.
You're looking for *patterns*, not perfection. A function that's 25 lines with a clear single
purpose is fine. One that's 25 lines doing 5 different things is a Bloater.

For directories: prioritize core logic files (services, models, controllers) over config,
tests, and generated files. Note if you skipped anything significant.

Baseline patterns don't count toward a category's rating. Common ones that are *not* smells:
a thin controller or route that forwards to a service (not Middle Man), data-shaped schemas,
entities, and DTOs (not Data Class), the per-feature module / controller / service / DTO /
schema layering (not Shotgun Surgery or Parallel Hierarchies), and reducers that switch on
`action.type` (not Switch Statements).

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

[For each category rated Moderate or Severe, recommend the focused skill and why. Never
route for a convention alone.]

- Run **smell-bloaters** on [file/dir] — [one sentence on what it will find]
- Run **smell-dispensables** on [file/dir] — [one sentence on what it will find]

### Overall health
[2–3 sentences. What's the dominant problem? Is this code in urgent need of refactoring
or mostly clean with a few rough spots? What should the developer tackle first? If the code
is essentially the generated baseline, say so plainly.]

### Convention notes (not findings)
[Optional — omit if empty, or in baseline audit mode where these appear above as
`[baseline]` findings. Baseline conventions or library constraints that resemble a
smell, one or two lines each on the tradeoff. Not rated and not routed — changing these is a
team standards decision.]
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
