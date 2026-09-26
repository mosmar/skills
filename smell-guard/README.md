# smell-guard

A coding standard for AI agents that stops code smells from being written in the first place.

AI assistants write code fast, and they introduce code smells just as fast: god services,
`if/else` chains on type, `any` everywhere, business logic in controllers. smell-guard puts
the review checklist in front of the agent *before* the code exists. The agent reads the
rules, writes against them, and runs a self-check before showing you anything. Most smells
never reach review.

It covers all five [refactoring.guru](https://refactoring.guru/refactoring/smells) smell
categories, plus stack-specific rules for **Angular**, **NestJS**, **Express**,
**MongoDB/Mongoose** and **MSSQL (SQL Server)**.

Works with **Claude Code**, **Cowork**, **GitHub Copilot in VS Code** (agent mode and chat), and
**GitHub Copilot** (cloud agent).

## Quick start

**GitHub Copilot, for one repo.** Commit the skill to the repo:

```bash
mkdir -p .github/skills/smell-guard
curl -o .github/skills/smell-guard/SKILL.md \
  https://raw.githubusercontent.com/<your-username>/skills/main/smell-guard/SKILL.md
```

**Claude Code, for one project or all projects:**

```bash
# from a clone of this repo
./install.sh --platform claude --target .claude/skills smell-guard      # this project
./install.sh --platform claude --target ~/.claude/skills smell-guard    # every project
```

For more options, see [Install reference](#install-reference), including always-on Copilot
instructions that apply only to TS/HTML/CSS files.

## How to trigger it

smell-guard is a *standard*, not a report, so there's no special phrase to trigger it. Once
it's installed, the agent picks it up on ordinary coding requests.

### Claude Code / Cowork

- *"Add a cancel-order endpoint to the orders module"*
- *"Build an Angular component that lists the user's orders with a status filter"*
- *"Refactor this service so it's easier to test"*
- *"Write this following smell-guard"* (to invoke it explicitly)

### GitHub Copilot (VS Code agent mode / cloud agent)

- *"Add a PATCH /orders/:id/cancel route to #file:src/routes/orders.js"*
- *"Create a NestJS OrdersModule with create and list endpoints"*
- *"Refactor #selection into a presentational component"*
- *"Use the smell-guard skill while implementing this"*

## How it works

```mermaid
flowchart LR
  A[Coding request] --> B[Read smell-guard rules]
  B --> C[Write code]
  C --> D{Self-check}
  D -- fails, can fix --> C
  D -- passes --> E[Present code]
  D -- fails, request constrains it --> F[Present code + flag smell + sketch fix]
```

1. **Read.** Before writing, the agent loads the rules for the five smell categories and
   the stack.
2. **Write.** It applies the rules while generating code, not afterwards.
3. **Self-check.** It runs a checklist of about 30 items, grouped by category.
4. **Fix or flag.** If a check fails and the agent has room to fix it, it fixes it. If the
   request forces the smell (for example "add one more case to this switch"), it does what
   was asked, flags the smell and sketches the cleaner version.

## What it enforces

### The five smell categories

| Category | Smell | Rule the agent follows |
|---|---|---|
| **Bloaters** | Long Method | One job per function. A section comment (`// validate`) means extract a function |
| | Large Class | Name the single responsibility first. More than ~4 injected dependencies is too many |
| | Long Parameter List | Max 3–4 params, then use a parameter object. No boolean flag params |
| | Primitive Obsession | Branded types or value classes for IDs, emails, money and statuses |
| | Data Clumps | 3+ values that always travel together become a named type |
| **OO Abusers** | Switch Statements | No repeated `if/else` or `switch` on type/kind/role. Use polymorphism, a discriminated union with an exhaustive check, or a strategy map |
| | Temporary Field | No fields that are only valid after some method runs. Return values instead |
| | Refused Bequest | No subclass that stubs out or throws on inherited methods |
| | Alternative Classes | Same job means same interface (`getUser` vs `fetchUser` gets aligned) |
| **Change Preventers** | Divergent Change | One reason to change per class. Split unrelated concerns early |
| | Shotgun Surgery | Each concept has one home, not 5+ files to edit |
| | Parallel Hierarchies | No `XxxNotification` + `XxxHandler` pairs growing in lockstep |
| **Dispensables** | Duplicate Code | Write logic once. Put the variation in a parameter |
| | Lazy Class | No class that only wraps a single call |
| | Data Class | Objects own their behavior, not just getters and setters |
| | Dead Code | No commented-out blocks or unused methods |
| | Speculative Generality | No abstraction until the second real case exists |
| | Comments | Comments explain *why*, never *what* |
| **Couplers** | Feature Envy | A method that mostly uses another object's data moves to that object |
| | Inappropriate Intimacy | No reaching into another class's internals |
| | Message Chains | Max one hop: `order.getShippingCity()`, not `order.getCustomer().getAddress().getCity()` |
| | Middle Man | No class that only forwards calls |

### Stack specifics

| Stack | Rule | Smell it prevents |
|---|---|---|
| **Angular** | No `HttpClient` in components. Data access goes in a service | Large Class, Divergent Change |
| | Split container components from presentational ones | Divergent Change |
| | No method calls in template bindings. Use pure pipes, `computed()` or fields | Long Method, Duplicate Code |
| | No `SharedService` / `UtilsService` catch-alls | Large Class |
| | No `any`. Typed reactive forms. Statuses as string-literal unions | Primitive Obsession |
| | Styles: tokens for repeated values, no `::ng-deep` / `!important`, shallow selectors | Duplicate Code, Inappropriate Intimacy |
| **NestJS** | Thin controllers that delegate to one service call | Long Method, Divergent Change |
| | `class-validator` DTOs + `ValidationPipe`, no manual checks | Duplicate Code |
| | Throw `HttpException` subclasses or use exception filters, no per-handler try/catch | Duplicate Code |
| | Guards, interceptors and pipes for cross-cutting concerns | Shotgun Surgery |
| | Config through `ConfigService`, never scattered `process.env` | Shotgun Surgery |
| | Feature modules. No god `SharedModule`. `forwardRef()` cycles get flagged | Large Class, Inappropriate Intimacy |
| **Express** (brownfield) | Thin route handlers that call service functions | Long Method, Divergent Change |
| | One error middleware via `next(err)`, no try/catch in every route | Duplicate Code |
| | Shared validation middleware or schema (zod / joi / express-validator) | Duplicate Code |
| | One config module reads `process.env` | Shotgun Surgery |
| **Data access** (MongoDB or MSSQL) | One repository per collection or table. No DB calls in controllers or routes | Shotgun Surgery |
| | Map documents and entities to response DTOs. Never return them straight from the API | Inappropriate Intimacy |
| | Field paths, column names and statuses as shared constants, not repeated strings | Duplicate Code, Primitive Obsession |
| | No queries inside loops. Load related data in one query (join, `populate`, `include`, `IN`) | Shotgun Surgery |
| **MongoDB / Mongoose** | Document behavior in schema methods or a domain class | Data Class, Feature Envy |
| **MSSQL** (TypeORM / Prisma / Sequelize / knex / `mssql`) | Parameterized queries only. No string-built SQL, even inside the repository | Duplicate Code, security |
| | A multi-step write owns its transaction in one service or repository method | Shotgun Surgery |
| | Each stored procedure gets one typed wrapper. A business rule never lives in both a proc and app code | Duplicate Code |
| | Row behavior goes on the entity or a domain class | Data Class |

## Before / after

### Multiple variants: notification service

*"Write a notification service for email, SMS, and push"*

**Without smell-guard:**
```typescript
async send(type: string, to: string, message: string) {
  if (type === 'email') { await this.email.send(to, message); }
  else if (type === 'sms') { await this.sms.send(to, message); }
  else if (type === 'push') { await this.push.send(to, message); }
}
```

**With smell-guard:**
```typescript
interface NotificationChannel {
  send(to: Recipient, message: string): Promise<void>;
}
class EmailChannel implements NotificationChannel { ... }
class SmsChannel implements NotificationChannel { ... }
class PushChannel implements NotificationChannel { ... }
// Adding a channel = one new class, zero edits to existing code
```

### Angular: order list with a filter

*"Show the user's orders with a status filter and a Cancel button on pending orders"*

**Without smell-guard:**
```typescript
@Component({
  template: `
    <div *ngFor="let o of filterOrders()">
      {{ o.total | currency }}
      <button *ngIf="o.status === 'pending'" (click)="cancel(o)">Cancel</button>
    </div>`,
})
export class OrdersComponent {
  orders: any[] = [];
  status = '';
  constructor(private http: HttpClient) {
    this.http.get<any[]>('/api/orders').subscribe(o => (this.orders = o));
  }
  filterOrders() { return this.orders.filter(o => !this.status || o.status === this.status); }
  cancel(o: any) { this.http.post(`/api/orders/${o.id}/cancel`, {}).subscribe(); }
}
```

**With smell-guard:**
```typescript
export type OrderStatus = 'pending' | 'shipped' | 'delivered' | 'cancelled';
export interface Order { id: OrderId; status: OrderStatus; total: number; }

@Injectable({ providedIn: 'root' })
export class OrderApiService {
  private readonly http = inject(HttpClient);
  list() { return this.http.get<Order[]>('/api/orders'); }
  cancel(id: OrderId) { return this.http.post<void>(`/api/orders/${id}/cancel`, {}); }
}

export const isCancellable = (order: Order) => order.status === 'pending';

@Component({
  template: `
    @for (order of visibleOrders(); track order.id) {
      <app-order-row [order]="order" (cancel)="cancel(order)" />
    }`,
})
export class OrdersPageComponent {
  private readonly api = inject(OrderApiService);
  private readonly orders = toSignal(this.api.list(), { initialValue: [] });
  readonly statusFilter = signal<OrderStatus | null>(null);
  readonly visibleOrders = computed(() =>
    this.orders().filter(o => !this.statusFilter() || o.status === this.statusFilter()));
  cancel(order: Order) { this.api.cancel(order.id).subscribe(); }
}
```

The HTTP calls live in a service, the types are real, and the template binds to a
`computed()` signal instead of calling a method on every change-detection pass.

### NestJS: create-order endpoint

**Without smell-guard:**
```typescript
@Post()
async create(@Body() body: any) {
  try {
    if (!body.customerId) throw new BadRequestException('customerId required');
    const total = body.items.reduce((s, i) => s + i.unitPrice * i.quantity, 0);
    return await this.orderModel.create({ ...body, total, status: 'pending' });
  } catch (e) {
    throw new InternalServerErrorException(e.message);
  }
}
```

**With smell-guard:**
```typescript
export class CreateOrderDto {
  @IsMongoId() customerId: string;
  @ValidateNested({ each: true }) @Type(() => OrderItemDto) @ArrayMinSize(1)
  items: OrderItemDto[];
}

@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}
  @Post() create(@Body() dto: CreateOrderDto) { return this.orders.create(dto); }
}

@Injectable()
export class OrdersService {
  constructor(@InjectModel(Order.name) private readonly orderModel: Model<Order>) {}
  create(dto: CreateOrderDto) {
    return this.orderModel.create({ ...dto, total: orderTotal(dto.items), status: OrderStatus.Pending });
  }
}
```

### Express (brownfield): adding to a fat router

*"Add a PATCH /orders/:id/cancel route"* to a router whose existing handlers mix
validation, pricing and DB calls. smell-guard writes the **new** route cleanly and leaves
the old ones alone:

```javascript
router.patch('/orders/:id/cancel', asyncHandler(async (req, res) => {
  res.json(await orderService.cancelOrder(req.params.id));
}));
```

Then it flags the existing code instead of silently copying it:

> ⚠️ The existing `POST /orders` handler has inline validation, pricing logic, a direct
> `Order.create` call and its own try/catch. It's a candidate for the same thin-handler
> + `orderService` split. Here's a sketch: …

It won't rewrite the rest of the router, and it won't migrate it to NestJS, unless you ask.

## When it deliberately doesn't apply

- **Small tasks stay small.** A date-formatting helper is a function, not a
  `DateFormatterStrategy`.
- **Framework conventions aren't smells.** NestJS decorators, Express `(req, res, next)`,
  data-shaped Mongoose schemas and ORM entities, and Angular DI all get a pass.
- **Non-production code is relaxed.** Tests, generated code, migrations and throwaway
  scripts only need to be readable.
- **Your repo wins.** If your lint config or established conventions disagree with a rule,
  the agent follows the repo and mentions the conflict.
- **Brownfield isn't a rewrite.** New code is written cleanly, existing smells are flagged,
  and the architecture isn't touched unless you ask.

## Tuning it to your codebase

- **Thresholds.** The numbers (3–4 params, ~4 dependencies, one hop, 5+ files) are plain
  text in `SKILL.md`. Edit them to match your team's taste.
- **Stack rules.** The *Stack specifics* section is self-contained, so you can remove or
  replace it for other stacks without touching the core rules.
- **Check it works.** [`evals/evals.json`](evals/evals.json) has prompts with expected
  behavior. Run them after any edit to catch regressions.
- **Linters.** ESLint and angular-eslint catch syntax-level issues. smell-guard covers the
  design-level ones that linters can't see, such as responsibility, coupling and structure.
  Use both.

## FAQ

**Won't this make the agent over-engineer everything?**
The skill treats over-engineering as a smell too. "Apply with judgment" and the
proportionality self-check tell the agent to add structure only when the code has the
problem it solves, and eval 6 tests exactly that.

**Will it try to migrate my Express app to NestJS?**
No. In brownfield code it matches the existing structure, writes new code cleanly, and
only flags what it would change.

**Does smell-scanner call the other smell skills?**
No. smell-scanner is a triage pass. It rates each category and *recommends* which
focused skill to run next, and then you (or the agent, if you ask) run it.

**Does it slow the agent down?**
It adds a few hundred lines of context and a self-check pass. In practice that costs less
than a round of "please refactor this" follow-ups.

## Part of the code smells suite

smell-guard *prevents* smells. The other skills *find and fix* them.

| Skill | Role |
|---|---|
| **smell-guard** | Prevents smells while code is written (this skill) |
| [smell-scanner](../smell-scanner/) | Fast triage of existing code across all 5 categories, routing to a focused skill |
| [smell-bloaters](../smell-bloaters/) | Deep fix guidance for Bloaters |
| [smell-oo-abusers](../smell-oo-abusers/) | Deep fix guidance for OO Abusers (JS/TS) |
| [smell-change-preventers](../smell-change-preventers/) | Deep fix guidance for Change Preventers |
| [smell-dispensables](../smell-dispensables/) | Deep fix guidance for Dispensables |
| [smell-couplers](../smell-couplers/) | Deep fix guidance for Couplers |

A typical workflow: **smell-guard** on every coding task, **smell-scanner** on periodic
reviews, and the focused skills to clean up anything that slipped through.

## Install reference

### Claude Code

```bash
# Project-specific
mkdir -p .claude/skills
cp SKILL.md .claude/skills/smell-guard.md

# Global — all projects
cp SKILL.md ~/.claude/skills/smell-guard.md
```

Or use `./install.sh --platform claude --target <dir> smell-guard` from the repo root.

### GitHub Copilot: skill (VS Code agent mode and cloud agent)

```bash
mkdir -p .github/skills/smell-guard
cp SKILL.md .github/skills/smell-guard/SKILL.md
```

Or use `./install.sh --target <repo> smell-guard`. Copilot selects the skill from its
`description`.

### GitHub Copilot: always-on repo instructions

To make Copilot follow the rules on *every* chat and suggestion in a repo, whether or not
the skill gets selected, add them to `.github/copilot-instructions.md`. Strip the YAML
frontmatter first, because it's only for skill discovery:

```bash
awk '/^---$/ && n<2 {n++; next} n>=2' SKILL.md >> .github/copilot-instructions.md
```

### GitHub Copilot: scoped to Angular / TypeScript files

To apply the rules only to TS, HTML and CSS/SCSS files, create a path-scoped instructions
file:

```bash
mkdir -p .github/instructions
{
  printf -- '---\napplyTo: "**/*.ts,**/*.html,**/*.css,**/*.scss"\n---\n\n'
  awk '/^---$/ && n<2 {n++; next} n>=2' SKILL.md
} > .github/instructions/smell-guard.instructions.md
```

### Cowork

1. Download `SKILL.md` from this folder
2. Open Settings → Skills → Install from file

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Agent-facing coding standard: 5 smell categories, stack specifics, self-check |
| `evals/evals.json` | Eight test cases: notification service (polymorphism), document processor (no temporary fields), extending a smelly switch (flag it), Angular order list, NestJS + MongoDB create-order endpoint, Express brownfield route, a trivial helper (no over-engineering), and NestJS + TypeORM/SQL Server orders with a transactional cancel |
