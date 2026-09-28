# smell-couplers

Deep-dive analysis of Coupler code smells — excessive coupling between classes, and the
opposite problem of classes that are useless middlemen. The unifying fix: move code to
where it belongs.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot in VS Code** (agent mode and chat).

## The four Coupler smells

Based on the [refactoring.guru Couplers catalog](https://refactoring.guru/refactoring/smells/couplers):

| Smell | Signal | Fix |
|---|---|---|
| **Feature Envy** | Method uses another class's data more than its own | Move Method to the class it envies |
| **Inappropriate Intimacy** | Two classes reach into each other's internals | Move Method/Field, Extract Class, Hide Delegate |
| **Message Chains** | `a.getB().getC().doThing()` — Law of Demeter violations | Hide Delegate, Extract Method |
| **Middle Man** | Class exists only to forward calls to another | Remove Middle Man, Inline Method |

## The core question

Every Coupler smell is an ownership problem: *who should be responsible for this behavior?*
This skill answers that directly — not just "this is coupled" but "this method belongs in
`Order`, not `PricingService`."

## When to use it

Run after `smell-scanner` rates Couplers as Moderate or Severe, or directly when you suspect
coupling — a method that feels out of place, accessor chains navigating through multiple
objects, or a class that seems to exist only to forward calls.

## How to trigger it

### Claude Code / Cowork

- *"Do a couplers analysis on these files"*
- *"This method doesn't seem to belong here"*
- *"I keep having to change two files together whenever anything changes"*
- *"smell-scanner flagged Couplers, run the focused pass"*
- *"There are a lot of long accessor chains in this service"*
- *"This class just delegates everything — is it even needed?"*

### GitHub Copilot (VS Code agent mode)

Copilot picks the skill automatically from its `description`, so natural phrasing works. You can also name the skill to invoke it explicitly.

- *"Do a couplers analysis on #file:src/services/order.service.ts and #file:src/services/customer.service.ts"*
- *"This method doesn't seem to belong here — check #selection"*
- *"I keep having to change two files together whenever anything changes"*
- *"smell-scanner flagged Couplers, run the smell-couplers focused pass"*
- *"There are a lot of long accessor chains in #file:src/services/billing.service.ts"*
- *"This class just delegates everything — is it even needed?"*
- *"Use the smell-couplers skill on src/services/"*

## Output

A findings report naming exactly where code should move and what method to add to hide
internal navigation:

```
## Couplers Analysis — pricing.service.ts, order.repository.ts

### Summary
PricingService is almost entirely Feature Envy — both methods work with Order's data and
belong on Order. Message chains through Customer and Address are a secondary issue. The
repository has one case of Inappropriate Intimacy worth addressing.

### Findings

#### Feature Envy — calculateOrderTotal() belongs on Order
- **Location**: `PricingService.calculateOrderTotal()`, pricing.service.ts
- **The coupling**: The entire method reads Order's items, customer membership tier, and
  promo code. PricingService knows more about Order's internals than Order does.
- **Why it hurts**: Adding a new discount type requires editing PricingService even though
  it's entirely an Order concern. Order can't calculate its own total without this service.
- **Refactoring**: Move Method — move to `Order.calculateTotal()`. PricingService can call
  it there, or be deleted if that was its only job.
- **Effort**: Medium

#### Message Chains — navigating Customer → Membership → Tier
- **Location**: `PricingService.calculateOrderTotal()`, line 9
- **The coupling**: `order.getCustomer().getMembership().getTier()` — three hops through
  internal structure to get a discount tier.
- **Why it hurts**: Changing how membership is stored (e.g. moving tier to Customer directly)
  breaks every chain that navigates through Membership.
- **Refactoring**: Hide Delegate — add `order.getMembershipTier(): string` that handles
  the navigation internally. Callers get the value without knowing the path.
- **Effort**: Low
...

---
### Decoupling order
1. Hide the message chains first — low effort, each is a 3-line method addition
2. Move calculateOrderTotal() to Order — eliminates the core Feature Envy
3. Move formatOrderSummary() to Order or a dedicated formatter
4. Fix the repository's intimate access to order.getCustomer().setAddress()
```

## Respects your stack

- **Never swaps frameworks or libraries.** Fixes use what the project already has — it won't
  suggest replacing Mongoose or an ORM, or migrating Express to NestJS.
- **Generated scaffold code is the clean baseline.** If your project came from an org
  template or generator, the structure it produces isn't reported as a smell, so a fresh
  project comes out clean and every project built from the scaffold stays consistent.
- **Keeps the standard layers** — controller → service → repository and API services over
  `HttpClient` aren't Middle Men.
- **Convention notes, not findings.** If an existing convention itself looks like a smell,
  it's mentioned separately — unrated and outside the refactoring order — so your team can
  decide whether to change the standard.
- **Tunable.** Ask for a "full scan" or "audit the template" to see scaffold patterns as
  `[baseline]` findings, or set project-wide rules with a `## Smell baseline` section — see
  [Tuning the smell suite](../README.md#tuning-the-smell-suite).

## Part of the code smells suite

Run `smell-scanner` first for a broad triage. This skill goes deep on Couplers.

## Installing

**1. Get the files.** Clone this repo, or unzip the download you were given. The commands
below run from its root folder.

```bash
git clone https://github.com/mosmar/skills.git && cd skills
```

**2. Install for your agent.** `install.sh` copies `smell-couplers/SKILL.md` to the right place.

### Claude Code

```bash
./install.sh --platform claude --target ~/.claude/skills smell-couplers             # every project
./install.sh --platform claude --target <project>/.claude/skills smell-couplers     # one project
```

### GitHub Copilot

```bash
./install.sh --platform copilot-global --target ~/.copilot/skills smell-couplers    # every repo, nothing to commit
./install.sh --target <repo> smell-couplers                                         # one repo, commit .github/skills/
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### By hand

The script only copies one file, so you can do it yourself from the repo root:

```bash
# Claude Code
cp smell-couplers/SKILL.md ~/.claude/skills/smell-couplers.md

# Copilot, every repo
mkdir -p ~/.copilot/skills/smell-couplers
cp smell-couplers/SKILL.md ~/.copilot/skills/smell-couplers/

# Copilot, one repo
mkdir -p <repo>/.github/skills/smell-couplers
cp smell-couplers/SKILL.md <repo>/.github/skills/smell-couplers/
```

### Without cloning

Fetch the single file from GitHub (works while the repo is public). Change the `-o` path to
any destination above:

```bash
curl --create-dirs -o ~/.copilot/skills/smell-couplers/SKILL.md \
  https://raw.githubusercontent.com/mosmar/skills/main/smell-couplers/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Two test cases: TypeScript pricing/order service with Feature Envy + chains; Python notification facade (Middle Man) + UserReportBuilder (chains + envy) |
