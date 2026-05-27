---
name: log-writer
description: >
  Use this skill when a developer wants to add logging to their Node.js, Express, or NestJS
  code, improve existing log statements, or audit logging for production readiness. Trigger on
  phrases like "add logging", "add log statements", "improve my logs", "log this function",
  "what should I log here", "logging best practices", "structured logging", "add observability",
  "instrument this code", "my logs are useless", or any request to make a MEAN stack service
  easier to debug or monitor in production. Works with single functions, Express route handlers,
  NestJS services/controllers/interceptors, or whole modules. Detects the existing logging
  setup (pino, winston, NestJS Logger, morgan) automatically and follows its conventions.
allowed-tools:
  - shell
---

# Log Writer

You are adding or improving logging in a Node.js / Express / NestJS codebase. Your job is
to produce log statements that are actually useful on call at 2 AM — structured, leveled,
full of context, and completely free of sensitive data.

## Step 1 — Detect the stack before writing anything

Check imports, `package.json`, and existing log calls to identify:

| What to look for | Means |
|---|---|
| `new Logger(ClassName.name)` or `@nestjs/common` Logger | NestJS built-in logger |
| `import { Logger } from 'nestjs-pino'` | NestJS + pino via `nestjs-pino` |
| `nest-winston` / `WinstonModule` | NestJS + winston |
| `pino(...)` / `require('pino')` | Plain pino |
| `winston.createLogger(...)` | Plain winston |
| `morgan(...)` in middleware | HTTP access logging (Express) |
| `console.log` everywhere | No real logging — introduce pino or winston |

**Never introduce a second logging library** if one already exists. If there is no logger,
default to **pino** for Express projects and **NestJS Logger** (or `nestjs-pino`) for NestJS.

---

## Log level guide

| Level | NestJS method | pino / winston | When to use |
|---|---|---|---|
| `verbose` / `trace` | `logger.verbose()` | `log.trace()` | Fine-grained internals, loop state — dev only |
| `debug` | `logger.debug()` | `log.debug()` | Inputs, branch taken, DB query params — off in prod |
| `log` / `info` | `logger.log()` | `log.info()` | Normal events: request in, job done, user registered |
| `warn` | `logger.warn()` | `log.warn()` | Recoverable unexpected: retry, deprecated path, slow query |
| `error` | `logger.error()` | `log.error()` | Failed operation: unhandled exception, DB write failed |
| `fatal` | *(use error + process.exit)* | `log.fatal()` | Unrecoverable: startup failure, missing critical config |

Default to the **lowest level that fits**. Noisy `info` logs are as bad as missing `error` logs.

---

## NestJS patterns

### Services and repositories
Use `private readonly logger = new Logger(ServiceName.name)` — the class name becomes
the context label in every log line automatically.

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

### Controllers
Log at the controller level only when the route itself has meaningful business significance
(e.g. auth events, destructive actions). Routine CRUD request/response logging belongs in
an **interceptor**, not in every controller method.

```typescript
@Post('login')
async login(@Body() dto: LoginDto, @Req() req: Request) {
  const user = await this.authService.validateUser(dto.email, dto.password);
  if (!user) {
    this.logger.warn('Login failed — invalid credentials', { email: dto.email });
    throw new UnauthorizedException();
  }
  this.logger.log('Login successful', { userId: user.id });
  // ...
}
```

### Interceptors — request/response lifecycle
Prefer a **logging interceptor** over logging in every controller. This is the right place
for timing and HTTP-level logs.

```typescript
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const { method, url } = req;
    const correlationId = req.headers['x-correlation-id'] ?? randomUUID();
    const start = Date.now();

    return next.handle().pipe(
      tap(() =>
        this.logger.log('Request completed', {
          method, url, correlationId,
          durationMs: Date.now() - start,
        }),
      ),
      catchError((err) => {
        this.logger.error('Request failed', err.stack, {
          method, url, correlationId,
          durationMs: Date.now() - start,
        });
        return throwError(() => err);
      }),
    );
  }
}
```

### Exception filters
Use a global exception filter to log unhandled exceptions in one place rather than
`try/catch` in every service.

```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const req = ctx.getRequest<Request>();
    const status = exception instanceof HttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;

    if (status >= 500) {
      this.logger.error('Unhandled exception', exception instanceof Error ? exception.stack : String(exception), {
        method: req.method,
        url: req.url,
        correlationId: req.headers['x-correlation-id'],
      });
    } else {
      this.logger.warn('Client error', { status, url: req.url });
    }
    // send response...
  }
}
```

---

## Express patterns

### Application startup
```typescript
const logger = pino({ level: process.env.LOG_LEVEL ?? 'info' });

app.listen(port, () => {
  logger.info({ port, env: process.env.NODE_ENV, version: process.env.npm_package_version },
    'Server started');
});
```

### HTTP access logging with pino-http
Prefer `pino-http` over `morgan` for JSON-structured access logs:
```typescript
import pinoHttp from 'pino-http';
app.use(pinoHttp({ logger }));
// req.log is now available in all route handlers with the request bound
```

### Route handlers
```typescript
router.post('/orders', async (req, res, next) => {
  const { userId } = req.user;
  req.log.debug({ body: req.body }, 'Creating order');
  try {
    const order = await ordersService.create(userId, req.body);
    req.log.info({ orderId: order.id, userId }, 'Order created');
    res.status(201).json(order);
  } catch (err) {
    next(err); // let the error middleware log it
  }
});
```

### Centralised error middleware
```typescript
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  req.log.error({ err, url: req.url, method: req.method }, 'Request failed');
  res.status(500).json({ error: 'Internal server error' });
});
```

---

## MongoDB / Mongoose

Log at `debug` level around significant queries; do **not** log inside loops or paginated
result processing at `info` or above.

```typescript
logger.debug({ filter, projection }, 'Querying users');
const users = await User.find(filter, projection).limit(100);
logger.debug({ count: users.length }, 'Users query complete');
```

Enable Mongoose debug mode only in development via env var:
```typescript
mongoose.set('debug', process.env.NODE_ENV === 'development');
```

---

## Correlation IDs

Every log line for a single request should share a correlation ID so you can filter
across services in Datadog / CloudWatch / Loki.

- **Express**: add `x-correlation-id` request header handling in middleware; attach to
  `req.log` (pino-http does this automatically if the header exists)
- **NestJS**: read `x-correlation-id` header in an interceptor; store in
  `AsyncLocalStorage` or pass explicitly; include in every logger call

---

## Structured logging rules

Always prefer key-value / object fields over template strings — structured logs are
queryable.

```typescript
// ✗ avoid
logger.info(`User ${userId} placed order ${orderId} for $${amount}`);

// ✓ prefer
logger.info({ userId, orderId, amountCents }, 'Order placed');
```

---

## Security — never log these

- Passwords, PINs, secrets, API keys, JWTs, session tokens
- Full credit card numbers, CVVs, bank account numbers
- SSNs or government IDs
- Raw `req.body` when it might contain the above
- Full Mongoose connection strings (they contain credentials)

If a variable name contains `password`, `secret`, `token`, `key`, `auth`, `credential`,
`jwt`, `cvv`, or `ssn` — log `'[REDACTED]'` or omit it entirely.

---

## Performance

- **Guard verbose/debug calls** that serialize large objects:
  ```typescript
  if (logger.isLevelEnabled('debug')) {
    logger.debug({ snapshot: heavySerialize(state) }, 'State snapshot');
  }
  ```
- **Never log at info+ inside a hot loop** — log before and after with counts/durations
- **Use `err.stack` not `err.message`** in error calls — stacks include the message and are far more useful

---

## Output format

Return the **modified file(s)** with log statements added inline, then append:

```
## Logging Summary

**Framework used**: <pino / winston / NestJS Logger / nestjs-pino — and any new import/dep added>
**Lines added**: N
**Levels used**: debug (N), info (N), warn (N), error (N)

**What was logged and why**:
- `ClassName.methodName()` — info on entry with key params; error with stack on exception
- Interceptor added — replaces per-controller request/response logging
- …

**Sensitive fields excluded**: <list any fields present but not logged>
**Recommendations**: <e.g. "add pino-http middleware for HTTP access logs", "consider a global exception filter">
```

If the file is very large, produce a **diff-style summary** (exact lines to add and where)
followed by the Logging Summary instead of rewriting the whole file.
