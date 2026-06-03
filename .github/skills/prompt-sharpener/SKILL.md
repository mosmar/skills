---
name: prompt-sharpener
description: >
  Use this skill before sending a request to GitHub Copilot or any AI agent to avoid wasting
  premium requests on incomplete or ambiguous asks. Trigger when the user says things like
  "help me ask Copilot", "sharpen my prompt", "how should I ask this", "I want to ask Copilot
  to...", "optimize my request", or "batch my questions". Also trigger when a user describes
  a task they want to hand off to an agent but their ask is vague, missing context, or could
  be combined with related tasks. The output is always a ready-to-paste, sharpened prompt —
  not a critique, not a checklist.
---

# Prompt Sharpener

Your job is to take what the user wants to ask a coding agent (GitHub Copilot, Claude Code, etc.)
and return a single, ready-to-paste prompt that gets a complete answer on the first try.

The core problem you're solving: premium AI requests cost quota regardless of how many
follow-ups they spawn. A vague or incomplete ask leads to clarifying back-and-forths, each
burning another request. One tight prompt that anticipates the agent's questions eliminates that.

## What you do

Read the user's raw ask — a question, a task description, a half-formed idea — and:

1. **Identify what's missing or ambiguous.** What would the agent ask back? What assumptions
   is the user making that the agent can't infer? What's the expected output format or scope?

2. **Fold in the missing context.** Don't ask the user to fill in gaps — infer reasonable
   defaults from context and bake them into the prompt. If you genuinely can't infer something
   critical, ask the user one targeted question before producing the output.

3. **Spot batchable tasks.** If the ask implies several related subtasks that would otherwise
   become separate requests, combine them into one structured prompt. For example, "refactor
   this function" often implies "also update the tests" and "check if callers need changes" —
   surface these and include them.

4. **Flag simple lookups (lightly).** If the ask is something a docs search or a quick Google
   would answer just as well, add a one-line note at the top before the sharpened prompt.
   Don't be preachy about it — just flag it once and still deliver the prompt.

## Output format

Always output in this structure:

---
> **💡 Docs/search might be faster here** *(only if clearly a lookup — omit otherwise)*

**Sharpened prompt:**

```
[The ready-to-paste prompt, written as if the user is sending it to Copilot]
```

**What was added:**
- [Bullet per key thing you inferred or folded in, so the user knows what changed]

**Batched tasks included:** *(omit if nothing was batched)*
- [List of related subtasks folded into the prompt]
---

Keep "What was added" brief — 2–4 bullets. The sharpened prompt itself is the deliverable;
the rest is just transparency so the user can override your assumptions if needed.

## What makes a sharp prompt

A sharp prompt for a coding agent has:
- **A clear, single-sentence goal** — what should exist or be true when the agent is done?
- **Relevant scope** — which files, functions, modules, or patterns are in play?
- **Constraints** — language, framework, style guide, existing patterns to follow
- **Expected output** — code changes only? explanation too? tests? a PR description?
- **Edge cases the agent should handle** — error paths, empty inputs, concurrent access, etc.

You don't need all of these for every prompt — use judgment. A simple "add a null check here"
doesn't need scope and constraints. A "refactor this service" absolutely does.

## Tone

Write the sharpened prompt in first person, as if the user is sending it. Keep it direct and
technical — the agent reading it is capable, so don't over-explain. Aim for the shortest prompt
that still eliminates all ambiguity.

## Examples

**Raw ask:** "make my API faster"

**Sharpened:**
```
Profile the Express endpoints in src/api/ and identify the top 3 bottlenecks by response time.
For each one: explain the cause, suggest a fix, and implement it if the change is localized to
that file. Focus on database query patterns and unnecessary synchronous operations. Don't change
the public API surface or existing tests.
```
*What was added: assumed Express/Node based on context, scoped to src/api/, specified not to
break API surface, asked for explanation + implementation, limited to top 3 to avoid scope creep.*

---

**Raw ask:** "add logging to the auth service"

**Sharpened:**
```
Add structured logging to src/services/auth.service.ts using the existing logger instance.
Log at INFO level: successful login (user ID, timestamp), logout. Log at WARN level: failed
login attempts (user ID, reason — no passwords in logs). Log at ERROR level: unexpected
exceptions with stack trace. Follow the log format used in src/services/user.service.ts.
Update unit tests to assert log calls are made on the relevant paths.
```
*What was added: specified log levels, called out no-passwords rule, pointed to an existing
service as a style reference, included test update as a batched task.*
