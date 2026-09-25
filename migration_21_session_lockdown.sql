-- ============================================================================
-- Ericka Portal — migration 21: every write needs a signed-in session
--
--   Before this, the public anon key (shipped in config.js) could UPDATE users
--   and timesheets directly: anyone viewing source could make themselves an
--   owner, reset anyone's PIN, or approve / inflate hours that feed Xero.
--   `authenticated` also held ALL privileges (incl. DELETE/TRUNCATE) on every
--   table, reachable by anyone who signed up through Supabase Auth.
--
--   What changes:
--     1. check_login() hands back a random session token (30 days). Every
--        write is now a SECURITY DEFINER function that takes that token,
--        looks up who is calling, and checks their role in the database.
--     2. anon loses every direct INSERT/UPDATE. It keeps SELECT (reads are
--        unchanged — hiding those needs real auth, i.e. option C).
--     3. Wrong PINs lock the name: 5 in a row → 15 min, doubling every further
--        5, capped at 24 h. A correct PIN resets the count.
--     4. RLS on for every table (read-only policy for anon) — clears the
--        Supabase "RLS disabled" errors. authenticated loses everything.
--     5. Login reports must_change_pin while a real account is still on 1234,
--        and no PIN can be set back to 1234.
--
--   Login experience is unchanged: pick your name, type your PIN.
-- Re-runnable.
-- ============================================================================

-- 1. Sessions + lockout state ------------------------------------------------
create table if not exists sessions (
  token      uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days'
);
revoke all on sessions from anon, authenticated;

alter table users add column if not exists failed_logins int not null default 0;
alter table users add column if not exists locked_until timestamptz;

-- The caller behind a token, or an error. Internal only — never granted.
create or replace function _session_user(p_token uuid)
returns users
language plpgsql
stable
security definer
set search_path = public
as $$
declare u users;
begin
  select usr.* into u
    from sessions s join users usr on usr.id = s.user_id
   where s.token = p_token and s.expires_at > now() and usr.active = true;
  if u.id is null then
    raise exception 'SESSION_EXPIRED: please sign in again.';
  end if;
  return u;
end;
$$;
revoke all on function _session_user(uuid) from public, anon, authenticated;

create or replace function _require_role(u users, roles text[])
returns void language plpgsql immutable set search_path = public as $$
begin
  if not (u.role = any(roles)) then
    raise exception 'Not allowed for your role.';
  end if;
end;
$$;
revoke all on function _require_role(users, text[]) from public, anon, authenticated;

-- 2. Login -------------------------------------------------------------------
drop function if exists check_login(text, text);
create function check_login(p_name text, p_pin text)
returns table (id uuid, name text, role text, client_id uuid,
               vertical text, site text, active boolean, is_operator boolean,
               token uuid, must_change_pin boolean)
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  u users;
  v_token uuid;
  v_fails int;
begin
  select * into u from users where users.name = p_name and users.active = true
   order by created_at limit 1;
  if u.id is null then return; end if;

  if u.locked_until is not null and u.locked_until > now() then
    raise exception 'Too many wrong PINs. Try again after % (Melbourne time).',
      to_char(u.locked_until at time zone 'Australia/Melbourne', 'HH12:MI am');
  end if;

  if u.pin is distinct from p_pin then
    v_fails := coalesce(u.failed_logins, 0) + 1;
    update users set failed_logins = v_fails,
           locked_until = case when v_fails % 5 = 0
             then now() + least(interval '15 minutes' * power(2, v_fails / 5 - 1),
                                interval '24 hours')
             else locked_until end
     where users.id = u.id;
    return;                       -- wrong PIN: no row, same as before
  end if;

  update users set failed_logins = 0, locked_until = null where users.id = u.id;
  delete from sessions where expires_at < now();
  insert into sessions (user_id) values (u.id) returning sessions.token into v_token;

  return query select u.id, u.name, u.role, u.client_id, u.vertical, u.site,
                      u.active, coalesce(u.is_operator, false), v_token,
                      (u.pin = '1234' and not coalesce(u.is_demo, false));
end;
$$;
revoke all on function check_login(text, text) from public, authenticated;
grant execute on function check_login(text, text) to anon;

create or replace function logout_session(p_token uuid)
returns void language sql security definer set search_path = public as $$
  delete from sessions where token = p_token;
$$;
revoke all on function logout_session(uuid) from public, authenticated;
grant execute on function logout_session(uuid) to anon;

-- 3. Timesheets --------------------------------------------------------------
create or replace function clock_in(p_token uuid, p_client_id uuid)
returns timesheets language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token); r timesheets;
begin
  select * into r from timesheets
   where va_id = u.id and clock_out is null order by clock_in desc limit 1;
  if r.id is not null then return r; end if;       -- reuse the open shift
  insert into timesheets (va_id, client_id) values (u.id, p_client_id) returning * into r;
  return r;
end;
$$;

create or replace function clock_out(p_token uuid, p_shift_id uuid)
returns timesheets language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token); r timesheets;
begin
  update timesheets set clock_out = now()
   where id = p_shift_id and va_id = u.id and clock_out is null
  returning * into r;
  if r.id is null then raise exception 'That shift is not yours or is already closed.'; end if;
  return r;
end;
$$;

create or replace function approve_shift(p_token uuid, p_shift_id uuid, p_ok boolean)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token); v_out timestamptz;
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  if p_ok then
    select clock_out into v_out from timesheets where id = p_shift_id;
    if not found then raise exception 'That shift no longer exists.'; end if;
    if v_out is null then raise exception 'Still clocked in — close the shift before approving it.'; end if;
    update timesheets set status = 'approved', approved_by = u.id, approved_at = now()
     where id = p_shift_id;
  else
    update timesheets set status = 'pending', approved_by = null, approved_at = null
     where id = p_shift_id;
  end if;
end;
$$;

create or replace function edit_shift(p_token uuid, p_shift_id uuid, p_clock_in timestamptz,
                                      p_clock_out timestamptz, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token);
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  if p_clock_in is null then raise exception 'A shift needs a start time.'; end if;
  if p_clock_out is not null and p_clock_out <= p_clock_in then
    raise exception 'Clock out has to be after clock in.'; end if;
  if p_clock_out is not null and p_clock_out - p_clock_in > interval '16 hours' then
    raise exception 'That shift is over 16 hours — check the date on the times.'; end if;
  update timesheets set clock_in = p_clock_in, clock_out = p_clock_out, note = p_note,
         edited_by = u.id, edited_at = now(),
         status = 'pending', approved_by = null, approved_at = null
   where id = p_shift_id;
end;
$$;

create or replace function record_authorisation(p_token uuid, p_va_id uuid, p_week_start date,
                                                p_extra_hours numeric, p_authorised_by text,
                                                p_evidence text)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token);
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  if coalesce(trim(p_authorised_by), '') = '' then raise exception 'Say who authorised it (Rad or Nikki).'; end if;
  if length(coalesce(trim(p_evidence), '')) < 15 then raise exception 'Paste the actual message — a few words isn''t evidence.'; end if;
  if not (p_extra_hours > 0) then raise exception 'Extra hours must be more than zero.'; end if;
  insert into hours_authorisations (va_id, week_start, extra_hours, authorised_by, evidence, recorded_by)
  values (p_va_id, p_week_start, p_extra_hours, trim(p_authorised_by), trim(p_evidence), u.id);
end;
$$;

-- 4. Roster: the old anon-callable version goes; a token-checked wrapper
--    calls it. Clients (client_admin) view the roster but never edit it.
revoke all on function save_roster(uuid, jsonb) from public, anon, authenticated;
create or replace function save_roster_s(p_token uuid, p_va_id uuid, p_shifts jsonb)
returns numeric language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token);
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  return save_roster(p_va_id, p_shifts);
end;
$$;

-- 5. Training ----------------------------------------------------------------
create or replace function complete_module(p_token uuid, p_module_id uuid, p_score int)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token);
begin
  insert into training_progress (user_id, module_id, score)
  values (u.id, p_module_id, p_score)
  on conflict do nothing;                 -- first pass sticks
end;
$$;

create or replace function submit_evidence(p_token uuid, p_module_id uuid, p_url text)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token);
begin
  if p_url !~* '^https?://[^\s"''<>`]+$' then
    raise exception 'Paste a plain link starting with http:// or https://'; end if;
  update training_progress set evidence_url = p_url, verified_by = null, verified_at = null
   where user_id = u.id and module_id = p_module_id;
end;
$$;

create or replace function verify_evidence(p_token uuid, p_user_id uuid, p_module_id uuid, p_ok boolean)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token);
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  update training_progress
     set verified_by = case when p_ok then u.id end,
         verified_at = case when p_ok then now() end
   where user_id = p_user_id and module_id = p_module_id;
end;
$$;

-- 6. Performance -------------------------------------------------------------
--    Row is built in the browser (the metric list lives in app.js); the
--    function stamps who/when and only accepts the table's own columns.
create or replace function save_productivity(p_token uuid, p_row jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token); r productivity;
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  r := jsonb_populate_record(null::productivity,
         p_row || jsonb_build_object('updated_by', u.id, 'updated_at', now()));
  r.id := coalesce((select id from productivity
                     where user_id = r.user_id and period_start = r.period_start),
                   gen_random_uuid());
  delete from productivity where id = r.id;
  insert into productivity select r.*;
end;
$$;

create or replace function save_perf_rates(p_token uuid, p_vals jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token);
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  insert into perf_rates (id, updated_at) values (1, now()) on conflict (id) do nothing;
  update perf_rates set
    cp_value     = coalesce((p_vals->>'cp_value')::numeric,     cp_value),
    ha_value     = coalesce((p_vals->>'ha_value')::numeric,     ha_value),
    recall_value = coalesce((p_vals->>'recall_value')::numeric, recall_value),
    fta_value    = coalesce((p_vals->>'fta_value')::numeric,    fta_value),
    otp_value    = coalesce((p_vals->>'otp_value')::numeric,    otp_value),
    updated_at   = now()
   where id = 1;
end;
$$;

-- 7. Members -----------------------------------------------------------------
--    Owners (admin) can do anything. Ericka managers add VAs at rate 0 and
--    manage non-owner accounts. Team leads only set rostered hours.
create or replace function create_member(p_token uuid, p_m jsonb)
returns table (id uuid, name text)
language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token); v_pin text := trim(p_m->>'pin');
        v_role text := coalesce(p_m->>'role', 'va'); v_id uuid;
begin
  perform _require_role(u, array['admin','manager']);
  if coalesce(trim(p_m->>'name'), '') = '' then raise exception 'Name is required.'; end if;
  if v_pin !~ '^\d{4,6}$' then raise exception 'PIN must be 4–6 digits.'; end if;
  if v_pin = '1234' then raise exception 'Pick a PIN other than 1234.'; end if;
  if u.role <> 'admin' and v_role <> 'va' then raise exception 'Only an owner can add that role.'; end if;
  insert into users (name, pin, role, client_id, vertical, site,
                     billable_rate, pay_rate, rostered_hours, active)
  values (trim(p_m->>'name'), v_pin, v_role, (p_m->>'client_id')::uuid,
          coalesce(p_m->>'vertical', 'medical'), p_m->>'site',
          case when u.role = 'admin' then coalesce((p_m->>'billable_rate')::numeric, 0) else 0 end,
          case when u.role = 'admin' then coalesce((p_m->>'pay_rate')::numeric, 0) else 0 end,
          coalesce((p_m->>'rostered_hours')::numeric, 0), true)
  returning users.id into v_id;
  return query select v_id, trim(p_m->>'name');
end;
$$;

create or replace function update_member(p_token uuid, p_user_id uuid, p_f jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token); t users; h numeric;
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  select * into t from users where users.id = p_user_id;
  if t.id is null then raise exception 'No such member.'; end if;
  if u.role <> 'admin' and t.role = 'admin' then raise exception 'Only an owner can change an owner.'; end if;
  if u.role = 'team_lead' and exists (select 1 from jsonb_object_keys(p_f) k where k <> 'rostered_hours') then
    raise exception 'Not allowed for your role.'; end if;
  if p_f ? 'rostered_hours' then
    h := (p_f->>'rostered_hours')::numeric;
    if h is null or h < 0 or h > 80 then raise exception 'Rostered hours must be between 0 and 80.'; end if;
  end if;
  update users set
    site           = case when p_f ? 'site'           then nullif(p_f->>'site', '') else site end,
    active         = case when p_f ? 'active'         then (p_f->>'active')::boolean else active end,
    rostered_hours = case when p_f ? 'rostered_hours' then h else rostered_hours end,
    manager_id     = case when p_f ? 'manager_id'     then nullif(p_f->>'manager_id', '')::uuid else manager_id end,
    is_operator    = case when p_f ? 'is_operator'    then (p_f->>'is_operator')::boolean else is_operator end
   where users.id = p_user_id;
  if p_f ? 'active' and not (p_f->>'active')::boolean then
    delete from sessions where user_id = p_user_id;   -- deactivated = signed out now
  end if;
end;
$$;

create or replace function reset_pin(p_token uuid, p_user_id uuid, p_pin text)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token); t users; v_pin text := trim(p_pin);
begin
  if v_pin !~ '^\d{4,6}$' then raise exception 'PIN must be 4–6 digits.'; end if;
  if v_pin = '1234' then raise exception 'Pick a PIN other than 1234.'; end if;
  if p_user_id <> u.id then
    perform _require_role(u, array['admin','manager']);
    select * into t from users where users.id = p_user_id;
    if t.id is null then raise exception 'No such member.'; end if;
    if u.role <> 'admin' and t.role = 'admin' then raise exception 'Only an owner can change an owner''s PIN.'; end if;
    delete from sessions where user_id = p_user_id;   -- old PIN's sessions end
  end if;
  update users set pin = v_pin, failed_logins = 0, locked_until = null where users.id = p_user_id;
end;
$$;

-- 8. Grants on the new functions ----------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'clock_in(uuid,uuid)', 'clock_out(uuid,uuid)', 'approve_shift(uuid,uuid,boolean)',
    'edit_shift(uuid,uuid,timestamptz,timestamptz,text)',
    'record_authorisation(uuid,uuid,date,numeric,text,text)',
    'save_roster_s(uuid,uuid,jsonb)', 'complete_module(uuid,uuid,integer)',
    'submit_evidence(uuid,uuid,text)', 'verify_evidence(uuid,uuid,uuid,boolean)',
    'save_productivity(uuid,jsonb)', 'save_perf_rates(uuid,jsonb)',
    'create_member(uuid,jsonb)', 'update_member(uuid,uuid,jsonb)', 'reset_pin(uuid,uuid,text)']
  loop
    execute format('revoke all on function %s from public, authenticated', f);
    execute format('grant execute on function %s to anon', f);
  end loop;
end $$;

-- 9. Table rights: anon reads, never writes; authenticated gets nothing -------
revoke insert, update, delete, truncate on all tables in schema public from anon;
revoke all on all tables in schema public from authenticated;
-- users keeps its column-level SELECT from migration 16 (no pin / pay_rate).

-- Stop the next new table arriving with anon/authenticated write rights.
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public grant select on tables to anon;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;
revoke all on sessions from anon, authenticated;

-- 10. RLS on everywhere; anon may read the app tables, nothing may touch sessions
do $$
declare t text;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists anon_read on %I', t);
    if t <> 'sessions' then
      execute format('create policy anon_read on %I for select to anon using (true)', t);
    end if;
  end loop;
end $$;
