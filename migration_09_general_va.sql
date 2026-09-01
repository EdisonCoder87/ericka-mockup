-- ============================================================================
-- Ericka Portal — migration 09: general (non-clinic) VAs
--   Some remote members aren't tied to a SIA Medical clinic — they're general
--   VAs (e.g. an owner's own VA). They carry site = 'General VA' and no client
--   (client_id null), so they show only on the managers' whole-team board.
-- Run via run_migrations.js. Idempotent.
-- ============================================================================

-- Kem Acibo — Grace's general VA.
insert into users (name, pin, role, client_id, vertical, billable_rate, pay_rate, site, active)
select 'Kem Acibo','1234','va', null, 'medical', 0, 0, 'General VA', true
where not exists (select 1 from users where name = 'Kem Acibo');
