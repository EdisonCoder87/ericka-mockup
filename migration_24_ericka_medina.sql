-- ============================================================================
-- 24 · Ericka Medina — admin (owner tier) for timesheets + invoicing
--   Sees every timesheet and runs the period export / Xero invoice to SIA Medical.
--   Starts on PIN 1234 → login flags must_change_pin, so she sets her own on
--   first sign-in. Re-runnable.
-- ============================================================================
insert into users (name, pin, role, client_id, vertical, billable_rate, pay_rate, active)
select 'Ericka Medina','1234','admin', null, null, 0, 0, true
where not exists (select 1 from users where name = 'Ericka Medina');
