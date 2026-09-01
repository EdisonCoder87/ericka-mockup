-- ============================================================================
-- Ericka Portal — migration 08: close the anon over-permissioning
--   The public "anon" role (whose key ships in config.js on the public site)
--   had ALL privileges — incl. DELETE + TRUNCATE — on EVERY table. That means
--   anyone viewing source could wipe/rewrite the database. Supabase grants this
--   by default and relies on RLS to gate it; RLS is off here, so we instead
--   revoke everything and re-grant only what the browser app actually uses.
--
--   This is NOT the full RLS lockdown (anon can still SELECT pay_rate and write
--   the app tables). RLS remains the deferred pre-paying-client step.
-- Run via run_migrations.js ("Run without RLS"). Re-runnable.
-- ============================================================================

revoke all on all tables in schema public from anon;

-- Reads: reference data + all the boards need to read every table.
grant select on all tables in schema public to anon;

-- Writes: only the exact operations the browser performs.
grant insert, update on timesheets        to anon;   -- VA clock in / out
grant insert          on training_progress to anon;  -- mark a module complete
grant insert, update on productivity       to anon;  -- manager/team-lead perf entry
grant insert, update on perf_rates         to anon;  -- editable CP/HA rates
grant insert, update on users              to anon;  -- admin page: add member / reset PIN / reassign clinic / (de)activate
