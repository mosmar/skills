---
name: smell-couplers
description: >
  Use this skill for a deep analysis of Coupler code smells — excessive coupling between
  classes, or the opposite problem of excessive delegation that makes objects useless
  middlemen. Trigger on phrases like "feature envy", "this method doesn't belong here",
  "classes too tangled", "law of demeter violation", "message chains", "this class just
  delegates everything", "inappropriate intimacy", "tight coupling", "incomplete library
  class", "I can't change this third-party class", "monkey-patching a library", or when
  smell-scanner has rated Couplers as Moderate or Severe. Also trigger when a developer says a change
  in one place keeps requiring changes in another, or when methods seem to be working with
  the wrong object's data. Works with snippets, single files, or directories. Output is a
  detailed findings report with specific move-method guidance and named refactoring
  techniques for each coupler found.
---

# Smell: Couplers

You are performing a focused deep-dive on Coupler smells — code that ties classes together
too tightly, or delegates so heavily that some classes become useless pass-throughs.

The unifying question behind all Coupler smells is: **who owns this behavior?** Code is
coupled when a method or piece of logic lives in the wrong place — somewhere that has to
reach into another object's internals to do its job. The fix is almost always to move the
code to where the data it needs already lives, or to hide the internal structure being
navigated so it doesn't need to be navigated from the outside.

## The five Coupler smells

### 1. Feature Envy
A method that is more interested in the data of another class than its own. It spends most
of its time calling getters on another object, computing things from that object's state,
or making decisions based on that object's internals. This is a sign the method belongs in
the class it envies.

**Signals to look for:**
- A method in class A that calls many methods or accesses many fields of class B
- Logic that computes something entirely from another object's data (`order.getItems()`,
  `order.getDiscount()`, `order.getCustomer().getTier()` — all in one method on `Pricer`)
- Methods that take an object as a parameter and then extensively decompose it
- Methods named after the object they work with (`calculateOrderTotal`, `formatUserAddress`
  living outside `Order` and `User`)

**Named refactoring techniques:**
- **Move Method** — move the envious method to the class it envies. If the method uses data
  from multiple classes, move it to the class whose data it uses most.
- **Extract Method** — if only part of the method has feature envy, extract that part and
  move it.

**Calibration:** Some coupling across boundaries is unavoidable — a controller that reads
from a request object isn't envying the request, it's doing its job. Feature Envy is a
smell when a method's core logic belongs to a different domain object.

### 2. Inappropriate Intimacy
Two classes that know too much about each other's internals. They dig into each other's
private fields, depend on implementation details, or are so intertwined that changing one
always breaks the other. Unlike Feature Envy (one class doing all the reaching), Inappropriate
Intimacy is usually bidirectional — both classes are tangled.

**Signals to look for:**
- Class A accesses private or "internal" fields of class B directly (especially via getters
  that expose implementation)
- Two classes that always need to be changed together
- Circular dependencies between classes
- A class that passes `this` to another class so the other can call back into it
- Subclasses that access parent private members directly (bypassing the parent's interface)
- Classes that mirror each other's field structure

**Named refactoring techniques:**
- **Move Method / Move Field** — redistribute responsibilities so each class owns what it
  needs and doesn't need to reach into the other.
- **Extract Class** — if the intimacy is around a shared concept, extract it into a third
  class that both can depend on.
- **Hide Delegate** — instead of exposing an internal object for callers to navigate, add a
  method on the outer class that handles the navigation internally.
- **Replace Inheritance with Delegation** — if a subclass is intimately coupled to parent
  internals, composition is often cleaner.

### 3. Message Chains
A series of method calls chained together to navigate object relationships:
`a.getB().getC().getD().doThing()`. Each link in the chain is a dependency on the internal
structure of the previous object. When the structure changes, every chain that navigates
through it breaks.

This is also known as a Law of Demeter violation — a method should only call methods on
objects it directly knows about (its own fields, its parameters, objects it created, or
global objects), not on objects returned by other method calls.

**Signals to look for:**
- Chains of 3+ accessor calls in a single expression
- Navigation through objects that "shouldn't" be exposed: `order.getCustomer().getAddress().getCity()`
- Repeated navigation of the same path in multiple places (copy-pasted chains)
- Methods that take a top-level object just to navigate to something deep inside it

**Named refactoring techniques:**
- **Hide Delegate** — add a method on the intermediate object that exposes what the caller
  needs, hiding the internal navigation. `order.getCustomer().getAddress().getCity()` becomes
  `order.getShippingCity()`, which handles the navigation internally.
- **Extract Method** — extract the chain into a named method that makes the intent clear and
  centralizes the navigation in one place.

**Calibration:** Fluent interfaces and builder patterns (`.filter().map().reduce()`) are not
Message Chains — they're intentional API design. The smell is navigating through domain
objects to reach data that the intermediate objects aren't supposed to expose.

### 4. Middle Man
A class whose primary job is forwarding calls to another class — it adds a layer of
indirection without adding any value. Every method just delegates to another object.

**Signals to look for:**
- A class where more than half the methods simply call the same method on a delegate object
- Classes named `XxxProxy`, `XxxWrapper`, `XxxAdapter` that don't actually adapt anything
- Classes that have one field (the delegate) and 5+ methods that all call into it
- A class that was created for a future purpose (abstraction, flexibility) that never materialized

**Named refactoring techniques:**
- **Remove Middle Man** — have callers call the delegate directly. Delete the wrapper.
- **Inline Method** — if only some methods are pure delegation, inline those specific ones.
- **Replace Delegation with Inheritance** — if the class is essentially wrapping another
  class to expose its interface, inheritance (or composition through a more meaningful
  abstraction) may be cleaner.

**Calibration:** Not all delegation is Middle Man. A class that delegates *most* calls but
adds meaningful behavior on a few is not a Middle Man — it's doing its job. The smell is
a class that adds no value at all. Facade pattern classes that simplify a complex subsystem
are also not Middle Men.

### 5. Incomplete Library Class
A third-party or library class that almost does what you need, but is missing a method or two —
and you can't (or shouldn't) modify it, because you don't own the source or changing it would
break other consumers. The coupling shows up as awkward workarounds scattered around the
codebase: the same little dance performed against the library at every call site because the
clean method you wish existed doesn't. Left unaddressed, this leads to copy-pasted glue code
(a Shotgun Surgery in waiting) or, worse, monkey-patching the library in place.

This is the "Other Smell" in refactoring.guru's catalog; it's grouped here under Couplers
because it's fundamentally about the coupling between your code and an external class you can't
change.

**Signals to look for:**
- The same small wrapper logic repeated at every call site of a library function
  (e.g. always converting the library's return value, always pre-formatting an argument)
- Helper functions that take a library instance as their first parameter and exist only to
  add behavior the library lacks (`formatMoment(date)`, `safeParse(jsonLib, str)`)
- Monkey-patching: assigning new methods onto a library's prototype or object at runtime
- A local utils module full of one-off functions that all operate on the same third-party type
- Comments like `// lib doesn't support X, so we do it here`

**Named refactoring techniques:**
- **Introduce Foreign Method** — when you need just one or two extra methods, write a function
  in your own code that takes the library instance as a parameter and performs the missing
  operation. Keep it next to the other code that uses the library. This is the lightweight fix.
- **Introduce Local Extension** — when you need several missing methods, create a subclass or
  wrapper class of the library type that adds them. A subclass extends the original directly;
  a wrapper holds an instance and delegates plus extends. Prefer a wrapper when the library
  class is hard to subclass (final/sealed, complex constructors) or when you want to constrain
  the surface area you expose.

**TypeScript/JS-specific approach:**
Prefer Introduce Foreign Method (a plain standalone function) over patching prototypes —
monkey-patching a library's prototype is global, invisible to other readers, and breaks when
the library updates. If you need many additions, a thin wrapper class (composition) is usually
cleaner than subclassing, and it survives library internals changing. Reserve `declare module`
augmentation for adding *types* to a library, not runtime behavior.

**Calibration:** A single, well-named helper function over a library is not a smell — it's
normal, healthy glue. The smell is the *absence* of that consolidation: the same missing
operation reimplemented ad hoc in many places, or runtime patching of code you don't own.

## How to approach the analysis

For each class and method, ask:
- Does this method use more of another class's data than its own? (Feature Envy)
- Do these two classes reach into each other in ways that make them hard to change
  independently? (Inappropriate Intimacy)
- Are there accessor chains navigating through multiple objects? (Message Chains)
- Does this class exist primarily to forward calls? (Middle Man)
- Is the same missing-from-the-library operation reimplemented at many call sites, or is a
  library being monkey-patched? (Incomplete Library Class)

For **Feature Envy**, identify which class the envious method belongs in — name it explicitly.
For **Message Chains**, identify what the chain is navigating to and suggest what method on
which intermediate class would hide it.
For **Inappropriate Intimacy**, describe the specific coupling — what does each class know
about the other that it shouldn't?
For **Middle Man**, count how many methods are pure delegation vs. how many add value.
For **Incomplete Library Class**, name the library and the missing operation, point to the
scattered call sites, and say whether a Foreign Method (one or two additions) or a Local
Extension (several additions) is the right fix.

## Output format

```
## Couplers Analysis — [filename or directory]

### Summary
[2–3 sentences on the coupling situation: which smells are present, how severe, and the
dominant ownership problem]

### Findings

#### [Smell type] — [Short title]
- **Location**: `ClassName.methodName()` or `path/to/file.ts`
- **The coupling**: [Specific description — what reaches into what, what knows what]
- **Why it hurts**: [What becomes hard to change or test as a result]
- **Refactoring**: [Named technique] — [Concrete guidance: what to move where, what method
  to add on which class]
- **Effort**: Low / Medium / High
- **Before sketch** (when the move direction isn't obvious):
  ```
  [relevant snippet]
  ```
- **After sketch**:
  ```
  [how it looks post-refactor]
  ```

---
### Decoupling order
[Which to address first — usually start with Message Chains (low effort, high clarity),
then Feature Envy (move methods to where they belong), then Inappropriate Intimacy (the
most structural change), then Middle Man (often easiest once the others are resolved).
Incomplete Library Class is usually low effort and high value — consolidating scattered glue
into a Foreign Method or Local Extension can be done early and independently of the others]
```

## Tone

Name the ownership problem directly. "This method belongs in `Order`, not `PricingService`"
is more useful than "this method has feature envy." The developer should finish reading a
finding knowing exactly where to move the code.
