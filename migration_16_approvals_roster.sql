-- ============================================================================
-- Ericka Portal — migration 16: daily approvals, operator-managers, visual roster
--
--   Going live: the four SIA Medical VAs start clocking on for real, and Shane
--   and Sharica move from pure managers to people who ALSO work a seat
--   (Footscray and Essendon respectively). Three things follow:
--
--     1. A manager can hold a seat  → users.is_operator
--        They appear on the client board and the roster like any other member,
--        they clock on, and their hours bill. Their ROLE stays 'manager' so
--        they keep the approval powers.
--
--     2. Somebody owns each person's approval → users.manager_id
--        Explicit, not inferred from site — a member can move site without
--        silently changing who signs off their hours. Shane and Sharica point
--        at themselves, which is how they approve their own timesheets.
--
--     3. Hours above roster need the client's say-so → hours_authorisations
--        Shane cannot approve a week that runs over the roster until she has
--        pasted in the message from Rad or Nikki that asked for the extra
--        hours. The evidence is stored with the week it justifies.
--
--   Plus roster_shifts: the Mon–Fri visual roster (Tanda-style). rostered_hours
--   stays on users as the weekly total, but is now DERIVED from the shifts
--   whenever a roster is saved, so there is one number, not two that disagree.
--
-- Run via run_migrations.js ("Run without RLS"). Re-runnable — safe to run twice.
-- ============================================================================

-- 1. Operator-managers and approval ownership --------------------------------
alter table users add column if not exists is_operator boolean not null default false;
alter table users add column if not exists manager_id  uuid references users(id);

comment on column users.is_operator is
  'Manager who also works a client seat: clocks on, bills, appears on the client board.';
comment on column users.manager_id is
  'Who approves this person''s timesheets. Points at self for a self-approving manager.';

-- 2. Approval trail on each shift --------------------------------------------
alter table timesheets add column if not exists approved_by uuid references users(id);
alter table timesheets add column if not exists approved_at timestamptz;
-- An edited shift must never look like a clean clock record. These two say a
-- human moved the times, and who — the VA's own clock is no longer the source.
alter table timesheets add column if not exists edited_by   uuid references users(id);
alter table timesheets add column if not exists edited_at   timestamptz;
alter table timesheets add column if not exists note        text;

create index if not exists timesheets_status_idx on timesheets (status);

-- 3. The visual roster --------------------------------------------------------
--    One row per shift per weekday. weekday 0 = Monday … 6 = Sunday, matching
--    hoursByDay() in app.js so the roster and the coverage strip line up.
create table if not exists roster_shifts (
  id         uuid primary key default gen_random_uuid(),
  va_id      uuid not null references users(id) on delete cascade,
  weekday    int  not null check (weekday between 0 and 6),
  start_time time not null,
  end_time   time not null,
  created_at timestamptz default now(),
  check (end_time > start_time)
);
create index if not exists roster_shifts_va_idx on roster_shifts (va_id);

-- 4. Authorisation for hours above the roster ---------------------------------
--    evidence = the pasted message from Rad or Nikki. Without a row here the
--    approvals screen will not let an over-roster week through.
create table if not exists hours_authorisations (
  id             uuid primary key default gen_random_uuid(),
  va_id          uuid not null references users(id) on delete cascade,
  week_start     date not null,
  extra_hours    numeric(5,2) not null,
  authorised_by  text not null,          -- 'Radmila Dusanovic' / 'Nikki'
  evidence       text not null,          -- the message itself, pasted in
  recorded_by    uuid references users(id),
  created_at     timestamptz default now()
);
create index if not exists hours_auth_va_week_idx on hours_authorisations (va_id, week_start);

-- 5. Seed: Shane → Footscray, Sharica → Essendon ------------------------------
--    Both keep role 'manager'. is_operator is what puts them in a seat.
update users set
  is_operator = true,
  client_id   = '11111111-1111-1111-1111-111111111111',
  vertical    = 'medical',
  site        = 'Footscray'
where name = 'Shane' and role = 'manager';

update users set
  is_operator = true,
  client_id   = '11111111-1111-1111-1111-111111111111',
  vertical    = 'medical',
  site        = 'Essendon'
where name = 'Sharica' and role = 'manager';

-- 6. Who approves whom --------------------------------------------------------
--    Footscray + the General VA → Shane. Essendon → Sharica. Each manager
--    approves her own hours (manager_id = self).
update users u set manager_id = m.id
  from users m
 where m.name = 'Shane' and m.role = 'manager'
   and u.name in ('Eunice Joana Go', 'Lyca De Guzman', 'Kem Acibo', 'Shane');

update users u set manager_id = m.id
  from users m
 where m.name = 'Sharica' and m.role = 'manager'
   and u.name in ('Sheila Babiera', 'Leemay Sierra', 'Sharica');

-- 7. Login must tell the app it is talking to an operator ---------------------
--    Return type changes, so the old function has to go first.
drop function if exists check_login(text, text);
create function check_login(p_name text, p_pin text)
returns table (id uuid, name text, role text, client_id uuid,
               vertical text, site text, active boolean, is_operator boolean)
language sql
stable
security definer
set search_path = public
as $$
  select u.id, u.name, u.role, u.client_id, u.vertical, u.site, u.active,
         coalesce(u.is_operator, false)
    from users u
   where u.name = p_name
     and u.pin  = p_pin
     and u.active = true;
$$;

revoke all on function check_login(text, text) from public;
grant execute on function check_login(text, text) to anon;

-- 8. Grants -------------------------------------------------------------------
--    pin and pay_rate stay unreadable (migration 15); the new columns are safe.
revoke select on users from anon;
grant select (id, name, role, client_id, vertical, site, billable_rate,
              rostered_hours, is_demo, active, created_at,
              is_operator, manager_id)
  on users to anon;

-- The roster is written ONLY through save_roster() below, so anon needs no
-- write grant at all here — and in particular no DELETE, which migration 08
-- deliberately took away from the public key.
grant select on roster_shifts        to anon;
grant select, insert on hours_authorisations to anon;   -- never rewritten

-- 9. Saving a roster has to be one transaction -------------------------------
--    The browser used to delete every shift and then insert the new set. A
--    failure between the two left the person with NO roster while
--    users.rostered_hours still held the old total — the approvals ceiling and
--    the roster grid disagreeing, which is the one thing deriving the total was
--    supposed to make impossible. Doing it inside the database makes it atomic,
--    and means anon never needs DELETE on the table.
create or replace function save_roster(p_va_id uuid, p_shifts jsonb)
returns numeric
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_total numeric;
begin
  if p_va_id is null then
    raise exception 'save_roster: no member given';
  end if;

  -- Validate BEFORE touching anything. A bad row aborts the whole save.
  if exists (
    select 1 from jsonb_to_recordset(coalesce(p_shifts, '[]'::jsonb))
      as x(weekday int, start_time time, end_time time)
     where x.weekday is null or x.weekday < 0 or x.weekday > 6
        or x.start_time is null or x.end_time is null
        or x.end_time <= x.start_time
  ) then
    raise exception 'Every shift needs a weekday 0-6 and a finish later than its start.';
  end if;

  select coalesce(sum(extract(epoch from (x.end_time - x.start_time)) / 3600), 0)
    into v_total
    from jsonb_to_recordset(coalesce(p_shifts, '[]'::jsonb))
      as x(weekday int, start_time time, end_time time);

  if v_total > 80 then
    raise exception 'That roster totals % h — the cap is 80.', round(v_total, 2);
  end if;

  delete from roster_shifts where va_id = p_va_id;

  insert into roster_shifts (va_id, weekday, start_time, end_time)
  select p_va_id, x.weekday, x.start_time, x.end_time
    from jsonb_to_recordset(coalesce(p_shifts, '[]'::jsonb))
      as x(weekday int, start_time time, end_time time);

  update users set rostered_hours = round(v_total, 2) where id = p_va_id;

  return round(v_total, 2);
end;
$fn$;

revoke all on function save_roster(uuid, jsonb) from public;
grant execute on function save_roster(uuid, jsonb) to anon;
