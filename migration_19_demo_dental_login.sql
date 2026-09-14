-- ============================================================================
-- Ericka Portal — migration 19: a clean dental VA login for a demo/voiceover
--   video. All dental + AI modules pre-completed so EVERY module opens freely
--   (no sequential lock) and the progress bar reads 100%.
--   Name: "Ericka Dental Demo"   PIN: 2020   (dental track)
-- Re-runnable.
-- ============================================================================

insert into users (id, name, pin, role, client_id, vertical, billable_rate, pay_rate, site, is_demo)
values ('adde0000-0000-0000-0000-0000000000de','Ericka Dental Demo','2020','va',
        '33333333-3333-3333-3333-333333333333','dental',0,0,'Demo Clinic',true)
on conflict (id) do update set name=excluded.name, pin=excluded.pin, role=excluded.role,
        client_id=excluded.client_id, vertical=excluded.vertical, site=excluded.site, is_demo=true;

-- Mark every dental module + the shared AI track complete for this account, so
-- all cards show "Review →" and none are locked during the recording.
insert into training_progress (user_id, module_id)
select 'adde0000-0000-0000-0000-0000000000de', m.id
from training_modules m
where m.vertical in ('dental','all')
on conflict (user_id, module_id) do nothing;
