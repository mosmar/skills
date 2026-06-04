# smell-guard

An agent-facing coding standard that prevents code smells from being introduced in the
first place. Agents read these rules before writing code and self-check their output
before presenting it — no post-review step needed.

Works with **Claude Code**, **Cowork**, **GitHub Copilot in VSCode**, and **GitHub Copilot** (cloud agent).

## How it differs from the detection skills

| | smell-scanner / focused skills | smell-guard |
|---|---|---|
| **When it runs** | After code is written | While code is being written |
| **Who reads it** | The human | The agent |
| **Output** | Findings report | Better code |
| **Style** | Explanatory | Directive — "do this, not that" |

The detection skills find smells that already exist. This skill prevents them from being
introduced. Used together: **smell-guard** on every coding task → **smell-scanner** on
periodic reviews → focused skills to clean up anything that slipped through.

## What it enforces

The agent reads these rules before writing and runs a mental self-check before presenting
any code output:

**Functions** — one responsibility, no section comments, max 3–4 parameters, no boolean
flag arguments.

**Classes** — single named responsibility, max ~4 injected dependencies, no fields that
are only valid after a specific method is called.

**Multiple variants** — no `if/else if` chains on type/kind/role. Use polymorphism,
discriminated unions with exhaustive checks, or a strategy map instead.

**Domain values** — branded types or value classes for emails, IDs, monetary amounts,
statuses — not raw `string` and `number`.

**Object references** — Law of Demeter: max one hop (`order.getCity()`, not
`order.getCustomer().getAddress().getCity()`). Methods that use another object's data
more than their own belong in that object.

**Cleanliness** — no dead code, no speculative abstractions, no what-not-why comments.

**Existing smells** — when editing code that already has a smell, don't silently spread
it. Add what was requested, flag the existing smell, and show what the fix would look like.

## How to install it as a project-wide coding standard

This is the most powerful way to use it — install once per project and every agent task
automatically follows these standards.

### Claude Code (project-specific)

```bash
mkdir -p .claude/skills
cp SKILL.md .claude/skills/smell-guard.md
```

Every `claude` invocation in this project will follow these standards automatically.

### Claude Code (global — all projects)

```bash
cp SKILL.md ~/.claude/skills/smell-guard.md
```

### GitHub Copilot in VSCode — repo-wide instructions

Copilot in VSCode reads `.github/copilot-instructions.md` as standing context for every
chat and inline suggestion in the repo. Copy the skill content there:

```bash
cat SKILL.md >> .github/copilot-instructions.md
```

Or create the file from scratch if it doesn't exist yet:

```bash
cp SKILL.md .github/copilot-instructions.md
```

Every Copilot Chat session and agent task in VSCode will follow these standards for that repo.

### GitHub Copilot in VSCode — file-type scoped (instruction files)

For TypeScript/JavaScript projects specifically, Copilot supports per-file-pattern
instruction files in `.github/instructions/`. This lets you scope the rules to only TS/JS
files rather than all files in the repo:

```bash
mkdir -p .github/instructions
```

Then create `.github/instructions/smell-guard.instructions.md`:

```markdown
---
applyTo: "**/*.ts,**/*.tsx,**/*.js,**/*.jsx"
---
```

And append the contents of `SKILL.md` below the frontmatter. Copilot will apply these
rules automatically whenever it touches a TypeScript or JavaScript file.

### GitHub Copilot (cloud agent — GitHub.com)

```bash
mkdir -p .github/skills/smell-guard
curl -o .github/skills/smell-guard/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/smell-guard/SKILL.md
```

Every Copilot agent task triggered from GitHub.com will consult these standards.

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

## Example: what changes

**Without smell-guard**, asked to "write a notification service for email, SMS, and push":
```typescript
// agent produces:
async send(type: string, to: string, message: string) {
  if (type === 'email') { await this.email.send(to, message); }
  else if (type === 'sms') { await this.sms.send(to, message); }
  else if (type === 'push') { await this.push.send(to, message); }
}
```

**With smell-guard**, same prompt:
```typescript
// agent produces:
interface NotificationChannel {
  send(to: string, message: string): Promise<void>;
}
class EmailChannel implements NotificationChannel { ... }
class SmsChannel implements NotificationChannel { ... }
class PushChannel implements NotificationChannel { ... }

// Adding a new channel = one new class, zero edits to existing code
```

## The self-check

Before presenting any code, the agent runs through this list:

- Does every function do one thing?
- Does every class have one named responsibility?
- Any if/else chains on type/kind/role that will be duplicated?
- Any nullable fields that depend on method call order?
- Any primitives that should be domain types?
- Any method chains longer than one hop?
- Any dead code, speculative abstractions, or what-not-why comments?

## Part of the code smells suite

```
smell-guard          ← prevents smells during code generation  (this skill)
smell-scanner        ← detects smells in existing code
smell-bloaters       ← deep fix guidance for Bloaters
smell-dispensables   ← deep fix guidance for Dispensables
smell-couplers       ← deep fix guidance for Couplers
smell-oo-abusers     ← deep fix guidance for OO Abusers (JS/TS)
smell-change-prev    ← deep fix guidance for Change Preventers
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Agent-facing coding standard — directive style, covers all 5 smell categories |
| `evals/evals.json` | Three test cases: notification service (should use polymorphism), document processor (no nullable sequential fields), extending a smelly switch (should flag it) |
