---
name: smell-bloaters
description: >
  Use this skill for a deep analysis of Bloater code smells — things that have grown too
  large to work with comfortably. Trigger when the user asks about "long methods", "large
  classes", "too many parameters", "functions doing too much", "primitive obsession", "data
  clumps", or when smell-scanner has rated Bloaters as Moderate or Severe and recommended
  this skill. Also trigger on general requests like "this function is too big, help me break
  it down" or "this class has too many responsibilities". Works with snippets, single files,
  or directories. The output is a detailed findings report with named refactoring techniques
  and concrete before/after guidance for each bloater found.
---

# Smell: Bloaters

You are performing a focused deep-dive analysis of Bloater smells — code that has grown so
large it's become painful to read, test, and change. Your job is to find every bloater,
explain exactly why it's a problem, name the specific refactoring technique that fixes it,
and give concrete guidance on how to apply it.

## The five Bloater smells

### 1. Long Method
A method that has grown beyond a single clear responsibility. Length alone isn't the smell —
a 40-line method with one clear job can be fine. The smell is a method doing multiple things:
validating input, computing something, talking to a database, sending a notification, all in
one function. The reader has to hold the whole thing in their head at once.

**Signals to look for:**
- Multiple levels of abstraction mixed together (low-level DB calls next to high-level business logic)
- Comments that label sections within the method (a sign it should be split)
- Deep nesting (>3 levels) that tracks multiple independent concerns
- More than one reason for the method to change

**Named refactoring techniques:**
- **Extract Method** — pull a coherent chunk into its own named function. The name of the extracted method should describe *what* it does, not *how*.
- **Replace Temp with Query** — if a local variable is computed once and used later, extract the computation into a method.
- **Decompose Conditional** — extract complex condition logic and its branches into well-named methods.
- **Replace Method with Method Object** — when a method has many local variables that interact, turn it into a class where each variable becomes a field.

**Heuristic:** If you can't describe what a method does in one short sentence without using "and", it probably needs splitting.

### 2. Large Class
A class that has taken on too many responsibilities. Signs: many unrelated fields, clusters
of methods that only use a subset of the fields, methods that would make more sense on a
different object.

**Signals to look for:**
- Fields that cluster into groups — some methods use fields A/B/C, others use D/E/F, they never mix
- God objects that know about everything (User class with auth, profile, billing, preferences all in one)
- Classes named with vague words like Manager, Processor, Handler, Service (sometimes a sign of responsibility accumulation)
- Very high method count (>15-20 public methods on a non-trivial class)

**Named refactoring techniques:**
- **Extract Class** — move a coherent cluster of fields and methods into a new class.
- **Extract Subclass** — if some features are only used in some cases, a subclass may be appropriate.
- **Extract Interface** — identify distinct behavioral contracts the class fulfills and formalize them.

### 3. Primitive Obsession
Using primitive types (string, int, bool, float) to represent domain concepts that deserve
their own type. A string for an email address carries no validation. An int for money risks
precision errors. A boolean flag for a concept with more than two states will inevitably
grow into three.

**Signals to look for:**
- Strings used for emails, URLs, phone numbers, IDs, currency codes, statuses, roles
- Numbers used for money (float/double), percentages, distances without units
- Parallel primitives that always travel together (firstName + lastName + email)
- Boolean flags that encode state: `isActive`, `isPremium`, `isBanned` (three booleans = 8 possible states, most invalid)
- Magic strings/numbers used for type discrimination (`type === 'admin'`, `status === 3`)

**Named refactoring techniques:**
- **Replace Data Value with Object** — wrap the primitive in a class with validation and behavior.
- **Replace Type Code with Class** — replace a string/int type discriminator with a proper class or enum.
- **Introduce Parameter Object** — when several primitives always travel together, make them a class.
- **Replace Array with Object** — when an array's positions have meaning (`arr[0]` = name, `arr[1]` = email), make it a struct/object.

### 4. Long Parameter List
A function or method that takes so many parameters it's hard to call correctly, hard to
read at the call site, and hard to change without breaking callers.

**Signals to look for:**
- More than 3–4 parameters (especially if they're all primitives)
- Parameters that always appear together at every call site
- Boolean flag parameters that change behavior (`doThing(id, true, false, true)`)
- Parameters that come from the same object — the caller is decomposing an object to pass its parts

**Named refactoring techniques:**
- **Introduce Parameter Object** — replace a cluster of parameters that travel together with a single object.
- **Preserve Whole Object** — instead of extracting three fields from an object to pass them, pass the object itself.
- **Replace Parameter with Method Call** — if a parameter could be computed by calling a method the receiver already knows about, eliminate the parameter.

### 5. Data Clumps
Groups of data items that always appear together — in method signatures, as fields in
multiple classes, or in variable declarations — but haven't been given their own type.
If you removed one item from the group, the others would lose their meaning.

**Signals to look for:**
- The same 3+ parameters appearing together across multiple method signatures
- The same set of fields appearing in two or more classes
- Variables always declared and used together
- Clusters that have a natural name (firstName + lastName + email → `ContactInfo`)

**Named refactoring techniques:**
- **Extract Class** — give the clump a home. The resulting class often naturally attracts related behavior too.
- **Introduce Parameter Object** — when the clump appears in method signatures.

## How to approach the analysis

Read the code methodically. For each class and method, ask:
- Does this method do one thing? Could I describe it in a short sentence without "and"?
- Are these fields and methods cohesive, or do they cluster into separate concerns?
- Are there primitives that are doing the work of a domain type?
- Are there parameter lists that always travel together?

Be precise about location: name the class, method, and if possible line range. Vague findings
("this class is too large") are not actionable. Specific findings ("the `UserService` class
has 23 methods split across three concerns: auth (lines 12–67), profile (lines 70–134), and
billing (lines 137–201) — extract into `AuthService`, `UserProfileService`, and
`BillingService`") are.

## Output format

```
## Bloater Analysis — [filename or directory]

### Summary
[2–3 sentences on overall bloat level and dominant smell type]

### Findings

#### [Smell type] — [Short title]
- **Location**: `ClassName.methodName()` or `path/to/file.ts`, lines N–M
- **Why it's a problem**: [Specific explanation — what makes this hard to work with]
- **Refactoring**: [Named technique] — [Concrete guidance: what to extract, what to name it]
- **Effort**: Low / Medium / High
- **Before sketch** (if helpful):
  ```
  [relevant snippet showing the smell]
  ```
- **After sketch** (if helpful):
  ```
  [how it looks post-refactor]
  ```

[Repeat for each finding]

---
### Refactoring order
[Numbered list: which to tackle first and why — usually ordered by impact/effort ratio]
```

Include before/after sketches for findings where the refactoring direction isn't obvious.
Omit them when the technique name is self-explanatory and the code is clear.

## Calibration

Not every long method is a bloater. A 50-line method that builds a complex SQL query step
by step, with clear intermediate variable names, may be perfectly readable. Judge by
comprehensibility and maintainability, not raw line count. Say so when something looks long
but is actually fine — it saves the developer from unnecessary refactoring.
