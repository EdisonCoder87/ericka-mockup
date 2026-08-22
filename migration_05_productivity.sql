-- ============================================================================
-- Ericka Portal — migration 05: VA productivity (team-lead entered)
-- Run in Supabase SQL Editor / via run_migrations.js ("Run without RLS").
-- The team lead reads objective counts from 3CX (calls) and HotDoc/Pracsoft
-- (bookings) and enters them per VA per period. Nikki sees them at a glance.
-- Re-runnable.
-- ============================================================================

create table if not exists productivity (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references users(id) on delete cascade,
  client_id    uuid references clients(id),
  period_label text not null,               -- e.g. "Week of 18 Aug 2026"
  calls        int default 0,               -- 3CX phone calls handled
  bookings     int default 0,               -- HotDoc / Pracsoft bookings made
  payments     int default 0,               -- payments processed
  notes        text,
  updated_by   uuid references users(id),
  updated_at   timestamptz default now(),
  unique (user_id, period_label)
);
create index if not exists productivity_user_idx on productivity (user_id, updated_at desc);

-- Team lead / admin enter these from the frontend (anon key). Low-sensitivity
-- data; RLS will scope who-can-write later (documented debt).
grant select, insert, update on productivity to anon;

-- Sample rows so Nikki's view + the design are visible immediately.
-- The team lead can overwrite these via the Team page.
insert into productivity (user_id, client_id, period_label, calls, bookings, payments, notes)
select u.id, u.client_id, 'Week of 18 Aug 2026', 128, 64, 19, 'Sample — replace via Team page'
from users u where u.name = 'Bea Villanueva'
on conflict (user_id, period_label) do nothing;

insert into productivity (user_id, client_id, period_label, calls, bookings, payments, notes)
select u.id, u.client_id, 'Week of 18 Aug 2026', 96, 41, 12, 'Sample — replace via Team page'
from users u where u.name = 'Joy Tolentino'
on conflict (user_id, period_label) do nothing;
