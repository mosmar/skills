# context-trimmer

A skill that extracts the minimum viable code context across files for a specific question —
so you paste only what Copilot actually needs, not entire modules.

Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

## The problem it solves

When a question touches multiple files, the temptation is to paste everything. But a typical
service file has 10 methods when Copilot only needs 2. Pasting the whole thing burns tokens
on code the agent never reads. This skill reads your files and your question together, then
hands you back a compact bundle — the relevant functions, their immediate dependencies, and
the type definitions they use. Nothing else.

## How to trigger it

### Claude Code / Cowork

- *"Trim the context for my Copilot question — I'm asking about X and here are my files"*
- *"What do I need to include when asking about the retry logic in my payment service?"*
- *"Context is too big — extract just the relevant parts for this question"*
- *"Slice the relevant code from these files for my question about Y"*

### GitHub Copilot (cloud agent)

- *"Use the context-trimmer skill — my question is X, here are the files"*
- *"Trim this context before I send it to another agent"*

## Output

Returns a single pasteable code bundle with file-path dividers and a reduction estimate:

```
**Context bundle for:** Why is JWT validation failing intermittently?

**Reduction:** ~420 tokens extracted from ~1,800 tokens across 4 files — 77% reduction

// ── src/middleware/auth.ts ───────────────────────────
export async function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    const payload = await verifyToken(token);
    req.user = await UserService.findById(payload.sub);
    next();
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// ── src/utils/jwt.ts ─────────────────────────────────
export async function verifyToken(token: string) {
  return jwt.verify(token, SECRET);  // SECRET from env or 'dev-secret'
}

// ── src/services/user.service.ts ─────────────────────
static async findById(id: string) {
  return db.query('SELECT * FROM users WHERE id = $1', [id]);
}

**What was included:**
- `auth.ts` → `authMiddleware()` — the function doing the validation
- `jwt.ts` → `verifyToken()` — called by middleware; `signToken` omitted
- `user.service.ts` → `findById()` — called on success path; 4 other methods omitted
```

## What it trims

Given your question, it keeps only:

- The specific functions or classes the question is about (full implementation)
- Immediate dependencies — one hop out (signatures, or short implementations)
- Type definitions and interfaces the relevant code uses
- Relevant config or constants that affect the behavior in question

It drops unrelated methods, unused imports, long comment blocks, test files (unless you're
asking about tests), generated code, and anything more than one dependency hop away.

## Installing

### Claude Code

```bash
# Global — available in every project
cp SKILL.md ~/.claude/skills/context-trimmer.md

# Project-specific
mkdir -p .claude/skills
cp SKILL.md .claude/skills/context-trimmer.md
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

```bash
mkdir -p .github/skills/context-trimmer
curl -o .github/skills/context-trimmer/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/context-trimmer/SKILL.md
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Test cases: JWT validation across 4 files, payment retry pipeline across 4 files |
