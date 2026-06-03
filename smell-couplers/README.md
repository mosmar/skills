# smell-couplers

Deep-dive analysis of Coupler code smells — excessive coupling between classes, and the
opposite problem of classes that are useless middlemen. The unifying fix: move code to
where it belongs.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

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

### GitHub Copilot (cloud agent)

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

## Part of the code smells suite

Run `smell-scanner` first for a broad triage. This skill goes deep on Couplers.

## Installing

### Claude Code

```bash
cp SKILL.md ~/.claude/skills/smell-couplers.md
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

```bash
mkdir -p .github/skills/smell-couplers
curl -o .github/skills/smell-couplers/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/smell-couplers/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Two test cases: TypeScript pricing/order service with Feature Envy + chains; Python notification facade (Middle Man) + UserReportBuilder (chains + envy) |
