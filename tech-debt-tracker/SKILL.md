---
name: tech-debt-tracker
description: >
  Use this skill whenever a developer wants to analyze code for technical debt, identify problem
  areas in a codebase, or produce a structured debt report. Trigger on phrases like "tech debt",
  "debt audit", "code health", "find issues in my code", "what needs refactoring", "audit this
  repo", "what's wrong with this codebase", "clean up my code", or any request to assess code
  quality, security problems, dependency issues, or test coverage gaps. Also trigger when the
  user asks to review a file or folder and wants a prioritized list of improvements. Works with
  pasted snippets, attached files, or entire directories.
---

# Tech Debt Tracker

You are performing a structured technical debt audit. Your job is to read the provided code —
whether a single snippet, one or more files, or a whole directory — and produce a prioritized,
actionable markdown report that a developer can act on immediately or share with their team.

## What you're analyzing

You cover four debt categories. For each finding, you care about **impact** (how much does this
hurt?) and **effort** (how hard is it to fix?), because that's what turns a list of complaints
into an actual to-do list.

### 1. Code Quality
Things that make the code harder to understand, change, or maintain:
- High cyclomatic complexity (deeply nested conditionals, long functions doing many things)
- Duplicated logic that should be extracted
- Unclear naming (single-letter variables outside tight loops, misleading names)
- Commented-out code, dead code, TODO/FIXME comments left unresolved
- Missing or stale documentation / docstrings

### 2. Security
Patterns that create vulnerability, not deep pen-testing — flag the obvious ones:
- Hardcoded secrets, tokens, passwords, or connection strings
- Unvalidated or unsanitized user inputs passed to databases, shell commands, or templates
- Use of deprecated or insecure crypto (MD5, SHA1 for passwords, eval(), exec(), etc.)
- Overly broad exception handling that swallows errors silently
- Exposed debug routes, admin endpoints, or verbose error messages in production paths

### 3. Dependencies
- Packages pinned to very old or end-of-life versions
- Dependencies with known vulnerabilities (flag if you recognize them; note you can't run npm audit yourself)
- Unused imports or requirements.txt / package.json entries not referenced in code
- Deprecated API usage from standard libraries or frameworks
- Missing version pins that make builds non-reproducible

### 4. Test Coverage Gaps
- Functions or classes with no test at all
- Happy-path-only tests missing edge cases, error paths, or boundary conditions
- Tests that assert on implementation details rather than behavior (fragile tests)
- Mocked-everything tests that don't exercise real logic
- Test files that are clearly stubs or TODOs

## How to approach the work

**If given a directory or multiple files**, do a broad sweep first — get a feel for the overall
structure, language, and apparent purpose before diving into specifics. Prioritize files that are
central to the app's logic (entry points, core modules, data models) over config files and
generated code.

**If given a snippet or single file**, go deep — you have everything you need, so be thorough.

As you read, keep a mental tally of findings and their severity. Aim for findings that are
*specific and actionable* — not "this function is complex" but "the process_payment() function
in billing.py is 120 lines with 7 levels of nesting; extract the discount calculation into a
helper". The reader should be able to act on each finding without having to re-read the code
themselves.

## Output format

Save the report as `tech-debt-report.md` in the working directory. Use this exact structure:

```
# Tech Debt Report — [filename or directory name]
*Generated: [date]*

## Executive Summary
2-4 sentences. Overall health, worst problem area, one headline recommendation.

## Findings

### Critical — Fix Soon
[Items that pose immediate risk: security vulns, crashes, data loss potential]

### High — Plan for Next Sprint
[Items with meaningful impact on stability or maintainability but not on fire]

### Medium / Low — Good Housekeeping
[Style, minor duplication, documentation gaps, small test holes]

---
Each finding follows this format:

**[Category] — [Short title]**
- **File**: path/to/file.py, line N (or "multiple locations")
- **Issue**: What's wrong and why it matters
- **Fix**: Concrete suggestion for how to address it
- **Effort**: [Low / Medium / High]

## Prioritized Action Plan
A numbered list of the top 5-8 things to do, ordered by impact/effort ratio.
The reader should be able to hand this list directly to a sprint planner.

## Metrics Snapshot
| Category | Findings | Critical | High | Medium/Low |
|---|---|---|---|---|
| Code Quality | N | N | N | N |
| Security | N | N | N | N |
| Dependencies | N | N | N | N |
| Test Coverage | N | N | N | N |
| Total | N | N | N | N |
```

## Severity guide

- **Critical** — Security exposure, potential data loss, crashes in production, hardcoded secrets
- **High** — Significant complexity debt, deprecated APIs likely to break, missing tests on critical paths
- **Medium/Low** — Style issues, minor duplication, stale comments, test gaps in non-critical code

## Tone and calibration

You're writing for a developer, not a manager. Be direct and specific. Don't pad the report with
generic advice ("consider adding more tests") when you can point to the exact gap. If the code is
actually in decent shape, say so — a short, honest report with 3 real findings beats a padded one
with 15 vague ones.

If you cannot read certain files (binary, generated, or tooling config), note that briefly and
move on — don't let it block the report.
