-- ============================================================================
-- Ericka Portal — migration 14: key a performance row on its WEEK, not its label
--
--   `period_label` is display text a team lead used to type by hand, so it
--   made a poor conflict target: re-typing the label for the same week created
--   a SECOND row for that week, which then showed up as a week-on-week trend
--   comparing a week against itself.
--
--   `period_start` is the real key. Backfill it, make it required, and move
--   the unique constraint onto it.
--
--   Also: `calls_missed` must not default to 0. A week entered before that
--   field existed has no missed-call count, and treating "unknown" as zero
--   renders a fabricated 100% answer rate on the client's dashboard.
-- Re-runnable.
-- ============================================================================

-- 1. Backfill any row still missing its week ---------------------------------
update productivity
   set period_start = to_date(substring(period_label from 'Week of (.+)$'), 'DD Mon YYYY')
 where period_start is null
   and period_label ~ '^Week of \d{1,2} [A-Za-z]{3} \d{4}$';

-- Anything still null gets the Monday of the week it was entered — a guess,
-- but an ordered one, and better than a row that can never be keyed.
update productivity
   set period_start = (date_trunc('week', coalesce(updated_at, now())))::date
 where period_start is null;

-- 2. Collapse any duplicate weeks before adding the constraint ---------------
delete from productivity p
 using productivity q
 where p.user_id = q.user_id
   and p.period_start = q.period_start
   and p.updated_at < q.updated_at;

-- 3. The week is now the key -------------------------------------------------
alter table productivity alter column period_start set not null;
alter table productivity drop constraint if exists productivity_user_id_period_label_key;
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'productivity_user_period_start_key') then
    alter table productivity add constraint productivity_user_period_start_key
      unique (user_id, period_start);
  end if;
end $$;

-- 4. Unknown missed calls stay unknown ---------------------------------------
alter table productivity alter column calls_missed drop default;
