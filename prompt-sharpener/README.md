# prompt-sharpener

A skill that takes a vague or incomplete Copilot request and returns a polished, ready-to-paste
prompt that gets a complete answer on the first try — no follow-up requests needed.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

## The problem it solves

GitHub Copilot charges premium requests per round trip, not per token. A vague ask — "make
this faster", "add logging", "refactor auth" — leads to clarifying back-and-forths, each
burning another request. One tight prompt that anticipates the agent's questions eliminates that.

## How to trigger it

### Claude Code / Cowork

- *"Help me ask Copilot to refactor my auth module"*
- *"Sharpen this prompt before I send it"*
- *"I want to ask Copilot to add logging — how should I phrase it?"*
- *"Optimize my request: [paste your rough ask]"*
- *"I have a few questions for Copilot, can you batch them?"*

### GitHub Copilot (cloud agent)

- *"Use the prompt-sharpener skill on this ask: [your rough request]"*
- *"Sharpen my Copilot prompt"*

## Output

Always returns a **ready-to-paste prompt** — not a critique, not a checklist:

```
**Sharpened prompt:**

Add structured logging to src/services/auth.service.ts using the existing logger instance.
Log at INFO level: successful login (user ID, timestamp), logout. Log at WARN level: failed
login attempts (user ID, reason — no passwords in logs). Log at ERROR level: unexpected
exceptions with stack trace. Follow the log format used in src/services/user.service.ts.
Update unit tests to assert log calls are made on the relevant paths.

**What was added:**
- Specified log levels with concrete examples
- Added no-passwords constraint
- Pointed to an existing service as a style reference
- Included test update as a batched task

**Batched tasks included:**
- Unit test updates for each logging path
```

If the ask is something a docs search would answer faster, it says so — once, briefly — before
still delivering the sharpened prompt.

## Installing

### Claude Code

```bash
# Global — available in every project
cp SKILL.md ~/.claude/skills/prompt-sharpener.md

# Project-specific
mkdir -p .claude/skills
cp SKILL.md .claude/skills/prompt-sharpener.md
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

```bash
mkdir -p .github/skills/prompt-sharpener
curl -o .github/skills/prompt-sharpener/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/prompt-sharpener/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Test cases: vague refactor ask, open-ended logging request, simple docs lookup |
