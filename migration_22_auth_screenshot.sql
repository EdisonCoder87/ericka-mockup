-- Migration 22: extra-hours authorisation needs a screenshot + a reason
--
-- Edison, 8 Oct 2026: Shane records the authorisation, but the proof is a
-- SCREENSHOT of the practice manager approving the hours, plus the reason the
-- extra time was needed. A pasted message is now optional.
--
-- The screenshot lives in the row itself (a compressed JPEG data URL, ~100-300 KB),
-- not in Supabase Storage: since migration 21 every write goes through a
-- token-checked function, and Storage would need an anon upload policy to work
-- with name+PIN logins. Insert+read only, same as before — evidence can't be edited.

alter table hours_authorisations add column if not exists reason     text;
alter table hours_authorisations add column if not exists screenshot text;
alter table hours_authorisations alter column evidence drop not null;

drop function if exists record_authorisation(uuid, uuid, date, numeric, text, text);

create or replace function record_authorisation(p_token uuid, p_va_id uuid, p_week_start date,
                                                p_extra_hours numeric, p_authorised_by text,
                                                p_reason text, p_screenshot text,
                                                p_evidence text default null)
returns void language plpgsql security definer set search_path = public as $$
declare u users := _session_user(p_token);
begin
  perform _require_role(u, array['admin','manager','team_lead']);
  if coalesce(trim(p_authorised_by), '') = '' then
    raise exception 'Say which practice manager approved it.'; end if;
  if length(coalesce(trim(p_reason), '')) < 10 then
    raise exception 'Give the reason for the extra hours.'; end if;
  if coalesce(p_screenshot, '') !~ '^data:image/(jpeg|png|webp);base64,' then
    raise exception 'Attach the screenshot of the practice manager approving the hours.'; end if;
  if length(p_screenshot) > 2000000 then
    raise exception 'That screenshot is too large. Crop it and try again.'; end if;
  if not (p_extra_hours > 0) then raise exception 'Extra hours must be more than zero.'; end if;
  insert into hours_authorisations (va_id, week_start, extra_hours, authorised_by, reason,
                                    screenshot, evidence, recorded_by)
  values (p_va_id, p_week_start, p_extra_hours, trim(p_authorised_by), trim(p_reason),
          p_screenshot, nullif(trim(coalesce(p_evidence, '')), ''), u.id);
end;
$$;

revoke all on function record_authorisation(uuid, uuid, date, numeric, text, text, text, text)
  from public, authenticated;
grant execute on function record_authorisation(uuid, uuid, date, numeric, text, text, text, text)
  to anon;
