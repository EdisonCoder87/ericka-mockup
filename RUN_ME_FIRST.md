# Ericka Portal — read this when you wake up ☀️

Everything's built and pushed. There's **one manual step only you can do**: run the SQL
migrations in Supabase (I can't run database changes with just the public key).

## 1. Run the migrations — in this exact order
Supabase → **SQL Editor** → **New query** → paste the whole file → **Run** (choose
**"Run without RLS"** each time). Do them in order:

1. `migration_01_sites.sql` — sites (Footscray/Essendon) + Grace *(skip if you already ran it)*
2. `migration_02_structure.sql` — 16 modules + the team-lead role
3. `migration_03_content.sql` — all module content + the Footscray cheat sheet
4. `migration_04_quizzes.sql` — the quizzes

Each should say **"Success. No rows returned."** If one errors, stop and tell me the message —
don't run the later ones.

## 2. Live site
https://edisoncoder87.github.io/ericka-mockup/ (give it ~1 min to rebuild after you push)

## 3. Log in and test (PINs)
| Role | Name | PIN |
|---|---|---|
| Admin (you) | Edison Nguyen | **1988** |
| Team Lead | Joan Cruz (Team Lead) | **5555** |
| SIA Medical (client) | Nikki (SIA Medical) | **2024** |
| Medical VA · Footscray | Bea Villanueva | **1111** |
| Medical VA · Essendon | Joy Tolentino | **2222** |
| Medical VA · Footscray | Grace Mendoza | **4444** |
| Dental VA | Ericka Dela Cruz | **3333** |

### What to check
- **Bea (1111):** *My Training* splits **Onboarding (6)** + **Training (10)**. Open a module → read
  the content → **take the quiz** → pass (≥75%) to complete it. **📇 Footscray Cheat Sheet** is in her sidebar.
- **Joy (2222):** same tracks, but **no cheat sheet link** (she's Essendon — site-scoping works).
- **Joan (5555):** lands on the **Team view** — whole remote team grouped by client → site, onboarding
  + training progress, tap a VA for their checklist.
- **Edison (1988):** Home → **Team** opens that same board.
- **Nikki (2024):** her VA cards show **Onboarding + Training** split; tap for the grouped checklist.

## 4. What's new this session
- **16 modules** of real content pulled from the Footscray manual (6 onboarding + 10 training).
- **Quizzes** on every module except the onboarding gateway — passing is what marks a module complete,
  with per-question feedback + retry.
- **Footscray Cheat Sheet** — doctors/rooms, availability & rules, fees, treatment-room fees, staff
  languages, allied health, difficult-situation scripts, and systems (passwords deliberately **not** stored).
- **Team-lead role** + whole-team progress board.

## 5. Deliberately deferred (needs your go-ahead)
- **AI phone-call practice** — this needs a small server + API keys + real per-call spend (Sonnet +
  text-to-speech + speech-to-text), so I didn't switch it on unsupervised. Design notes are in
  `AI_CALLS_DESIGN.md` for when you want to green-light it.
- **Live admin CRUD** (add VAs / set PIN / site from the UI) — skipped for now because it needs the
  database opened up for writes, which isn't safe until RLS is on. For now, add/edit people in the
  **Supabase Table editor** (the `users` table).

## Known debt (unchanged)
No RLS yet — fine for SIA Medical (friendly, no patient data here). Before any arm's-length paying
client: turn on Supabase Auth + Row-Level Security (the schema is already RLS-ready).
