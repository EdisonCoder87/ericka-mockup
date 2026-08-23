-- ============================================================================
-- Ericka Portal — migration 06: full performance scorecard
-- Redesigns `productivity` to hold the grouped inbound/outbound metrics, and
-- adds `perf_rates` (CP & HA bulk-billed values) for auto-calculated revenue.
-- Run via run_migrations.js ("Run without RLS"). Re-runnable.
-- ============================================================================

drop table if exists productivity cascade;

create table productivity (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references users(id) on delete cascade,
  client_id          uuid references clients(id),
  period_label       text not null,
  -- Inbound
  calls_inbound      int default 0,
  scans              int default 0,
  -- Outbound · Confirmation
  confirmation_calls int default 0,
  -- Outbound · Arrears  (revenue = collected $, entered)
  arrears_total      int default 0,
  arrears_answered   int default 0,
  arrears_collected  numeric(10,2) default 0,
  -- Outbound · Care Plan Review  (revenue = booked x cp_value, auto)
  cpr_total          int default 0,
  cpr_picked_up      int default 0,
  cpr_booked         int default 0,
  -- Outbound · Health Assessment (revenue = booked x ha_value, auto)
  ha_due             int default 0,
  ha_picked_up       int default 0,
  ha_booked          int default 0,
  notes              text,
  updated_by         uuid references users(id),
  updated_at         timestamptz default now(),
  unique (user_id, period_label)
);
create index on productivity (user_id, updated_at desc);
create index on productivity (client_id);
grant select, insert, update on productivity to anon;

-- Configurable bulk-billed values used to auto-calc CP & HA revenue.
create table if not exists perf_rates (
  id         int primary key default 1,
  cp_value   numeric(10,2) default 79.70,    -- Care Plan Review (item 732) rebate
  ha_value   numeric(10,2) default 246.65,   -- Health Assessment (item 705) rebate
  updated_at timestamptz default now(),
  check (id = 1)
);
grant select, insert, update on perf_rates to anon;
insert into perf_rates (id) values (1) on conflict (id) do nothing;

-- Sample rows (team lead overwrites via the Team page)
insert into productivity (user_id, client_id, period_label,
  calls_inbound, scans, confirmation_calls,
  arrears_total, arrears_answered, arrears_collected,
  cpr_total, cpr_picked_up, cpr_booked,
  ha_due, ha_picked_up, ha_booked, notes)
select u.id, u.client_id, 'Week of 18 Aug 2026',
  142, 34, 96,  28, 15, 740.00,  45, 26, 18,  20, 11, 7, 'Sample - replace via Team page'
from users u where u.name = 'Bea Villanueva'
on conflict (user_id, period_label) do nothing;

insert into productivity (user_id, client_id, period_label,
  calls_inbound, scans, confirmation_calls,
  arrears_total, arrears_answered, arrears_collected,
  cpr_total, cpr_picked_up, cpr_booked,
  ha_due, ha_picked_up, ha_booked, notes)
select u.id, u.client_id, 'Week of 18 Aug 2026',
  118, 22, 70,  20, 9, 415.00,  33, 17, 11,  14, 6, 4, 'Sample - replace via Team page'
from users u where u.name = 'Joy Tolentino'
on conflict (user_id, period_label) do nothing;
