# tech-debt-tracker

A skill that audits code for technical debt and produces a prioritized, actionable markdown report.
Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

## What it analyzes

- **Code quality** — complexity, duplication, dead code, unclear naming, unresolved TODOs
- **Security** — hardcoded secrets, SQL injection, insecure crypto, swallowed exceptions
- **Dependencies** — outdated packages, deprecated APIs, missing version pins, unused imports
- **Test coverage** — missing tests, happy-path-only assertions, fragile or stub tests

## How to trigger it

### Claude Code / Cowork
Say something like:

- *"Run a tech debt audit on this file"*
- *"Tech debt sweep on my auth module"*
- *"What needs refactoring in this codebase?"*
- *"Audit this repo for issues"*
- *"What's wrong with this code?"*

Works with pasted snippets, attached files, or a whole directory.

### GitHub Copilot (cloud agent)
After [installing the skill](#github-copilot-cloud-agent), Copilot selects it automatically based on
your prompt. You can also invoke it explicitly:

- *"Use the tech-debt-tracker skill on src/"*
- *"Run a tech debt audit on this repository"*

## Installing

### Claude Code

Copy `SKILL.md` to a skills directory Claude Code watches:

```bash
# Global — available in every project
cp SKILL.md ~/.claude/skills/tech-debt-tracker.md

# Project-specific — only in that project
mkdir -p .claude/skills
cp SKILL.md .claude/skills/tech-debt-tracker.md
```

Claude Code discovers skills in both locations automatically.

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

Copy `SKILL.md` into `.github/skills/tech-debt-tracker/` in your project:

```bash
mkdir -p .github/skills/tech-debt-tracker
curl -o .github/skills/tech-debt-tracker/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/tech-debt-tracker/SKILL.md
```

Copilot discovers skills in `.github/skills/` automatically and picks this one based on your prompt
and the skill's description. See the
[GitHub docs](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
for full details on project and personal skill locations.

## Output

Saves `tech-debt-report.md` with:

- **Executive Summary** — 2–4 sentence overview and headline recommendation
- **Findings** — grouped into Critical 🔴 / High 🟡 / Medium-Low 🟢, each with file location, issue description, fix suggestion, and effort estimate
- **Prioritized Action Plan** — top 5–8 items ordered by impact/effort ratio, sprint-ready
- **Metrics Snapshot** — findings count by category and severity

### Example output (truncated)

```markdown
# Tech Debt Report — auth.py
*Generated: 2026-05-26*

## Executive Summary
auth.py has critical security exposure that needs immediate attention. All three
functions build SQL queries via string concatenation, creating SQL injection
vulnerabilities. Passwords are hashed with MD5 (broken since ~2005) and production
database credentials are hardcoded in source. Recommend parameterizing queries and
rotating credentials before the next deploy.

## Findings

### 🔴 Critical — Fix Soon

**Security — SQL Injection in login()**
- **File**: `auth.py`, line 12
- **Issue**: Username and password are concatenated directly into the query string,
  allowing an attacker to log in as any user or dump the database.
- **Fix**: Use parameterized queries: `cursor.execute("SELECT * FROM users WHERE
  username=%s AND password=%s", (username, hashed))`
- **Effort**: Low

...

## Prioritized Action Plan
1. Parameterize all SQL queries (Low effort, eliminates the highest-risk attack class)
2. Rotate the hardcoded DB_PASSWORD — assume it's compromised
3. Replace MD5 with bcrypt or argon2 for password hashing
...
```

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Test cases used during development |
