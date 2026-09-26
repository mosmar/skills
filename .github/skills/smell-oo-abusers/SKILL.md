---
name: smell-oo-abusers
description: >
  Use this skill for a deep analysis of Object-Orientation Abuser smells in JavaScript and
  TypeScript code — cases where OOP principles are misapplied or violated. Trigger on phrases
  like "big switch statement", "if-else chain on type", "this field is only used sometimes",
  "subclass that ignores the parent", "two classes doing the same thing differently", "replace
  conditional with polymorphism", or when smell-scanner has rated OO Abusers as Moderate or
  Severe. Focused on JS/TS patterns: class hierarchies, discriminated unions, type guards,
  and the specific ways OOP is misused in modern TypeScript codebases. Works with snippets,
  single files, or directories.
---

# Smell: Object-Orientation Abusers (JavaScript / TypeScript)

You are performing a focused deep-dive on OO Abuser smells in JavaScript and TypeScript —
cases where object-oriented principles are incompletely or incorrectly applied.

These smells share a root cause: behavior that should be encoded in the type system or class
hierarchy is instead handled through conditional logic, optional fields, or inconsistent
interfaces. The code works, but it's fragile — adding a new variant means finding and
updating every `switch`, every optional field check, every caller that handles the difference.

TypeScript gives you powerful tools to eliminate these smells — discriminated unions, abstract
classes, interfaces, generics — and this skill will point you toward the right one for each
case.

## The four OO Abuser smells

### 1. Switch Statements (and if/else chains on type)
A `switch` or `if/else if` chain that dispatches on a type, status, kind, or role field to
decide what behavior to execute. Every time a new variant is added, every such switch in the
codebase must be found and updated — and the compiler won't tell you if you missed one.

**Signals to look for in JS/TS:**
- `switch (entity.type)` or `if (x.kind === 'A') ... else if (x.kind === 'B')`
- String or numeric literals used as type discriminators across multiple places
- The same `switch` structure duplicated in more than one file
- `typeof`, `instanceof`, or custom `isX()` type guards used to branch on behavior
- A `type` or `kind` field on an object that determines which methods are valid

**Named refactoring techniques:**
- **Replace Conditional with Polymorphism** — create a class or interface per variant, move
  each branch into the corresponding class's method. The switch disappears.
- **Replace Type Code with Class** — replace the string/number type discriminator with a
  proper TypeScript class or discriminated union type.
- **Replace Type Code with Subclasses** — if variants have meaningfully different behavior,
  each becomes a subclass of a shared abstract base.

**TypeScript-specific approach:**
When full polymorphism is overkill, TypeScript's discriminated unions with exhaustive checks
are a clean middle ground:
```typescript
// Instead of: if (notif.type === 'email') ... else if (notif.type === 'sms') ...
type Notification = EmailNotification | SmsNotification | PushNotification;
// Use a type-narrowing handler per variant, enforced by the compiler
```
Always prefer exhaustive `switch` with a `never` default assertion over open-ended `if/else`
chains — the compiler will catch missing cases.

**Calibration:** Not every `switch` is a smell. Switching on a value to format output, map
data, handle a fixed set of external codes (HTTP status codes, keyboard keys), or dispatch
actions in a reducer is fine.
The smell is a `switch` on a *domain type* that determines *behavior* — especially when
that switch appears in more than one place.

### 2. Temporary Field
A class field that is only meaningful in certain circumstances — null or undefined most of
the time, only populated when the object is in a particular state. This creates objects whose
validity depends on runtime state the type system can't see, making them error-prone to use.

**Signals to look for in JS/TS:**
- Fields typed as `T | null` or `T | undefined` that aren't genuinely optional
- Fields set only inside specific methods and never in the constructor
- TypeScript classes where some methods only work after calling an `init()` or `load()` method
- Fields that are only populated in certain subclass constructors
- Properties with names like `tempResult`, `cachedValue`, `_internalState` that are set
  mid-process and read later

**Named refactoring techniques:**
- **Extract Class** — move the temporary fields and the methods that use them into a separate
  class that only exists when those fields are valid.
- **Introduce Null Object** — replace nullable fields with a Null Object that implements the
  same interface but does nothing, eliminating null checks throughout.
- **Replace Temp with Query** — if the field holds a computed value, make it a getter that
  computes on demand instead of a field that must be set at the right time.

**TypeScript-specific approach:**
Leverage TypeScript's type system to make state explicit:
```typescript
// Instead of: class Processor { result: Result | null }
// Use a state machine type:
type ProcessorState =
  | { status: 'idle' }
  | { status: 'complete'; result: Result };
```
This makes invalid states unrepresentable rather than just runtime-checked.

### 3. Refused Bequest
A subclass that inherits from a parent but ignores or overrides most of what it inherits —
or actively throws errors on inherited methods it doesn't support. The subclass is using
inheritance for code reuse but doesn't actually satisfy the parent's contract.

**Signals to look for in JS/TS:**
- A subclass that overrides several parent methods with empty bodies or `throw new Error('Not supported')`
- A subclass that only uses 1–2 of the parent's 6+ methods
- TypeScript classes where `super.method()` is never called in any override
- A base class with many methods where each subclass only implements a subset
- Interfaces that are implemented with `// TODO` stubs or no-op bodies

**Named refactoring techniques:**
- **Replace Inheritance with Delegation** — instead of extending the parent, hold a reference
  to it. Use only what you need.
- **Extract Interface** — define a minimal interface with only the methods the subclass
  actually supports, and have it implement that instead.
- **Push Down Method** — move the methods the subclass doesn't use out of the base class and
  into only the subclasses that need them.

**TypeScript-specific approach:**
Prefer composition and interfaces over deep class hierarchies. TypeScript's structural typing
means you rarely need inheritance for polymorphism — an interface is usually enough.

### 4. Alternative Classes with Different Interfaces
Two or more classes that do the same thing but have different method names, signatures, or
structures — so they can't be used interchangeably even though they should be. This often
happens when different developers built similar things without coordination.

**Signals to look for in JS/TS:**
- Two service classes with methods like `getUser` vs `fetchUser`, `create` vs `add`, `remove` vs `delete`
- Two data-fetching classes with the same pattern but different method names or return shapes
- Two error-handling classes that both represent errors but have different fields (`message` vs `errorMessage`, `code` vs `statusCode`)
- Duplicate TypeScript interfaces that express the same concept differently
- Two adapters for the same external service written by different people

**Named refactoring techniques:**
- **Rename Method** — align the method names to a shared convention.
- **Extract Interface** — define the shared interface both classes should implement.
- **Move Method** — if one class has the right interface and the other doesn't, move the
  duplicate logic into the correctly-named class.

## Respect the project baseline

The project's frameworks, libraries, and generated scaffold are the standard you measure
against — not the subject of the review. Teams move between projects built from the same
scaffold, so consistency with it outweighs any individual refactoring.

- **Never recommend replacing a framework or library.** Don't suggest swapping the data layer
  (Mongoose, TypeORM, Prisma, Sequelize, knex, mssql), the web framework (Express, NestJS,
  Angular), or the validation, logging, HTTP, state-management, or test library — and never an
  architecture migration such as Express → NestJS. Every refactoring you propose must use what
  the project already has.
- **Generated scaffold code is the clean baseline.** If the project was generated from an
  organization template or CLI, the structure it produces — per-feature module / controller /
  service / DTO / schema files, gateway wiring, standard folders, base classes, placeholder
  files — is not a finding, even where it resembles a smell. A freshly generated project should
  come out clean.
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
  severity or effort, and not part of the refactoring order. Changing a convention — or
  anything that would require a different library — is a standards decision for the team,
  because it affects consistency across every project built from the same scaffold. Say so.

### Controls

Teams can adjust the baseline two ways. Request wording beats project settings, which beat
the defaults above.

- **Baseline audit mode.** If the user asks to "include the scaffold", "audit the template",
  "ignore the baseline", or run a "full scan", report baseline patterns as normal findings
  with severity and effort, prefixed `[baseline]` so readers know the fix belongs in the template or the team
  standard, not one project. Convention notes fold into the findings. Still don't recommend
  replacing a framework or library unless the user explicitly asks about library choice —
  and even then, frame it as an org standards decision.
- **Project settings.** If `CLAUDE.md` or `.github/copilot-instructions.md` has a
  `## Smell baseline` section, honor it:
  - `baseline: none` — behave as in audit mode for every request.
  - `ignore:` — paths or globs you never analyze or mention.
  - `conventions:` — extra patterns that are standard in this project; never report them.
  - `enforce:` — conventions the team decided to change; report violations as normal
    findings, not convention notes.

**OO Abuser-specific baseline calibration:**
- **Switch Statements** — switches the framework or state library expects are not smells:
  reducers that switch on `action.type`, error-mapping middleware and exception filters,
  microservice message-pattern dispatch, HTTP status mapping.
- **Refused Bequest** — implementing framework lifecycle interfaces (`OnInit`,
  `OnModuleInit`, `CanActivate`) or extending a scaffold base class with no-op hooks is
  convention, not a refused bequest.
- **Alternative Classes** — align names to the convention the project already uses
  (`findAll` / `findOne` / `create` if that's what the scaffold generates), not a new one.
- **Fix style** — propose polymorphism, discriminated unions, or strategy maps in the style
  the codebase already uses. Don't introduce a class hierarchy into code that is
  consistently functional, or vice versa.

## Output format

```
## OO Abusers Analysis — [filename or directory]

### Summary
[2–3 sentences: which smells are present, how pervasive, and the dominant fix direction]

### Findings

#### [Smell type] — [Short title]
- **Location**: `ClassName.methodName()` or `path/to/file.ts`
- **The problem**: [Specific description of the misapplied OOP pattern]
- **Why it hurts**: [What becomes painful as the codebase grows]
- **Refactoring**: [Named technique] — [Concrete TypeScript-specific guidance]
- **Effort**: Low / Medium / High
- **Before sketch**:
  ```typescript
  [relevant snippet]
  ```
- **After sketch**:
  ```typescript
  [how it looks post-refactor, using TypeScript features where appropriate]
  ```

---
### Refactoring order
[Which to tackle first. Switch Statements are usually highest priority — they spread. Refused
Bequest and Alternative Classes are often lower effort. Temporary Field depends on severity.]

### Convention notes (not findings)
[Optional — omit if empty, or in baseline audit mode where these appear above as
`[baseline]` findings. Baseline conventions or library constraints that resemble a
smell, one or two lines each on the tradeoff. No severity or effort, not in the refactoring
order — changing these is a team standards decision.]
```

Always include before/after sketches for Switch Statement findings — the polymorphism
refactoring direction is the most important thing to show concretely in TypeScript.
