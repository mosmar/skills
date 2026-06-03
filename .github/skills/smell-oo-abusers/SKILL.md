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
data, or handle a fixed set of external codes (HTTP status codes, keyboard keys) is fine.
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
```

Always include before/after sketches for Switch Statement findings — the polymorphism
refactoring direction is the most important thing to show concretely in TypeScript.
