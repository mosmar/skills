---
name: smell-guard
description: >
  Use this skill whenever an agent is writing, editing, or refactoring code and should
  actively avoid introducing code smells. This is a coding standard skill — it shapes
  HOW code is generated, not just what it produces. Trigger when the user asks an agent
  to implement a feature, write a new class or service, refactor existing code, add a
  new method, or any task where code will be produced. Install in .claude/skills/ or
  .github/skills/ to apply these standards automatically to every coding task in a project.
  The agent reads these rules before writing and performs a self-check pass before
  presenting output. Do not use this skill for analysis-only tasks; use smell-scanner
  for detecting smells in existing code.
---

# Smell Guard — Agent Coding Standards

You are about to write or edit code. Read these rules, apply them as you write, and
run the self-check before presenting output. These rules cover all five smell categories
from the refactoring.guru catalog: Bloaters, OO Abusers, Change Preventers, Dispensables,
and Couplers.

---

## Bloaters — don't let things grow too large

**Long Method.** A function should do one thing, describable without "and." If you find
yourself writing section comments inside a body (`// validate`, `// calculate`, `// notify`),
stop — each section is a function. Extract immediately; name the function after what it does.

**Large Class.** Name the single responsibility before writing the class. If you can't name
it without "and", "manager", or "handler", you have two classes. A class with more than
~4 injected dependencies is almost always doing too much.

**Long Parameter List.** More than 3–4 parameters means introduce a parameter object.
Parameters that always travel together belong in a named type:
```typescript
createUser(details: UserDetails)          // not
createUser(email, firstName, lastName, role, birthDate)
```
Never use a boolean flag parameter to change behavior — that's two functions pretending to be one.

**Primitive Obsession.** Use types, not raw primitives, for domain concepts. A `string`
for an email, ID, phone number, monetary amount, status, or role carries no validation and
no meaning at the type level. Wrap them:
```typescript
type UserId = string & { readonly _brand: 'UserId' };
class EmailAddress { constructor(readonly value: string) {
  if (!value.includes('@')) throw new Error('Invalid email');
}}
```

**Data Clumps.** If the same 3+ values always appear together across multiple function
signatures or class fields, they belong in a named type. `firstName + lastName + email`
appearing everywhere is a `ContactInfo`. Extract it and use it consistently.

---

## Object-Orientation Abusers — apply OOP correctly

**Switch Statements.** Do not write `if/else if` chains or `switch` on a type, kind, role,
or status field if that pattern would be repeated in more than one place. Choose one:

- **Polymorphism** (variants have different behavior):
  ```typescript
  interface NotificationChannel { send(to: string, msg: string): Promise<void>; }
  class EmailChannel implements NotificationChannel { ... }
  class SmsChannel implements NotificationChannel { ... }
  // Adding a variant = one new class, zero if/else edits
  ```
- **Discriminated union + exhaustive switch** (variants are data-shaped):
  ```typescript
  switch (entity.type) {
    case 'A': return handleA(entity);
    case 'B': return handleB(entity);
    default: const _: never = entity; // compiler catches missing cases
  }
  ```
- **Strategy map** (simple, stable variants):
  ```typescript
  const handlers: Record<Type, (e: Entity) => Result> = { A: ..., B: ... };
  ```

A switch for a one-off mapping or formatting that will never be duplicated is fine.

**Temporary Field.** Never create a class field that is only valid after a specific method
is called. `this._result: Result | null = null` set in `process()` is a Temporary Field.
Return values from methods rather than storing intermediate state:
```typescript
// Instead of: parse() sets this._content, validate() reads it
async parse(): Promise<ParsedContent> { ... }
async validate(content: ParsedContent): Promise<ValidationResult> { ... }
```
If sequential state is genuinely needed, make it explicit with a discriminated union type
rather than nullable fields.

**Refused Bequest.** Do not create a subclass that overrides parent methods with empty
bodies or `throw new Error('Not supported')`. A subclass that won't honor the parent
contract should not extend it. Use composition or a more targeted interface instead:
```typescript
// Instead of extending a fat base and refusing half of it:
interface Printable { print(): void; }
class Report implements Printable { ... }  // only implements what it actually supports
```

**Alternative Classes with Different Interfaces.** If two classes do the same thing with
different method names (`getUser` vs `fetchUser`, `create` vs `add`), align them to a
shared interface. Inconsistent naming for the same concept doubles cognitive load for
every developer who uses both.

---

## Change Preventers — design for change

**Divergent Change.** Each class should have one reason to change. If you notice you're
writing methods that cluster around two unrelated concerns (auth AND reporting, payments
AND notifications), extract the second concern into its own class now, before the
entanglement grows.

**Shotgun Surgery.** Do not scatter a single concept across many files. If adding a field,
a rule, or a new variant would require editing 5+ files, that concept needs a home. Ask:
"where is the single place this should live?" and put it there. Thin repetitive layers
(Model → DTO → Mapper → Validator all with the same fields) accumulate Shotgun Surgery debt.

**Parallel Inheritance Hierarchies.** Do not create two class hierarchies that must grow
in lockstep. If every `XxxNotification` requires a matching `XxxHandler`, that's a
parallel hierarchy. Merge the behavior — let each `Notification` know how to handle itself,
or use a registration pattern instead of mirrored hierarchies.

---

## Dispensables — if it doesn't earn its place, remove it

**Duplicate Code.** Write the logic once. If you find yourself copy-pasting a block with
minor variations, extract a shared function with the variation as a parameter. Two copies
of logic means two places for bugs and two places to update.

**Lazy Class.** Do not create a class with only one non-trivial method or that exists
purely to wrap a single call. Every class adds cognitive overhead — it must justify that
cost. If the class doesn't encapsulate a meaningful concept, inline it into its caller.

**Data Class.** Do not create classes with only fields and getters/setters and no behavior.
If you're building a class whose data is always manipulated by external methods in other
classes, move that behavior in. Objects should own their own invariants and transformations.

**Dead Code.** Do not leave dead code behind — no commented-out blocks, no methods marked
"unused", no `TODO: remove this`. Delete it. Version control remembers it.

**Speculative Generality.** Do not add abstractions, parameters, hooks, or extension points
"for future use." If there is currently one implementation, do not add an abstract base
class or interface for theoretical future implementations. Add the abstraction when the
second real case exists. YAGNI.

**Comments (as a smell).** Do not write comments that describe *what* code does. Write
code that is self-describing. `// loop through items and sum totals` means extract a method
named `sumItemTotals()`. Reserve comments for *why* — non-obvious decisions, constraints,
gotchas — never mechanics. Never leave commented-out code in output.

---

## Couplers — keep things from getting tangled

**Feature Envy.** If a method uses another object's data more than its own, it belongs in
that object. A method in `PricingService` that reads `order.items`, `order.customer`, and
`order.promoCode` belongs on `Order`. Move it.

**Inappropriate Intimacy.** Do not write classes that reach into each other's internals.
If class A needs to access implementation details of class B that aren't part of B's public
contract, add a method to B that exposes what A needs without exposing how it works. Two
classes that must always change together are inappropriately intimate.

**Message Chains.** Do not chain more than one hop through object relationships:
```typescript
// Bad — coupled to three layers of internal structure
order.getCustomer().getAddress().getCity()

// Good — hide the navigation behind a method
order.getShippingCity()
```
If you need data that's three objects deep, add a method on the nearest object.

**Middle Man.** Do not create a class whose primary job is forwarding calls to another
class. If every method is a one-liner delegating to a single dependency, the class adds
indirection without value. Either inline it or give it real responsibilities of its own.

---

## When editing code that already has smells

Do not silently spread an existing bad pattern. If the code you're editing contains a
smell and the user's request requires you to extend it:

1. Fulfill the request — add what was asked for
2. Flag the smell explicitly in your response
3. Show what the refactored version would look like

Example: asked to add a new case to an existing if/else chain on type → add the case,
then note "this switch is a candidate for Replace Conditional with Polymorphism" and
sketch the cleaner structure.

---

## Self-check before presenting output

- [ ] Every function does one thing — no section comments inside bodies
- [ ] Every class has one named responsibility — no "and" in the description
- [ ] No if/else chains on type/kind/role that will need to be duplicated
- [ ] No nullable fields that depend on method call order
- [ ] No primitives standing in for domain concepts (emails, IDs, statuses, money)
- [ ] No groups of 3+ primitives that always travel together (Data Clumps)
- [ ] No subclass that refuses what it inherits
- [ ] No two classes doing the same thing with different method names
- [ ] No class or method with too many responsibilities (Divergent Change risk)
- [ ] No concept scattered across 5+ files when it should have one home
- [ ] No parallel class hierarchies growing in lockstep
- [ ] No duplicate logic — each piece of knowledge has exactly one home
- [ ] No class too thin to justify its existence
- [ ] No data-only class with all behavior pushed into its callers
- [ ] No dead code or commented-out blocks
- [ ] No speculative abstractions or unused extension points
- [ ] No what-not-why comments
- [ ] No method chains longer than one hop
- [ ] No methods using another object's data more than their own
- [ ] No classes reaching into each other's internals
- [ ] No class that only exists to forward calls to another

If a check fails and you have latitude to fix it, fix it. If the user's request constrains
you, implement what was asked and flag the smell.
