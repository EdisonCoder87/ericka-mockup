# Ericka Portal — current state

Live at **https://portal.ericka.com.au** (GitHub Pages + Supabase; no server, $0/mo to run).

## 1. Migrations — Claude runs these for you
Run directly via the Supabase Management API, so you never touch the SQL editor:

```
SUPABASE_PAT=sbp_… node run_migrations.js <file.sql>
```

| # | File | What it does |
|---|---|---|
| 01 | `migration_01_sites.sql` | sites (Footscray / Essendon) |
| 02 | `migration_02_structure.sql` | 16 modules + the team-lead role |
| 03 | `migration_03_content.sql` | module content + the Footscray cheat sheet |
| 04 | `migration_04_quizzes.sql` | the quizzes |
| 05–06 | `migration_05/06_*.sql` | the performance scorecard + revenue rates |
| 07 | `migration_07_real_team.sql` | the real 4-tier access model |
| 08 | `migration_08_tighten_grants.sql` | security: revoke anon DELETE/TRUNCATE |
| 09 | `migration_09_general_va.sql` | General VAs (no clinic) |
| 10 | `migration_10_roster_metrics.sql` | rostered hours · answer rate · orderable periods · dental metrics · AI-track columns |
| 11 | `migration_11_ai_modules.sql` | the 11 AI certification modules + content |
| 12 | `migration_12_ai_quizzes.sql` | quizzes for the AI track |
| 13 | `migration_13_demo_clinics.sql` | the two demo clinics Grace demos from |
| 14 | `migration_14_period_key.sql` | keys a performance row on its week, not its label |
| 15 | `migration_15_hide_pin_and_pay.sql` | public key can no longer read `pin` or `pay_rate` |
| 16 | `migration_16_approvals_roster.sql` | **daily approvals · operator-managers · visual roster · extra-hours authorisation** |
| 17 | `migration_17_clean_names.sql` | real names only (drops "(SIA Medical)" etc.) · demo accounts deactivated |

**⚠️ Never re-run 05 or 06** — they drop the `productivity` table.
**⚠️ Never re-run 03 or 04 after 11/12** — they wipe *all* module content / quizzes, AI track included.

## 2. Before a client demo — refresh the demo data
Demo timesheets are seeded relative to the current week, so they go stale after Sunday.
One command puts them back:

```
SUPABASE_PAT=sbp_… node run_migrations.js migration_13_demo_clinics.sql
```

## 3. Who logs in

**Every account is on PIN `1234`** (reset 2026-09-05 for handover). Pick the name from the
dropdown, type 1234. Each person changes theirs on first login — client and VA via
**My Account**, owner and manager via the **Admin** page.

| Tier | Who |
|---|---|
| Owner (`admin`) | Edison Nguyen · Grace Sia |
| Ericka Manager (`manager`) | Shane · Sharica |
| Client (`client_admin`, view only) | Nikki · Radmila Dusanovic |
| Remote member (`va`) | the real team |
| **Demo owner — dental** | Demo Owner (Dental) |
| **Demo owner — medical** | Demo Owner (Medical) |

Grace demos from **Demo Owner (Dental)** or **Demo Owner (Medical)**. Both are seeded demo
clinics — the real SIA Medical account stays truthful and is never dressed up with invented
numbers.

To put everyone back on 1234 later (e.g. before another handover):

```sql
update users set pin = '1234';
```

## 4. What a client sees on their page
- **Coverage** — who is clocked in right now, and hours covered per day this week.
- **Performance** — the last completed week from the weekly reports, with week-on-week
  deltas and a period picker. Metrics switch on the vertical: a dental owner sees recalls,
  failed appointments and unscheduled treatment; a GP sees Care Plan Reviews and Health
  Assessments. Both see answer rate.
- **Per member** — onboarding / training / AI certification bars, capabilities, hours this
  week **against their roster** (with an on-pace / behind read), and billable value.

## 5. Rostered hours
One number per member (`users.rostered_hours`) — no weekly typing. Set it in **Team →
tap a member → Save roster**, or inline on the **Admin** page. Managers may edit it
(it is not pay data). The client sees actual vs rostered, pro-rated to how far through
the week it is, so nobody reads as "behind" at 9am on a Tuesday.

## 6. AI certification
Two tiers a member earns, shown to the client as a badge:
- **🤖 AI Assisted** (6 modules) — uses AI to problem-solve, communicate and write process.
- **🛠️ AI Builder** (5 modules) — builds small tools and automations with Claude Code.

Each tier ends in a **practical**: the member pastes a link to real work on the module page,
and a manager signs it off in **Team → tap a member → Practicals submitted**. The badge only
lights once that is verified — a badge a quiz alone can mint is worth nothing to a client.

## Known debt
- **No RLS yet.** Fine while every client is friendly. Before an arm's-length paying client
  gets a login: switch on Supabase Auth + Row-Level Security (the schema is RLS-ready).
  Migration 15 closed the sharpest edge — the public key can no longer read `pin` or
  `pay_rate`, so nobody can lift Ericka's margin off the page — but it can still read
  `billable_rate`, and it can still WRITE to the tables the browser writes to. Those need
  real logins the database can verify, not app-level role checks.
- **3CX numbers are typed in.** Send one real weekly report and the entry form can take a
  paste/upload instead.
- **Practical sign-off is enforced in the app, not the database.** With RLS off, the public
  key can write to `training_progress` directly, so a determined member could mint their own
  AI badge. Same gate as everything else — it closes when RLS goes on.
- The demo clinics live in the live database. They are hidden from managers and labelled
  "Demo" for owners — delete them once a real dental client is onboarded.

---

## Going live — the timesheet loop (from 7 Sep 2026)

The four SIA Medical VAs clock on for real, Shane and Sharica sign the hours off,
and the week closes into a Xero invoice. Four pages carry it:

| Page | Who | What they do there |
|---|---|---|
| `07_va_timesheet.html` | every member | Clock in / clock out. One clock, no second system. |
| `09_roster.html` | Shane, Sharica, Edison (Rad + Nikki read-only) | The Mon–Fri grid — who is on and when, grouped by site, with a site toggle. |
| `12_approvals.html` | Shane, Sharica (Edison sees everyone) | Daily sign-off, correcting a forgotten clock-out, and recording the client's authorisation for extra hours. |
| `13_export.html` | Edison, Shane, Sharica | Close the period → three CSVs. |

### Who approves whom
`users.manager_id` decides it, and it is set on the **Admin page** (the *Approved by* column).
Seeded by migration 16:

| Member | Site | Approved by |
|---|---|---|
| Eunice Joana Go, Lyca De Guzman | Footscray | **Shane** |
| Kem Acibo | General VA | **Shane** |
| Sheila Babiera, Leemay Sierra | Essendon | **Sharica** |
| **Shane** (her own seat) | Footscray | **Shane** |
| **Sharica** (her own seat) | Essendon | **Sharica** |

Shane and Sharica keep `role = 'manager'` and gain `is_operator = true`. That flag is
what puts them in a seat: they clock on, their hours bill, and they appear on the
client board and the roster like anyone else — while keeping the approval power.
They approve their own hours because `manager_id` points at themselves.

### The roster is STANDING — it already repeats
`roster_shifts` stores a **weekday**, not a date. Set someone's pattern once and it applies
every week from then on; nobody re-enters it weekly. Change it only when a person's regular
days actually change. **Copy from…** on each row clones a colleague's pattern, so setting up
a team who work the same days is one click per person.

Shane and Sharica each have their **own** roster row (they hold seats), alongside the people
they manage.

**A one-off extra shift does not go in the roster.** The VA just clocks the hours; the week
then reads as over-roster on Approvals, and Shane clears it by recording Rad's or Nikki's
authorisation. That keeps the base roster stable and every extra hour evidenced — putting
one-offs in the roster would permanently raise the ceiling that the authorisation gate
depends on.

### Rostered hours are DERIVED
Save a roster on `09_roster.html` and the weekly total is written back to
`users.rostered_hours`. There is deliberately **no** hours input on the admin page any
more — two places to set one number is how the client card and the roster end up
disagreeing.

### Extra hours need the client's message
Approvals blocks any shift that would push a week past `rostered_hours` + whatever
has already been authorised. To clear it, Shane records **who** asked (Rad or Nikki),
**how many** hours, and **pastes their actual message** into `hours_authorisations`.
The evidence stays attached to that week. This is not advisory — the Approve button
is disabled until the row exists.

### Closing a pay cycle (Sundays)
`13_export.html` → pick the period → check the warning bars (open shifts, unapproved
hours, missing rates) → fill the invoice number → three downloads:

1. **`xero_invoice_<period>.csv`** — Xero → *Business → Invoices → Import*.
   Every line repeats the same `*InvoiceNumber`, so Xero builds **one** invoice to
   SIA Medical with a line per person. Defaults: account `200`, `GST on Income`,
   7-day terms (MSA cl 4.3). **The contact name must match the Xero contact exactly**
   or Xero creates a duplicate contact.
2. **`hours_<paydate>.csv`** — drop into `ericka-bpo/payroll/`, run `build_wise_batch.py`.
   Hours only; pay rates live in `va_roster.csv` and never touch the portal.
3. **`timesheet_detail_<period>.csv`** — every shift behind the totals, including who
   edited what. Keep it with the invoice.

**Only approved, closed shifts bill.** An open shift or an unapproved one is reported
in the warning bars and left off the invoice — that is the point of the approval step.

### Still open
- **Everyone is signed out once** by migration 16 — the session key changed, because a
  session stored before it carries no `is_operator` and would lock Shane and Sharica
  out of their own timesheet page. Everyone signs back in with their PIN.
- **`billable_rate` is 0 for the whole real team, Shane and Sharica included.** They
  bill at $0 until it is set on the Admin page, and they show on Rad's board at $0.
- **No lockout on PIN guessing**, and everything is still on `1234`. Each person should
  change theirs on first login.
- **`billable_rate` is readable** by anyone who lifts the public key from the page
  source. `pay_rate` and `pin` are not (migration 15), so this exposes Ericka's
  *price list*, not its margin. Closes with RLS.
- **Writes are still app-level.** anon can write `timesheets`, so an approval is a
  record of intent, not something the database enforces. Closes with RLS + real auth.

---

## Demo accounts (Grace)

The seeded demo clinics are **deactivated** (migration 17) so they stay out of the
team's login list, the team board, the admin roster and every count. They are not
deleted — their timesheets and training rows are what make a demo look real, and
removing the user would cascade those away.

To present:

```
SUPABASE_PAT=sbp_… node run_migrations.js migration_13_demo_clinics.sql
```

That re-creates them **active** and re-anchors their timesheets to the current week
(which is what makes them go stale after Sunday). They still don't appear on the
normal login screen — open **`portal.ericka.com.au/01_welcome.html?demo=1`** to see
and sign in as `Demo Owner (Dental)` or `Demo Owner (Medical)`, PIN `1234`.

Afterwards, re-run migration 17 to put them away again:

```
SUPABASE_PAT=sbp_… node run_migrations.js migration_17_clean_names.sql
```
