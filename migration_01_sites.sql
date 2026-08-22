-- ============================================================================
-- Ericka Portal — migration 01: add "site" to users + demo site assignments
-- Run ONCE in Supabase → SQL Editor (safe to re-run; idempotent).
-- Choose "Run without RLS" again if prompted.
-- ============================================================================

-- 1. New field: which site a VA works at (free text — reassign anytime in the
--    Table editor). Groups VAs under headings like Footscray / Essendon.
alter table users add column if not exists site text;

-- 2. Assign the existing demo VAs to sites
update users set site = 'Footscray' where name = 'Bea Villanueva';
update users set site = 'Essendon'  where name = 'Joy Tolentino';
update users set site = 'Richmond'  where name = 'Ericka Dela Cruz';  -- dental, different client

-- 3. Add a 2nd Footscray medical VA so site-grouping is obviously visible
insert into users (name, pin, role, client_id, vertical, billable_rate, pay_rate, site)
select 'Grace Mendoza','4444','va','11111111-1111-1111-1111-111111111111','medical',35,12,'Footscray'
where not exists (select 1 from users where name = 'Grace Mendoza');

-- 4. Give Grace 2 completed modules (so she isn't blank)
insert into training_progress (user_id, module_id)
select u.id, m.id
from users u, training_modules m
where u.name = 'Grace Mendoza'
  and m.vertical = 'medical' and m.ord in (1, 2)
on conflict (user_id, module_id) do nothing;
