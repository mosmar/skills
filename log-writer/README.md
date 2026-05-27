# log-writer

A skill that adds or improves logging in **Node.js, Express, and NestJS** code following
production best practices. Works with **Claude Code**, **Cowork**, and **GitHub Copilot** (cloud agent).

## What it does

- **Detects your existing logging setup** — matches pino, winston, NestJS Logger, nestjs-pino,
  or morgan rather than introducing a new dependency
- **Defaults to pino** for plain Express projects, **NestJS Logger** (or nestjs-pino) for NestJS
- **Chooses the right log level** — verbose/debug/log/warn/error at every site
- **Structured output** — key-value objects over template strings so logs are queryable in
  Datadog, CloudWatch, Loki, etc.
- **Adds context** — correlation/request IDs, user IDs, relevant state at the point of failure
- **NestJS-aware** — suggests interceptors for request lifecycle, exception filters for
  centralised error logging, and the `new Logger(ClassName.name)` pattern throughout
- **Mongoose** — debug-level query logging, never logs connection strings
- **Redacts sensitive data** — never logs passwords, JWTs, tokens, secrets, or PII

## How to trigger it

### Claude Code / Cowork
Say something like:

- *"Add logging to this service"*
- *"Add log statements to my NestJS auth module"*
- *"Improve the logging in this Express router"*
- *"What should I log in this controller?"*
- *"Instrument this service for production observability"*
- *"My logs are useless in production — fix them"*
- *"Add structured logging with pino"*

Works with a single function, a full file, or an entire NestJS module directory.

### GitHub Copilot (cloud agent)
After [installing the skill](#installing), Copilot selects it automatically. You can also
invoke it explicitly:

- *"Use the log-writer skill on src/orders/"*
- *"Add production logging to this NestJS service using log-writer"*

## Installing

### Claude Code

```bash
# Global — available in every project
cp SKILL.md ~/.claude/skills/log-writer.md

# Project-specific — only in that project
mkdir -p .claude/skills
cp SKILL.md .claude/skills/log-writer.md
```

### Cowork
1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

### GitHub Copilot (cloud agent)

```bash
mkdir -p .github/skills/log-writer
curl -o .github/skills/log-writer/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/log-writer/SKILL.md
```

## Output

Returns the **modified file(s)** with log statements added inline, followed by a
**Logging Summary** explaining:

- Framework used and any new import/dependency added
- Lines added, broken down by level
- What was logged and why, per method
- Sensitive fields present but excluded
- Follow-up recommendations (e.g. "add a LoggingInterceptor", "use pino-http middleware")

### Example output (NestJS service)

```typescript
@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  async createOrder(userId: string, dto: CreateOrderDto): Promise<Order> {
    this.logger.debug('Creating order', { userId, itemCount: dto.items.length });
    try {
      const order = await this.ordersRepository.save({ ...dto, userId });
      this.logger.log('Order created', { orderId: order.id, userId });
      return order;
    } catch (err) {
      this.logger.error('Failed to create order', err.stack, { userId });
      throw err;
    }
  }
}
```

```
## Logging Summary

**Framework used**: NestJS built-in Logger — matched existing usage
**Lines added**: 4
**Levels used**: debug (1), log (1), error (1)

**What was logged and why**:
- `OrdersService.createOrder()` — debug on entry with userId and item count (not DTO body);
  log on success with orderId; error with stack on DB failure

**Sensitive fields excluded**: none identified in this method
**Recommendations**: Add a LoggingInterceptor to capture request/response lifecycle
  centrally instead of logging in every controller method.
```

## Log level reference (NestJS / pino)

| Level | NestJS | pino | When |
|---|---|---|---|
| Trace/Verbose | `logger.verbose()` | `log.trace()` | Internals — dev only |
| Debug | `logger.debug()` | `log.debug()` | Inputs, branches — off in prod |
| Info | `logger.log()` | `log.info()` | Normal events |
| Warn | `logger.warn()` | `log.warn()` | Unexpected but recoverable |
| Error | `logger.error()` | `log.error()` | Failed operation |

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition — works in Claude Code, Cowork, and GitHub Copilot unchanged |
| `evals/evals.json` | Test cases: NestJS auth service, Express router with pino-http, bad existing logs to fix |
