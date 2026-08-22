-- ============================================================================
-- Ericka Portal — database schema + seed
-- Run ONCE in Supabase: Dashboard → SQL Editor → paste this whole file → Run.
--
-- Design notes:
--  * Every row carries client_id so "a client sees only their own VAs" is a
--    one-column filter now, and Row-Level Security (RLS) is a switch-on later.
--  * pay_rate is NEVER selected by any client-facing query (see app.js). The
--    client only ever sees billable_rate. This is enforced in the app for the
--    bones; column-level DB enforcement comes with the RLS hardening step.
--  * Auth = name + PIN (matches the mockup + sia-training). No Supabase Auth yet.
-- ============================================================================

-- Clean re-run support (safe to run repeatedly during setup) --------------
drop table if exists performance_metrics cascade;
drop table if exists training_progress   cascade;
drop table if exists timesheets          cascade;
drop table if exists training_modules    cascade;
drop table if exists users               cascade;
drop table if exists clients             cascade;

-- Clients / tenants -------------------------------------------------------
create table clients (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  vertical   text not null check (vertical in ('medical','dental')),
  created_at timestamptz default now()
);

-- Users: admin | va | client_admin ---------------------------------------
create table users (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  pin           text not null,
  role          text not null check (role in ('admin','va','client_admin')),
  client_id     uuid references clients(id),        -- null for admin (sees all)
  vertical      text check (vertical in ('medical','dental')),
  billable_rate numeric(8,2) default 0,             -- what the CLIENT is billed / hr  (client-visible)
  pay_rate      numeric(8,2) default 0,             -- what the VA is paid / hr         (NEVER shown to a client)
  active        boolean default true,
  created_at    timestamptz default now()
);
create index on users (client_id);
create index on users (role);

-- Training modules (content packs per vertical) ---------------------------
create table training_modules (
  id               uuid primary key default gen_random_uuid(),
  vertical         text not null check (vertical in ('medical','dental')),
  ord              int  not null,                    -- display order 1..n
  title            text not null,
  icon             text default '📘',
  capability_label text not null,                    -- the skill a finished module PROVES
  created_at       timestamptz default now()
);
create index on training_modules (vertical, ord);

-- Training progress (drives training volume + capabilities) ---------------
create table training_progress (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references users(id) on delete cascade,
  module_id    uuid not null references training_modules(id) on delete cascade,
  status       text not null default 'completed' check (status in ('completed')),
  completed_at timestamptz default now(),
  unique (user_id, module_id)
);
create index on training_progress (user_id);

-- Timesheets (clock in / out; hours computed in the app from the stamps) --
create table timesheets (
  id         uuid primary key default gen_random_uuid(),
  va_id      uuid not null references users(id) on delete cascade,
  client_id  uuid references clients(id),
  clock_in   timestamptz not null default now(),
  clock_out  timestamptz,                            -- null = still clocked in
  status     text not null default 'pending' check (status in ('pending','approved')),
  created_at timestamptz default now()
);
create index on timesheets (va_id);
create index on timesheets (client_id);

-- Performance metrics (structured placeholder — fed later) ----------------
create table performance_metrics (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  client_id  uuid references clients(id),
  label      text not null,
  value      text not null,
  period     text,
  created_at timestamptz default now()
);
create index on performance_metrics (user_id);

-- ============================================================================
-- Grants for the public "anon" API role (bones: app-level filtering).
-- Read-only on reference tables; write only where a VA legitimately writes.
-- Tighten to RLS before any arm's-length paying client.
-- ============================================================================
grant usage on schema public to anon;
grant select on clients, users, training_modules, training_progress,
                timesheets, performance_metrics to anon;
grant insert, update on timesheets        to anon;   -- clock in / clock out
grant insert          on training_progress to anon;  -- mark a module complete

-- ============================================================================
-- SEED
-- ============================================================================

-- Clients
insert into clients (id, name, vertical) values
  ('11111111-1111-1111-1111-111111111111','SIA Medical','medical'),
  ('22222222-2222-2222-2222-222222222222','SIA Dental','dental');

-- Users  (PINs are demo values — change them in the Table editor anytime)
insert into users (id, name, pin, role, client_id, vertical, billable_rate, pay_rate) values
  -- Ericka admin (you) — sees everything
  ('a0000000-0000-0000-0000-000000000001','Edison Nguyen','1988','admin', null, null, 0, 0),
  -- SIA Medical client admin — view-only, scoped to SIA Medical
  ('c0000000-0000-0000-0000-000000000001','Nikki (SIA Medical)','2024','client_admin','11111111-1111-1111-1111-111111111111','medical',0,0),
  -- SIA Medical VAs
  ('b0000000-0000-0000-0000-000000000001','Bea Villanueva','1111','va','11111111-1111-1111-1111-111111111111','medical',35,12),
  ('b0000000-0000-0000-0000-000000000002','Joy Tolentino','2222','va','11111111-1111-1111-1111-111111111111','medical',35,12),
  -- SIA Dental VA (proves isolation — must NOT appear in SIA Medical's board)
  ('b0000000-0000-0000-0000-000000000003','Ericka Dela Cruz','3333','va','22222222-2222-2222-2222-222222222222','dental',33,11);

-- Medical training pack (6 modules)
insert into training_modules (id, vertical, ord, title, icon, capability_label) values
  ('d1000000-0000-0000-0000-000000000001','medical',1,'Welcome & the Ericka Way','👋','Ericka Standard'),
  ('d1000000-0000-0000-0000-000000000002','medical',2,'Medical Front-Desk Calls','📞','Phone Triage'),
  ('d1000000-0000-0000-0000-000000000003','medical',3,'Practice Software','💻','Practice Software'),
  ('d1000000-0000-0000-0000-000000000004','medical',4,'Medicare & Bulk Billing','🩺','Medicare & Billing'),
  ('d1000000-0000-0000-0000-000000000005','medical',5,'Results & Recalls','📋','Results & Recalls'),
  ('d1000000-0000-0000-0000-000000000006','medical',6,'Privacy & Compliance','🔒','Privacy & Compliance');

-- Dental training pack (6 modules)
insert into training_modules (id, vertical, ord, title, icon, capability_label) values
  ('d2000000-0000-0000-0000-000000000001','dental',1,'Welcome & the Ericka Way','👋','Ericka Standard'),
  ('d2000000-0000-0000-0000-000000000002','dental',2,'Phone & Booking Skills','📞','Phone & Booking'),
  ('d2000000-0000-0000-0000-000000000003','dental',3,'Dental4Web (D4W)','💻','D4W'),
  ('d2000000-0000-0000-0000-000000000004','dental',4,'Billing & HICAPS','💳','Billing & HICAPS'),
  ('d2000000-0000-0000-0000-000000000005','dental',5,'Dental Basics & Lingo','🦷','Dental Basics'),
  ('d2000000-0000-0000-0000-000000000006','dental',6,'Recalls & Reactivation','🔁','Recalls & Reactivation');

-- Seed training progress: Bea = 4/6, Joy = 3/6
insert into training_progress (user_id, module_id) values
  ('b0000000-0000-0000-0000-000000000001','d1000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-000000000001','d1000000-0000-0000-0000-000000000002'),
  ('b0000000-0000-0000-0000-000000000001','d1000000-0000-0000-0000-000000000003'),
  ('b0000000-0000-0000-0000-000000000001','d1000000-0000-0000-0000-000000000004'),
  ('b0000000-0000-0000-0000-000000000002','d1000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-000000000002','d1000000-0000-0000-0000-000000000002'),
  ('b0000000-0000-0000-0000-000000000002','d1000000-0000-0000-0000-000000000003');

-- Seed a couple of completed shifts this week so hours show (relative to now)
insert into timesheets (va_id, client_id, clock_in, clock_out, status) values
  ('b0000000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111', now() - interval '1 day 8 hours', now() - interval '1 day', 'approved'),
  ('b0000000-0000-0000-0000-000000000002','11111111-1111-1111-1111-111111111111', now() - interval '1 day 6 hours', now() - interval '1 day', 'pending');

-- performance_metrics intentionally left EMPTY — the client card shows
-- "no data yet" until real performance data is fed in.
