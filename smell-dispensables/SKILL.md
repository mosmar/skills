---
name: smell-dispensables
description: >
  Use this skill for a deep analysis of Dispensable code smells — unnecessary code whose
  absence would make the codebase cleaner, faster to read, and easier to maintain. Trigger
  on phrases like "dead code", "duplicate code", "unnecessary code", "clean up this file",
  "what can I delete", "we have a lot of code that does the same thing", "speculative
  abstractions", "this class doesn't do much", or when smell-scanner has rated Dispensables
  as Moderate or Severe. Also trigger when the user says a file "feels bloated but not in
  an obvious way" — Dispensables are often the culprit. Works with snippets, single files,
  or directories. The output is a findings report with specific deletion or consolidation
  guidance for each dispensable found.
---

# Smell: Dispensables

You are performing a focused deep-dive on Dispensable smells — code that is pointless,
redundant, or vestigial. The unifying theme of this category is that the fix is almost
always some form of **removal**: delete it, inline it, or merge it into something that
already earns its place.

This is often the most immediately satisfying refactoring category because the payoff is
instant: less code to read, less code to maintain, less code to break.

## The six Dispensable smells

### 1. Comments (as a smell)
This is the most nuanced one — comments aren't inherently bad. The smell is a specific
kind of comment: one that explains *what* the code does rather than *why*. If a comment
describes the mechanics of the code next to it, that's a signal the code isn't
self-explanatory. The fix is to make the code explain itself, then delete the comment.

**Comments that ARE smells:**
- `// loop through users and check their status` (just describes the for loop below it)
- `// calculate total` above a block of arithmetic
- Section divider comments (`// --- Validation ---`, `// Step 1: Fetch data`) that signal a Long Method in disguise
- Commented-out code left "just in case"
- TODO/FIXME comments more than a few weeks old (they're either dead code or unresolved debt)

**Comments that are NOT smells:**
- Why a non-obvious decision was made (`// using linear scan here because N is always < 10`)
- Warnings about gotchas (`// note: this mutates the input array`)
- External constraint explanations (`// API requires snake_case keys`)
- Public API documentation

**Named refactoring techniques:**
- **Rename Method / Rename Variable** — if a comment explains what a function or variable does, a better name removes the need for the comment.
- **Extract Method** — if a comment labels a block of code, that block should be a named method.

### 2. Duplicate Code
The same logic appearing in more than one place. When a bug is fixed in one copy but not
the others, or when behavior needs to change and the developer doesn't know how many copies
exist, the codebase becomes unreliable.

**What to look for:**
- Identical or near-identical blocks of code in multiple methods or classes
- Methods that differ only in one small parameter or condition
- Copy-pasted logic with minor variations (a sign that the variation should be a parameter)
- The same validation or transformation logic scattered across multiple entry points

**Named refactoring techniques:**
- **Extract Method** — consolidate into a shared function called by both sites.
- **Extract Class** — if the duplication spans multiple methods that belong together, a new class may be the home.
- **Form Template Method** — when two methods do the same steps in the same order but with different implementations, move the structure to a base class and override the parts that differ.
- **Substitute Algorithm** — if two implementations do the same thing differently, pick the cleaner one and replace both.

### 3. Lazy Class
A class that doesn't do enough to justify its existence. Every class adds cognitive overhead —
a name to remember, a file to navigate to, an abstraction to understand. If a class has only
one or two methods, barely any fields, and doesn't meaningfully encapsulate anything, it's
probably not pulling its weight.

**What to look for:**
- Classes with only one non-trivial method
- Classes that exist purely to wrap a single function call
- Very thin subclasses that add nothing to the parent
- Abstract classes or interfaces with only one concrete implementation (especially if that implementation is simple)

**Named refactoring techniques:**
- **Inline Class** — move the class's contents into its only caller or into a related class, then delete it.
- **Collapse Hierarchy** — if a subclass barely differs from its parent, merge them.

### 4. Data Class
A class with fields, getters, and setters — but no real behavior. Data classes are often a
sign that behavior that belongs to the class has leaked out into other classes that manipulate
its data. The fix isn't usually to delete the class, but to move behavior in.

**What to look for:**
- Classes with only `get`/`set` methods and no logic
- Classes whose data is always manipulated by the same external methods in another class
- DTO/ViewModel classes that have grown validation or transformation logic in their callers

**Named refactoring techniques:**
- **Move Method** — find methods in other classes that primarily work on this class's data and move them here.
- **Encapsulate Field** — replace public fields with proper accessors to enable future behavior.
- **Remove Setting Method** — if a field is only set at construction, make it immutable.

**Calibration note:** Not every data class is a smell. DTOs, request/response objects, and
value objects at system boundaries are often appropriately data-only. The smell applies when
a class *should* have behavior but has outsourced it all.

### 5. Dead Code
Code that is never executed — unreachable branches, uncalled functions, unused variables,
orphaned classes. Dead code is pure noise: it costs reading time with no benefit, and it
creates false impressions of what the system does.

**What to look for:**
- Functions or methods that are never called (check for usages, not just the definition)
- Variables declared but never read
- Branches that can never be reached (`if (false)`, conditions that are always true/false given the type)
- Parameters that are always passed the same value, or ignored entirely
- Classes that are never instantiated
- Code after unconditional returns
- Commented-out code (treat as dead — if it were needed, it would be in version control)

**Named refactoring techniques:**
- Just delete it. If it's needed again, version control has it.
- **Remove Parameter** — if a function parameter is always ignored or always the same value.

### 6. Speculative Generality
Code written for a future that never arrived. Abstractions, parameters, hooks, and extension
points added "just in case we need to support X someday." This code adds complexity now in
exchange for a flexibility that may never be needed — or that will need to be redesigned
anyway when the real requirement arrives.

**What to look for:**
- Abstract classes or interfaces with only one concrete implementation (and no near-term plans for more)
- Parameters that are always `null`, `false`, or a default value at every call site
- Configuration flags that are never toggled from their default
- Hook methods (onBeforeX, onAfterX) that are never overridden
- Generic/template code that's only ever used with one type
- Comments like "// for future use", "// will support multi-tenant later"

**Named refactoring techniques:**
- **Collapse Hierarchy** — merge the abstract class and its single implementation.
- **Inline Class** — if the abstraction exists only to support theoretical extension, inline it.
- **Remove Parameter** — if a parameter is always the same value, bake in the default and remove it.
- **Rename Method** — if a method is named for generality it doesn't use (`processEntity` vs `processOrder`), rename it.

## How to approach the analysis

Dispensables are often subtle — the code works fine, it's just unnecessary. Approach the
analysis with a skeptic's eye: *does this earn its place?* For each comment, ask if the
code could speak for itself. For each class, ask if it justifies the cognitive overhead.
For each abstraction, ask if the flexibility is actually used.

For **dead code** in particular: be careful about concluding something is unused from a
snippet alone. Note when you can't confirm call sites from the provided code, and recommend
the developer search for usages before deleting.

## Output format

```
## Dispensables Analysis — [filename or directory]

### Summary
[2–3 sentences: how much unnecessary code is present, which smells dominate, and the
rough cleanup effort]

### Findings

#### [Smell type] — [Short title]
- **Location**: `path/to/file.ts`, lines N–M (or `ClassName.method()`)
- **Why it's dispensable**: [Specific explanation]
- **Refactoring**: [Named technique] — [Concrete action: what to delete, inline, rename, or merge]
- **Effort**: Low / Medium / High
- **Caveat** (if needed): [e.g., "confirm no external callers before deleting"]

[Repeat for each finding]

---
### Cleanup order
[Start with dead code and commented-out blocks — pure removals with no downside.
Then duplicates — pick the canonical version, update callers. Then lazy/speculative
abstractions. Data class behavior-migration last since it requires design judgment.]
```

## Tone

Be direct. The recommendation for most Dispensables is "delete this" — say so without
hedging. The one exception is dead code where call sites can't be confirmed from the
snippet; flag those with a "verify before deleting" caveat. Don't pad findings with
philosophical discussion about why comments can sometimes be useful — the developer knows.
