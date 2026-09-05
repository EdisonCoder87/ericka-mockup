-- ============================================================================
-- Ericka Portal — migration 10: rostered hours, coverage, trends, dental set,
--                               AI-certification scaffolding, demo flag.
--   * users.rostered_hours   — the weekly roster each VA is contracted to.
--   * users.is_demo          — demo accounts, hidden from the managers' board.
--   * productivity           — missed calls, an orderable period_start, and
--                              the dental metric columns.
--   * perf_rates             — dental values (recall / FTA / unscheduled tx).
--   * training_modules       — a third category 'ai' + tier + evidence prompt.
--   * training_progress      — practical evidence + manager verification.
-- Additive only (add column if not exists) — safe to re-run.
-- ============================================================================

-- 1. Roster + demo flag -------------------------------------------------------
alter table users add column if not exists rostered_hours numeric(5,2) default 0;
alter table users add column if not exists is_demo        boolean default false;

comment on column users.rostered_hours is
  'Contracted hours per week. NOT pay data — managers may see and edit it.';
comment on column users.is_demo is
  'Demo/showcase account. Hidden from the managers'' real team board.';

-- 2. Productivity: answer rate, orderable period, dental metrics -------------
alter table productivity add column if not exists calls_missed  int  default 0;
alter table productivity add column if not exists period_start  date;

-- Dental outcome set (mirrors the medical grouping).
alter table productivity add column if not exists recall_due       int default 0;
alter table productivity add column if not exists recall_contacted int default 0;
alter table productivity add column if not exists recall_booked    int default 0;
alter table productivity add column if not exists fta_total        int default 0;
alter table productivity add column if not exists fta_contacted    int default 0;
alter table productivity add column if not exists fta_rebooked     int default 0;
alter table productivity add column if not exists otp_due          int default 0;
alter table productivity add column if not exists otp_contacted    int default 0;
alter table productivity add column if not exists otp_booked       int default 0;
alter table productivity add column if not exists new_patients     int default 0;

-- period_label is free text ('Week of 18 Aug 2026') and cannot be ordered, so
-- trends need a real date. Backfill what parses; the app sets it from here on.
update productivity
   set period_start = to_date(substring(period_label from 'Week of (.+)$'), 'DD Mon YYYY')
 where period_start is null
   and period_label ~ '^Week of \d{1,2} [A-Za-z]{3} \d{4}$';

create index if not exists productivity_period_idx on productivity (user_id, period_start desc);

-- 3. Dental revenue values ----------------------------------------------------
alter table perf_rates add column if not exists recall_value numeric(10,2) default 210.00;
alter table perf_rates add column if not exists fta_value    numeric(10,2) default 210.00;
alter table perf_rates add column if not exists otp_value    numeric(10,2) default 650.00;

comment on column perf_rates.recall_value is 'Value of a booked recall visit (exam + scale/clean).';
comment on column perf_rates.fta_value    is 'Value recovered when a failed appointment is rebooked.';
comment on column perf_rates.otp_value    is 'Average value of booked unscheduled/outstanding treatment.';

-- 4. AI certification track ---------------------------------------------------
-- A third module category alongside onboarding + training.
alter table training_modules drop constraint if exists training_modules_category_check;
alter table training_modules add constraint training_modules_category_check
  check (category in ('onboarding','training','ai'));

alter table training_modules add column if not exists tier text;              -- 'foundation' | 'builder'
alter table training_modules add column if not exists requires_evidence boolean default false;
alter table training_modules add column if not exists evidence_prompt   text;

comment on column training_modules.tier is
  'AI track tier: foundation (AI Assisted) or builder (AI Builder). Null elsewhere.';
comment on column training_modules.requires_evidence is
  'True = a quiz pass alone does not complete it; a practical must be verified.';

-- 5. Practical evidence + manager verification --------------------------------
alter table training_progress add column if not exists evidence_url text;
alter table training_progress add column if not exists verified_by  uuid references users(id);
alter table training_progress add column if not exists verified_at  timestamptz;

-- The member submits a link and a manager ticks it off — both are updates.
grant update on training_progress to anon;
