-- ============================================================================
-- Ericka Portal — migration 15: stop the public key from READING pins and pay
--
--   The anon key is published in config.js — that is by design for a site with
--   no server. But anon held table-wide SELECT on `users`, so anyone who
--   opened the portal could read every PIN, every pay_rate AND every
--   billable_rate — i.e. work out Ericka's margin on every person.
--
--   Fix without touching the login experience:
--     1. Move the PIN check into a SECURITY DEFINER function. The browser asks
--        "is this name+pin valid?" and gets the user row back; it can no longer
--        read the pin column itself.
--     2. Replace the table-wide SELECT grant with a column list that omits
--        `pin` and `pay_rate`.
--
--   ⚠️ What this does NOT do: stop someone GUESSING a PIN (there is still no
--      lockout or rate limit), or stop writes. Both need real auth + RLS.
-- Re-runnable.
-- ============================================================================

-- 1. Login moves into the database -------------------------------------------
create or replace function check_login(p_name text, p_pin text)
returns table (id uuid, name text, role text, client_id uuid,
               vertical text, site text, active boolean)
language sql
stable
security definer
set search_path = public
as $$
  select u.id, u.name, u.role, u.client_id, u.vertical, u.site, u.active
    from users u
   where u.name = p_name
     and u.pin  = p_pin
     and u.active = true;
$$;

revoke all on function check_login(text, text) from public;
grant execute on function check_login(text, text) to anon;

-- 2. Hand anon only the columns the app actually reads ------------------------
--    (a column-level grant can't override a table-wide one, so drop that first)
revoke select on users from anon;
grant select (id, name, role, client_id, vertical, site, billable_rate,
              rostered_hours, is_demo, active, created_at)
  on users to anon;

-- Writes are unchanged: the admin page still creates members, resets PINs and
-- reassigns clinics. Writing a PIN never required being able to read one.
