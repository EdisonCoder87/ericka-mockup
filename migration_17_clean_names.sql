-- ============================================================================
-- Ericka Portal — migration 17: real names only, demo accounts out of the way
--
--   The team starts using this tomorrow, so the login screen has to look like
--   a real tool: the people who actually work here, named the way they are
--   spoken to. Two changes:
--
--     1. Drop the parenthetical qualifiers from names. "Nikki (SIA Medical)"
--        was a disambiguator from when there were seeded placeholders around;
--        with a real team on the system it just reads as clutter, and the role
--        is already carried by `role` + `client_id`.
--
--     2. Deactivate the seeded demo accounts. They stay in the database —
--        Grace still demos from them — but they are out of every board and
--        every count. `migration_13_demo_clinics.sql` brings them back, and
--        the login screen surfaces them again on `01_welcome.html?demo=1`.
--
-- Re-runnable.
-- ============================================================================

-- 1. Real names, no qualifiers ------------------------------------------------
update users set name = 'Nikki' where name = 'Nikki (SIA Medical)';

-- Anything else carrying a trailing "(…)" on a REAL account gets the same
-- treatment, so this doesn't need revisiting per-person.
update users
   set name = btrim(regexp_replace(name, '\s*\([^)]*\)\s*$', ''))
 where is_demo = false
   and name ~ '\([^)]*\)\s*$'
   and btrim(regexp_replace(name, '\s*\([^)]*\)\s*$', '')) <> '';

-- 2. Demo accounts out of the live tool ---------------------------------------
--    Deactivated, not deleted: their timesheets and training rows are what make
--    a demo look real, and deleting the user would cascade them away.
update users set active = false where is_demo = true;
