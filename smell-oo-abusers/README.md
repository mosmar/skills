# smell-oo-abusers

Deep-dive analysis of Object-Orientation Abuser smells in JavaScript and TypeScript —
cases where OOP principles are misapplied, leaving code fragile and hard to extend.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

## The four OO Abuser smells (JS/TS focus)

Based on the [refactoring.guru OO Abusers catalog](https://refactoring.guru/refactoring/smells/oo-abusers):

| Smell | Signal | Fix |
|---|---|---|
| **Switch Statements** | `if/else` chain on a type/kind field, duplicated in multiple places | Replace Conditional with Polymorphism, discriminated unions |
| **Temporary Field** | Class fields that are `null` until a specific method is called | Extract Class, state machine type, Replace Temp with Query |
| **Refused Bequest** | Subclass throws `Not implemented` or ignores most of the parent | Extract Interface, Replace Inheritance with Delegation |
| **Alternative Classes** | Two classes do the same thing with different method names | Rename Method, Extract Interface |

## TypeScript-specific approach

This skill leans into TypeScript's type system for its recommendations — discriminated unions
with exhaustive `never` checks instead of open-ended `if/else`, interface segregation instead
of fat base classes, state machine types instead of nullable fields. Every finding includes
a TypeScript before/after sketch.

## When to use it

Run after `smell-scanner` rates OO Abusers as Moderate or Severe, or directly when you
see type-dispatching `if/else` chains, nullable fields that depend on call order, or a
subclass that doesn't really fit its parent.

## How to trigger it

### Claude Code / Cowork

- *"OO abusers analysis on this service"*
- *"I have a big switch statement on a type field — is this a smell?"*
- *"smell-scanner said OO Abusers were Severe, run the focused pass"*
- *"This subclass throws Not Implemented on half its methods"*
- *"These fields are only valid after calling init() — is that a problem?"*

### GitHub Copilot (cloud agent)

- *"Use the smell-oo-abusers skill on src/"*

## Output

Findings with TypeScript-specific before/after sketches showing the polymorphism or
type-system refactoring:

```
## OO Abusers Analysis — discount.service.ts

### Summary
The customerType if/else chain is duplicated three times across DiscountService.
Adding a new customer tier requires finding and updating all three. Replace Conditional
with Polymorphism eliminates the duplication and makes the compiler enforce completeness.

### Findings

#### Switch Statements — customerType dispatched in 3 methods
- **Location**: `DiscountService`, discount.service.ts
- **The problem**: calculate(), getLabel(), and isEligibleForFreeShipping() all branch
  on customerType with the same four cases. Adding 'corporate' tier means three edits
  with no compiler help to find them.
- **Refactoring**: Replace Conditional with Polymorphism
- **Effort**: Medium

- **Before**:
  ```typescript
  calculate(order: Order): number {
    if (order.customerType === 'vip') return order.subtotal * 0.25;
    else if (order.customerType === 'premium') return order.subtotal * 0.15;
    // ...
  }
  ```
- **After**:
  ```typescript
  interface CustomerDiscount {
    calculate(subtotal: number): number;
    getLabel(): string;
    isEligibleForFreeShipping(subtotal: number): boolean;
  }
  class VipDiscount implements CustomerDiscount {
    calculate(subtotal: number) { return subtotal * 0.25 + (subtotal > 500 ? 50 : 0); }
    getLabel() { return '25% VIP discount + bonus'; }
    isEligibleForFreeShipping() { return true; }
  }
  // Adding a new tier = adding one class, zero if/else edits
  ```
```

## Part of the code smells suite

Run `smell-scanner` first for a broad triage. This skill goes deep on OO Abusers.

## Installing

### Claude Code

```bash
cp SKILL.md ~/.claude/skills/smell-oo-abusers.md
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

```bash
mkdir -p .github/skills/smell-oo-abusers
curl -o .github/skills/smell-oo-abusers/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/smell-oo-abusers/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — tuned for JavaScript and TypeScript |
| `evals/evals.json` | Two test cases: duplicated customerType + channel dispatch; DocumentProcessor temporary fields + Circle refusing toBitmap() |
