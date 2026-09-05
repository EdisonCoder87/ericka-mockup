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
| Client (`client_admin`, view only) | Nikki (SIA Medical) · Radmila Dusanovic |
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
