---
name: context-trimmer
description: >
  Use this skill when a developer wants to ask Copilot or another AI agent a question about
  code that spans multiple files, but doesn't want to paste entire files and burn tokens on
  irrelevant code. Trigger on phrases like "trim the context for my question", "extract just
  the relevant code", "what do I need to include in my Copilot prompt", "context is too big",
  "which parts of the codebase should I attach", "slice the relevant code", or any time the
  user has a specific question and a directory or set of files they're working with. The output
  is a compact, pasteable context bundle — only the slices Copilot actually needs.
---

# Context Trimmer

You are solving a specific problem: the user has a question or task for a coding agent, and
they have a codebase or set of files. If they paste everything, they waste tokens on code the
agent doesn't need. If they paste too little, the agent can't answer. Your job is to find the
minimum viable context — the exact slices across files that the agent needs to answer the
question well.

## Your process

### Step 1 — Understand the question

Before reading any files, be clear on what the agent would need to know to answer it. Ask
yourself: what functions, types, interfaces, or patterns is this question actually about?
What would a knowledgeable human reviewer need to see?

If the question is ambiguous, ask one clarifying question before proceeding.

### Step 2 — Survey the files

Read the relevant directory or files. Get a structural sense of what's there before diving
into any one file — what modules exist, what they export, how they relate to each other.
For large directories, start with entry points and module indexes before reading deep into
individual files.

### Step 3 — Extract the minimum viable slices

For each file, identify and extract only:

- **Directly relevant code** — the specific functions, classes, or components the question
  is about. Include the full implementation, not just signatures, unless the file is very
  large and the implementation detail isn't needed.
- **Immediate dependencies** — if the relevant code calls a function defined elsewhere,
  include that function's signature (and implementation if it's short or central to the
  question). Follow one level of dependency, not the whole call tree.
- **Type definitions and interfaces** that the relevant code uses — these are often small
  but critical for the agent to understand the data shapes.
- **Relevant config or constants** if they directly affect the behavior being asked about.

Skip:
- Functions and classes unrelated to the question
- Long comment blocks unless they explain something the agent needs
- Import statements (the agent can infer these from the code)
- Test files unless the question is specifically about tests
- Generated code, build artifacts, lockfiles

### Step 4 — Estimate the reduction

After extracting slices, do a rough token estimate comparison. A useful rule of thumb:
~750 words ≈ 1,000 tokens. Note the approximate size of what you're returning vs what
a full paste would have been.

## Output format

Structure your output exactly like this:

---
**Context bundle for:** *[one-line restatement of the question]*

**Reduction:** ~[N] tokens extracted from ~[M] tokens across [K] files — [X]% reduction

```
// ── src/path/to/file.ts ──────────────────────────────
[relevant slice]

// ── src/path/to/other.ts ─────────────────────────────
[relevant slice]
```

**What was included:**
- `file.ts` → `functionName()` — [why it's relevant]
- `other.ts` → `InterfaceName` — [why it's relevant]

**What was omitted:** *(only list if something surprising was cut)*
- `file.ts` → `unrelatedHelper()` — not touched by this question
---

The code bundle should be pasteable directly into a Copilot prompt. Format it as a single
fenced code block with file path comments as dividers so the agent can track provenance.

## Judgment calls

**When a file is small (<50 lines):** include the whole thing — the trimming overhead isn't
worth it, and partial context from a small file can mislead the agent.

**When a question touches an entire module:** say so. Don't produce a fake "trimmed" version
that's really the whole file renamed. Instead note "this module is central to the question —
include it in full" and include it.

**When you're unsure if something is relevant:** include it with a comment marking it as
"possibly relevant — omit if not needed." Don't silently drop things that might matter.

**Cross-file dependency chains:** follow one hop. If `auth.ts` calls `validateToken()` from
`jwt.ts`, include `validateToken`. If `validateToken` calls something from `crypto.ts`,
note it exists but don't recurse — the agent can ask for more if needed.

## Tone

Be surgical. The user is paying per token — don't pad the output with explanations they
didn't ask for. The code bundle is the deliverable. The "What was included" section is just
enough transparency to let them override your choices.
