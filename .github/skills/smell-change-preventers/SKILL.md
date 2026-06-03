---
name: smell-change-preventers
description: >
  Use this skill for a deep analysis of Change Preventer smells — structural problems that
  make every future code change more expensive than it should be. Trigger on phrases like
  "every time I change X I have to change Y too", "shotgun surgery", "divergent change",
  "this class changes for too many reasons", "parallel class hierarchies", "changes ripple
  everywhere", "hard to add a new feature without touching everything", or when smell-scanner
  has rated Change Preventers as Moderate or Severe. This skill requires multiple files to
  be genuinely useful — single-file analysis can identify suspects but not confirm patterns.
  Works best with a directory or a set of related files. Output is a structural diagnosis
  with a refactoring plan.
---

# Smell: Change Preventers

You are performing a focused deep-dive on Change Preventer smells — structural problems that
mean a single logical change requires modifying many places in the codebase. These are the
smells that make developers dread adding features, because every change spawns a cascade of
required edits across multiple files.

Unlike other smell categories, Change Preventers are almost impossible to detect from a single
file. They're patterns that only become visible across the whole codebase. If given a single
file, you can identify *suspects* — patterns that would cause cascading changes if they scale —
but flag clearly that a multi-file view is needed to confirm.

## The three Change Preventer smells

### 1. Divergent Change
A class that has to be modified for multiple unrelated reasons. Every time a new payment
method is added, you edit this class. Every time a report format changes, you edit this class.
Every time a notification channel is added, you edit this class. The class has too many
reasons to change — it's violating the Single Responsibility Principle.

This is the inverse of Shotgun Surgery: one class, many reasons to change.

**Signals to look for:**
- A class with methods that cluster into two or more clearly unrelated groups
- A class that appears in the git log under multiple unrelated feature branches
- Comments or regions in a file that label distinct conceptual areas (`// --- Payment handling ---`, `// --- Reporting ---`)
- Large service or manager classes (UserManager, OrderService, AppController) that grew by accretion
- A class that multiple different teams or developers routinely edit for their own separate concerns

**Named refactoring techniques:**
- **Extract Class** — identify the distinct responsibilities and split them into separate classes,
  each with one reason to change.
- **Extract Module/Package** — for larger-scale divergence, the separation may need to be at
  the module or package boundary.

**How to diagnose it:** Look for methods that group naturally around different data or different
stakeholders. Ask: "If I were adding a new payment method, which methods would I touch? If I
were adding a new report type, which methods would I touch?" If the answers are different
subsets of the same class, it's divergent.

### 2. Shotgun Surgery
A single logical change that requires making small edits to many different classes. Adding a
new field to User means updating the User class, the UserDTO, the UserMapper, the UserValidator,
the UserRepository, the UserSerializer, and two test fixtures. The logic is scattered.

This is the inverse of Divergent Change: one reason to change, many classes.

**Signals to look for:**
- Adding a field or capability requires touching 5+ files
- The same concept (a field name, a constant, a validation rule) is duplicated across many files
- Thin layer classes that each touch the same concept: Model → DTO → Mapper → Validator → Serializer
- Copy-pasted configuration, error handling, or transformation logic spread across many files
- Multiple files that all import and re-export the same constant or type
- Parallel structures where every file in a folder has the same shape (class, test, fixture, mock)
  and adding anything means updating all of them

**Named refactoring techniques:**
- **Move Method / Move Field** — centralize the scattered logic in one place.
- **Extract Class** — if multiple classes are all touching the same concern, consolidate them.
- **Inline Class** — sometimes the fix is to collapse an unnecessary layer rather than add another.

**How to diagnose it:** Ask: "If I need to add X to this system, which files do I touch?"
If the answer is 5+ files for a conceptually simple addition, that's Shotgun Surgery.

### 3. Parallel Inheritance Hierarchies
Every time you add a subclass in one hierarchy, you have to add a corresponding subclass in
another. `Dog` requires `DogTrainer`. `Car` requires `CarInsurancePolicy`. `PaymentMethod`
requires `PaymentMethodSerializer`. The hierarchies are growing in lockstep.

**Signals to look for:**
- Two class hierarchies with the same shape — same number of subclasses, same names with
  different prefixes/suffixes (EmailNotification + EmailNotificationHandler,
  SmsNotification + SmsNotificationHandler)
- Factory methods that return pairs of related objects
- A method in one hierarchy that always creates an instance from the other hierarchy
- Folders that mirror each other's structure (models/ and serializers/ with the same filenames)
- `switch` statements in one hierarchy that are duplicated in the other

**Named refactoring techniques:**
- **Move Method** — if one hierarchy is primarily serving the other, merge the behavior into the
  first. Eliminate the second hierarchy.
- **Use objects from one hierarchy in the other** — instead of parallel hierarchies, have one
  hierarchy hold references to objects from the other (composition over parallel inheritance).

## How to approach the analysis

Change Preventers require a panoramic view. Your process:

1. **Survey the structure** — understand the module/folder layout, the major class boundaries,
   and how the code is organized before looking for patterns.

2. **Look for parallel structures** — same-named files in different folders, classes with
   matching prefixes/suffixes, hierarchies that mirror each other.

3. **Trace a hypothetical change** — pick a representative feature addition (a new payment
   method, a new user role, a new report type) and trace which files would need to change.
   Count them. Identify the pattern.

4. **Identify the responsible structure** — is it a class with too many responsibilities
   (Divergent Change), a concept scattered across too many files (Shotgun Surgery), or two
   hierarchies growing together (Parallel Hierarchies)?

**If given a single file:** Identify patterns that would become Change Preventers at scale —
a class that handles multiple unrelated concerns, constants duplicated from elsewhere, thin
transformation layers. Flag these as *suspected* Change Preventers and recommend a multi-file
scan to confirm.

## Output format

```
## Change Preventers Analysis — [directory or set of files]

### Structure overview
[3–5 sentences mapping the codebase structure: modules, major classes, how things are organized.
This gives the reader confidence you understood the layout before diagnosing.]

### Smells found

#### [Smell type] — [Short title]
- **Scope**: [Which files/classes are involved]
- **The pattern**: [Specific description of the change-preventing structure]
- **The cost**: [What a concrete example change would require — name the files that would
  need to be touched]
- **Refactoring**: [Named technique] — [Structural guidance: what to merge, split, or move]
- **Effort**: Medium / High (Change Preventers are rarely Low effort — they're structural)
- **Confidence**: Confirmed (seen across files) / Suspected (single-file analysis)

---
### Hypothetical change trace
[Pick the most illustrative example: "To add a new payment method, you would currently need
to edit: [list the files]. After refactoring, you would edit: [list the files]."]

### Refactoring order
[Change Preventers usually require careful sequencing. Recommend which to address first and
warn about any dependencies between the fixes.]
```

## Tone

Be concrete about the blast radius. "Adding a new notification channel currently requires
touching 7 files" is more compelling than "there is Shotgun Surgery here." Name the files.
Trace the change. Make the cost visible.
