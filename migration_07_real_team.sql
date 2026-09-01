-- ============================================================================
-- Ericka Portal — migration 07: go-live team + roles
--   * Adds the "manager" role (Ericka Managers — Shane & Sharica).
--   * Wipes the demo VAs / demo team-lead so real data can be populated.
--   * Seeds the real access tiers: Grace (owner/admin) + Rad (client_admin).
--   * Opens anon insert/update on users so the in-app admin page can
--     add members / reset PINs / reassign clinics (app-gated; RLS still deferred).
-- Run via run_migrations.js ("Run without RLS"). Idempotent / re-runnable.
-- ============================================================================

-- 1. Role set gains "manager" (Ericka Manager tier) --------------------------
alter table users drop constraint if exists users_role_check;
alter table users add constraint users_role_check
  check (role in ('admin','va','client_admin','team_lead','manager'));

-- 2. Wipe the demo people (FK cascades clear their progress/timesheets/prod) --
delete from users where name in (
  'Bea Villanueva','Joy Tolentino','Grace Mendoza',
  'Ericka Dela Cruz','Joan Cruz (Team Lead)'
);

-- 3. Seed the real access tiers (Edison + Nikki already exist; left untouched)
--    Starting PIN = 1234 for all; each person changes theirs on first login
--    via "Change my PIN" (admin page for admin/manager, My Account for client/va).

-- Owner tier: Grace Sia (full admin, sees everything)
insert into users (name, pin, role, client_id, vertical, billable_rate, pay_rate, active)
select 'Grace Sia','1234','admin', null, null, 0, 0, true
where not exists (select 1 from users where name = 'Grace Sia');

-- Client tier: Radmila Dusanovic (SIA Medical, view-only)
insert into users (name, pin, role, client_id, vertical, billable_rate, pay_rate, active)
select 'Radmila Dusanovic','1234','client_admin',
       '11111111-1111-1111-1111-111111111111','medical',0,0,true
where not exists (select 1 from users where name = 'Radmila Dusanovic');

-- Ericka Manager tier: Shane & Sharica (manage the whole remote team).
-- client_id null = whole-team reach (not bound to one client).
insert into users (name, pin, role, client_id, vertical, billable_rate, pay_rate, active)
select 'Shane','1234','manager', null, null, 0, 0, true
where not exists (select 1 from users where name = 'Shane');

insert into users (name, pin, role, client_id, vertical, billable_rate, pay_rate, active)
select 'Sharica','1234','manager', null, null, 0, 0, true
where not exists (select 1 from users where name = 'Sharica');

-- 4. Open the writes the in-app admin page needs (app-gated to admin/manager).
--    No DELETE for anon — deactivating a member = update active=false.
grant insert, update on users to anon;
