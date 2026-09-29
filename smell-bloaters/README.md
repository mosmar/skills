# smell-bloaters

Deep-dive analysis of Bloater code smells — things that have grown too large to work with
comfortably. Finds every instance, names the specific refactoring technique, and gives
concrete before/after guidance.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot in VS Code** (agent mode and chat).

## The five Bloater smells

Based on the [refactoring.guru Bloaters catalog](https://refactoring.guru/refactoring/smells/bloaters):

| Smell | Signal | Fix |
|---|---|---|
| **Long Method** | Multiple concerns, section comments, deep nesting | Extract Method, Decompose Conditional |
| **Large Class** | Field clusters, unrelated methods, vague class name | Extract Class, Extract Interface |
| **Primitive Obsession** | Strings for emails/IDs/status, ints for money | Replace Data Value with Object, Introduce Parameter Object |
| **Long Parameter List** | 4+ params, boolean flags, params from same object | Introduce Parameter Object, Preserve Whole Object |
| **Data Clumps** | Same 3+ fields appearing together everywhere | Extract Class, Introduce Parameter Object |

## When to use it

Run this after `smell-scanner` rates Bloaters as Moderate or Severe, or directly when you
know bloat is the issue — a method that's too long, a class that's doing too many things,
a function signature that's out of control.

## How to trigger it

### Claude Code / Cowork

- *"Do a bloater analysis on this file"*
- *"This class has too many responsibilities — run smell-bloaters on it"*
- *"smell-scanner said Bloaters were Severe, do the focused pass"*
- *"This function is way too long, help me break it down"*
- *"Too many parameters in this service — what's the fix?"*

### GitHub Copilot (VS Code agent mode)

Copilot picks the skill automatically from its `description`, so natural phrasing works. You can also name the skill to invoke it explicitly.

- *"Do a bloater analysis on #file:src/services/order.service.ts"*
- *"This class has too many responsibilities — use smell-bloaters on #selection"*
- *"smell-scanner said Bloaters were Severe, run the smell-bloaters focused pass"*
- *"This function is way too long, help me break it down"*
- *"Too many parameters in #file:src/services/payment.service.ts — what's the fix?"*
- *"Use the smell-bloaters skill on src/services/order.service.ts"*

## Output

A findings report with location, why it hurts, the named refactoring technique, effort
estimate, and before/after sketches where the refactoring direction isn't obvious:

```
## Bloater Analysis — order.service.ts

### Summary
One severe Long Method dominates — `processOrder()` handles five distinct responsibilities.
A Long Parameter List and Primitive Obsession are secondary. Splitting the method is the
highest-leverage move and will naturally reduce the parameter count too.

### Findings

#### Long Method — processOrder() does five things
- **Location**: `OrderService.processOrder()`, lines 8–54
- **Why it's a problem**: Validation, pricing, payment, persistence, and notification are
  all in one method. Adding a new payment method or notification channel means editing
  a 60-line function and hoping nothing else breaks.
- **Refactoring**: Extract Method × 5 — extract `validateItems()`, `calculateTotal()`,
  `chargePayment()`, `persistOrder()`, `notifyCustomer()`. Each becomes independently
  testable.
- **Effort**: Medium

#### Long Parameter List — 7 parameters on processOrder()
- **Location**: `OrderService.processOrder()` signature
- **Why it's a problem**: Call sites look like `processOrder(id, custId, items, 'card',
  '123 Main St', 'SAVE10', true)` — impossible to read without the function definition open.
- **Refactoring**: Introduce Parameter Object — extract `shippingAddress`, `promoCode`,
  and `isGuestCheckout` into a `CheckoutOptions` object.
- **Effort**: Low
...

---
### Refactoring order
1. Extract the five sub-methods from processOrder() — this is the core fix
2. Introduce CheckoutOptions parameter object — clean up call sites
3. Replace any[] items with a typed Item interface
```

## Respects your stack

- **Never swaps frameworks or libraries.** Fixes use what the project already has — it won't
  suggest replacing Mongoose or an ORM, or migrating Express to NestJS.
- **Generated scaffold code is the clean baseline.** If your project came from an org
  template or generator, the structure it produces isn't reported as a smell, so a fresh
  project comes out clean and every project built from the scaffold stays consistent.
- **Fits your idioms** — magic-string statuses become an enum or union in the existing
  schema; it won't introduce branded types the project doesn't already use.
- **Convention notes, not findings.** If an existing convention itself looks like a smell,
  it's mentioned separately — unrated and outside the refactoring order — so your team can
  decide whether to change the standard.
- **Tunable.** Ask for a "full scan" or "audit the template" to see scaffold patterns as
  `[baseline]` findings, or set project-wide rules with a `## Smell baseline` section — see
  [Tuning the smell suite](../README.md#tuning-the-smell-suite).

## Part of the code smells suite

Run `smell-scanner` first for a broad triage. This skill goes deep on Bloaters specifically.
The other focused skills cover the remaining four categories.

## Installing

**1. Get the files.** Clone this repo, or unzip the download you were given. The commands
below run from its root folder.

```bash
git clone https://github.com/mosmar/skills.git && cd skills
```

**2. Install for your agent.** `install.sh` copies `smell-bloaters/SKILL.md` to the right place.
Run `./install.sh` for a menu, or pass the choices directly:

### Claude Code

```bash
./install.sh --claude --global smell-bloaters                        # every project, nothing to commit
./install.sh --claude --project --dir <project> smell-bloaters       # one project, commit .claude/skills/
```

### GitHub Copilot

```bash
./install.sh --copilot --global smell-bloaters                       # every repo, nothing to commit
./install.sh --copilot --project --dir <repo> smell-bloaters         # one repo, commit .github/skills/
```

To install every skill in this repo instead, use `all` in place of `smell-bloaters` (recommended).

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### By hand

The script only copies one file, so you can do it yourself from the repo root:

```bash
# Claude Code, every project
mkdir -p ~/.claude/skills/smell-bloaters
cp smell-bloaters/SKILL.md ~/.claude/skills/smell-bloaters/

# Copilot, every repo
mkdir -p ~/.copilot/skills/smell-bloaters
cp smell-bloaters/SKILL.md ~/.copilot/skills/smell-bloaters/

# Copilot, one repo
mkdir -p <repo>/.github/skills/smell-bloaters
cp smell-bloaters/SKILL.md <repo>/.github/skills/smell-bloaters/
```

### Without cloning

Fetch the single file from GitHub (works while the repo is public). Change the `-o` path to
any destination above:

```bash
curl --create-dirs -o ~/.copilot/skills/smell-bloaters/SKILL.md \
  https://raw.githubusercontent.com/mosmar/skills/main/smell-bloaters/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Two test cases: overloaded TypeScript order service, God-class Python UserManager |
