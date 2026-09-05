-- ============================================================================
-- Ericka Portal — migration 13: demo clinics for Grace's client demo
--
--   Real SIA Medical has no timesheets and no performance entered yet, so the
--   client view renders empty. Rather than put invented numbers in front of
--   Nikki and Rad on the REAL account, this seeds two clearly-named demo
--   clinics — one dental, one medical — fully populated.
--
--   Every demo row carries users.is_demo = true, so demo people are hidden
--   from the managers' real team board (owners still see them).
--
--   ⚠️ RE-RUN THIS BEFORE A DEMO. Timesheets are seeded relative to the
--      current week, so they go stale after Sunday:
--        SUPABASE_PAT=... node run_migrations.js migration_13_demo_clinics.sql
--
--   Also adds the dental onboarding spine (titles only — content TODO), so a
--   dental VA card shows an onboarding bar like a medical one does.
-- Re-runnable: wipes and rebuilds all demo data.
-- ============================================================================

-- 1. Clear previous demo data (FK cascades clear their shifts/progress/prod) --
delete from users   where is_demo = true;
delete from clients where id in ('33333333-3333-3333-3333-333333333333',
                                 '44444444-4444-4444-4444-444444444444');

-- 2. Dental onboarding spine (real structure, content still to be written) ----
insert into training_modules (id, vertical, category, ord, title, icon, capability_label, summary)
values
 ('e1000000-0000-0000-0000-000000000001','dental','onboarding',1,'Meet the practice','🏥','Practice Basics','Who the team are, the rooms, the hours and who to escalate to.'),
 ('e1000000-0000-0000-0000-000000000002','dental','onboarding',2,'Your systems & logins','💻','Systems Access','D4W, the phone system and the messaging tools you will live in.'),
 ('e1000000-0000-0000-0000-000000000003','dental','onboarding',3,'The appointment book','📅','Appointment Book','Appointment types, lengths and the booking rules per provider.'),
 ('e1000000-0000-0000-0000-000000000004','dental','onboarding',4,'Privacy & confidentiality','🔒','Privacy & Compliance','What you may say, to whom, and what never leaves the practice.'),
 ('e1000000-0000-0000-0000-000000000005','dental','onboarding',5,'Clocking on, comms & escalation','⏱️','Ericka Standard','Timesheets, handovers, and when to put something up the line.')
on conflict (id) do nothing;

-- 3. Demo clients -------------------------------------------------------------
insert into clients (id, name, vertical) values
 ('33333333-3333-3333-3333-333333333333','Demo Dental Clinic','dental'),
 ('44444444-4444-4444-4444-444444444444','Demo Medical Clinic','medical');

-- 4. Demo people --------------------------------------------------------------
--    Owner logins Grace can demo from, plus three VAs each.
insert into users (id, name, pin, role, client_id, vertical, billable_rate, pay_rate,
                   site, rostered_hours, is_demo, active) values
 -- Dental
 ('e2000000-0000-0000-0000-000000000001','Demo Owner (Dental)','9911','client_admin',
  '33333333-3333-3333-3333-333333333333','dental',0,0,null,0,true,true),
 ('e3000000-0000-0000-0000-000000000001','Mika Reyes','9901','va',
  '33333333-3333-3333-3333-333333333333','dental',35,0,'Main Street',38,true,true),
 ('e3000000-0000-0000-0000-000000000002','Dana Cruz','9902','va',
  '33333333-3333-3333-3333-333333333333','dental',35,0,'Main Street',30,true,true),
 ('e3000000-0000-0000-0000-000000000003','Jomar Lim','9903','va',
  '33333333-3333-3333-3333-333333333333','dental',35,0,'Northside',20,true,true),
 -- Medical
 ('e2000000-0000-0000-0000-000000000002','Demo Owner (Medical)','9922','client_admin',
  '44444444-4444-4444-4444-444444444444','medical',0,0,null,0,true,true),
 ('e4000000-0000-0000-0000-000000000001','Ana Bautista','9904','va',
  '44444444-4444-4444-4444-444444444444','medical',35,0,'Northcote',38,true,true),
 ('e4000000-0000-0000-0000-000000000002','Rey Santos','9905','va',
  '44444444-4444-4444-4444-444444444444','medical',35,0,'Northcote',38,true,true),
 ('e4000000-0000-0000-0000-000000000003','Cielo Ramos','9906','va',
  '44444444-4444-4444-4444-444444444444','medical',35,0,'Sunshine',24,true,true);

-- 5. Timesheets — this week, Melbourne time ----------------------------------
--    Monday 00:00 Melbourne of the current week, as a real timestamptz.
--    One VA is left clocked IN so the "on right now" strip has something live.
with wk as (
  select (date_trunc('week', (now() at time zone 'Australia/Melbourne'))
          at time zone 'Australia/Melbourne') as mon,
         extract(dow from (now() at time zone 'Australia/Melbourne'))::int as dow_today
),
-- day 0 = Monday. Only seed days that have already happened this week.
shifts (va, day, start_h, hours) as (values
  -- Mika Reyes — full-timer, tracking on roster
  ('e3000000-0000-0000-0000-000000000001',0, 9.0, 7.5),
  ('e3000000-0000-0000-0000-000000000001',1, 9.0, 7.5),
  ('e3000000-0000-0000-0000-000000000001',2, 9.0, 7.0),
  ('e3000000-0000-0000-0000-000000000001',3, 9.0, 7.5),
  ('e3000000-0000-0000-0000-000000000001',4, 9.0, 7.5),
  -- Dana Cruz — part-time, ahead of roster
  ('e3000000-0000-0000-0000-000000000002',0, 8.5, 6.5),
  ('e3000000-0000-0000-0000-000000000002',1, 8.5, 6.5),
  ('e3000000-0000-0000-0000-000000000002',3, 8.5, 6.5),
  ('e3000000-0000-0000-0000-000000000002',4, 8.5, 6.0),
  -- Jomar Lim — 20h, running behind
  ('e3000000-0000-0000-0000-000000000003',1,13.0, 5.0),
  ('e3000000-0000-0000-0000-000000000003',3,13.0, 4.5),
  -- Medical demo team
  ('e4000000-0000-0000-0000-000000000001',0, 8.0, 7.5),
  ('e4000000-0000-0000-0000-000000000001',1, 8.0, 7.5),
  ('e4000000-0000-0000-0000-000000000001',2, 8.0, 7.5),
  ('e4000000-0000-0000-0000-000000000001',3, 8.0, 7.0),
  ('e4000000-0000-0000-0000-000000000001',4, 8.0, 7.5),
  ('e4000000-0000-0000-0000-000000000002',0,12.0, 7.0),
  ('e4000000-0000-0000-0000-000000000002',1,12.0, 7.5),
  ('e4000000-0000-0000-0000-000000000002',2,12.0, 7.5),
  ('e4000000-0000-0000-0000-000000000002',3,12.0, 7.0),
  ('e4000000-0000-0000-0000-000000000002',4,12.0, 7.5),
  ('e4000000-0000-0000-0000-000000000003',1, 9.0, 6.0),
  ('e4000000-0000-0000-0000-000000000003',2, 9.0, 6.0),
  ('e4000000-0000-0000-0000-000000000003',4, 9.0, 6.0)
)
insert into timesheets (va_id, client_id, clock_in, clock_out, status)
select s.va::uuid, u.client_id,
       wk.mon + (s.day || ' days')::interval + (s.start_h || ' hours')::interval,
       wk.mon + (s.day || ' days')::interval + ((s.start_h + s.hours) || ' hours')::interval,
       'approved'
  from shifts s
  join wk on true
  join users u on u.id = s.va::uuid
 -- Monday = dow 1 .. Sunday = dow 0. Only days already elapsed this week.
 where s.day < (case when wk.dow_today = 0 then 7 else wk.dow_today end)
   and wk.mon + (s.day || ' days')::interval + ((s.start_h + s.hours) || ' hours')::interval < now();

-- Mika is on the phones right now (open shift, started ~2.5 hours ago).
insert into timesheets (va_id, client_id, clock_in, clock_out, status)
select 'e3000000-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333',
       now() - interval '2 hours 34 minutes', null, 'pending';

-- Ana is on right now too, so the medical demo has a live face.
insert into timesheets (va_id, client_id, clock_in, clock_out, status)
select 'e4000000-0000-0000-0000-000000000001', '44444444-4444-4444-4444-444444444444',
       now() - interval '3 hours 12 minutes', null, 'pending';

-- 6. Performance — the last two completed weeks, so trends have something ----
--    (3CX/HotDoc/Pracsoft reports are retroactive; the current week is not in yet.)
with wk as (
  select (date_trunc('week', (now() at time zone 'Australia/Melbourne')))::date as this_mon
),
p (va, wks_ago, calls_inbound, calls_missed, scans, confirmation_calls,
   arrears_total, arrears_answered, arrears_collected,
   cpr_total, cpr_picked_up, cpr_booked, ha_due, ha_picked_up, ha_booked,
   recall_due, recall_contacted, recall_booked,
   fta_total, fta_contacted, fta_rebooked,
   otp_due, otp_contacted, otp_booked, new_patients) as (values
  -- ── Dental demo team ──────────────────────────────────────────────────
  ('e3000000-0000-0000-0000-000000000001',1, 214,  9, 0, 118,  22, 14, 1180.00, 0,0,0, 0,0,0,  96, 71, 48,  17, 14,  9,  54, 33, 12, 21),
  ('e3000000-0000-0000-0000-000000000001',2, 198, 17, 0, 104,  19, 11,  860.00, 0,0,0, 0,0,0,  88, 61, 39,  21, 15,  8,  49, 27,  9, 17),
  ('e3000000-0000-0000-0000-000000000002',1, 163, 11, 0,  92,  15,  9,  640.00, 0,0,0, 0,0,0,  74, 55, 36,  12,  9,  6,  41, 26, 10, 14),
  ('e3000000-0000-0000-0000-000000000002',2, 171, 14, 0,  88,  17, 10,  720.00, 0,0,0, 0,0,0,  69, 48, 31,  14, 10,  5,  38, 22,  7, 15),
  ('e3000000-0000-0000-0000-000000000003',1,  88,  6, 0,  51,   9,  6,  380.00, 0,0,0, 0,0,0,  42, 30, 19,   8,  6,  4,  23, 14,  5,  8),
  ('e3000000-0000-0000-0000-000000000003',2,  81, 10, 0,  44,   8,  4,  240.00, 0,0,0, 0,0,0,  38, 24, 14,   9,  5,  2,  20, 11,  3,  6),
  -- ── Medical demo team ─────────────────────────────────────────────────
  ('e4000000-0000-0000-0000-000000000001',1, 231, 12, 46, 124,  26, 17, 1340.00, 52, 34, 24,  23, 15, 11,  0,0,0, 0,0,0, 0,0,0, 0),
  ('e4000000-0000-0000-0000-000000000001',2, 208, 21, 39, 111,  24, 13,  910.00, 47, 27, 18,  19, 11,  7,  0,0,0, 0,0,0, 0,0,0, 0),
  ('e4000000-0000-0000-0000-000000000002',1, 219, 15, 41, 117,  21, 14, 1075.00, 45, 29, 21,  20, 13,  9,  0,0,0, 0,0,0, 0,0,0, 0),
  ('e4000000-0000-0000-0000-000000000002',2, 226, 19, 44, 121,  23, 12,  980.00, 49, 31, 19,  18, 10,  8,  0,0,0, 0,0,0, 0,0,0, 0),
  ('e4000000-0000-0000-0000-000000000003',1, 121,  8, 24,  66,  13,  8,  520.00, 27, 18, 12,  11,  7,  5,  0,0,0, 0,0,0, 0,0,0, 0),
  ('e4000000-0000-0000-0000-000000000003',2, 114, 13, 21,  59,  12,  6,  410.00, 24, 14,  9,   9,  5,  3,  0,0,0, 0,0,0, 0,0,0, 0)
)
insert into productivity (
  user_id, client_id, period_label, period_start,
  calls_inbound, calls_missed, scans, confirmation_calls,
  arrears_total, arrears_answered, arrears_collected,
  cpr_total, cpr_picked_up, cpr_booked, ha_due, ha_picked_up, ha_booked,
  recall_due, recall_contacted, recall_booked,
  fta_total, fta_contacted, fta_rebooked,
  otp_due, otp_contacted, otp_booked, new_patients, notes)
select p.va::uuid, u.client_id,
       'Week of ' || to_char(wk.this_mon - (p.wks_ago * 7), 'FMDD Mon YYYY'),
       wk.this_mon - (p.wks_ago * 7),
       p.calls_inbound, p.calls_missed, p.scans, p.confirmation_calls,
       p.arrears_total, p.arrears_answered, p.arrears_collected,
       p.cpr_total, p.cpr_picked_up, p.cpr_booked, p.ha_due, p.ha_picked_up, p.ha_booked,
       p.recall_due, p.recall_contacted, p.recall_booked,
       p.fta_total, p.fta_contacted, p.fta_rebooked,
       p.otp_due, p.otp_contacted, p.otp_booked, p.new_patients,
       'Demo data'
  from p join wk on true join users u on u.id = p.va::uuid
on conflict (user_id, period_label) do nothing;

-- 7. Training progress --------------------------------------------------------
--    Everyone finishes onboarding; training and the AI track vary so the
--    client board shows a real spread rather than a wall of 100%.

-- All demo VAs: full onboarding for their vertical.
insert into training_progress (user_id, module_id, score)
select u.id, m.id, 100
  from users u
  join training_modules m on m.vertical = u.vertical and m.category = 'onboarding'
 where u.is_demo and u.role = 'va';

-- Core training: Mika/Dana/Ana/Rey complete; Jomar and Cielo part-way.
insert into training_progress (user_id, module_id, score)
select u.id, m.id, 90
  from users u
  join training_modules m on m.vertical = u.vertical and m.category = 'training'
 where u.is_demo and u.role = 'va'
   and (u.name in ('Mika Reyes','Dana Cruz','Ana Bautista','Rey Santos')
        or (u.name in ('Jomar Lim','Cielo Ramos') and m.ord <= 3));

-- AI track ------------------------------------------------------------------
-- Mika Reyes: AI Assisted + AI Builder, both practicals verified.
insert into training_progress (user_id, module_id, score, evidence_url, verified_by, verified_at)
select 'e3000000-0000-0000-0000-000000000001', m.id, 95,
       case when m.requires_evidence then 'https://example.com/demo/mika-'
            || case when m.tier = 'foundation' then 'recall-sop' else 'whitespace-filler' end
       end,
       case when m.requires_evidence then (select id from users where name = 'Shane') end,
       case when m.requires_evidence then now() - interval '9 days' end
  from training_modules m where m.category = 'ai';

-- Dana Cruz: AI Assisted complete (verified); part-way through Builder.
insert into training_progress (user_id, module_id, score, evidence_url, verified_by, verified_at)
select 'e3000000-0000-0000-0000-000000000002', m.id, 88,
       case when m.requires_evidence then 'https://example.com/demo/dana-arrears-sop' end,
       case when m.requires_evidence then (select id from users where name = 'Sharica') end,
       case when m.requires_evidence then now() - interval '4 days' end
  from training_modules m where m.category = 'ai' and (m.tier = 'foundation' or m.ord <= 8);

-- Jomar Lim: foundation modules done EXCEPT the practical is submitted, not
-- yet verified — shows the "awaiting verification" state in the demo.
insert into training_progress (user_id, module_id, score)
select 'e3000000-0000-0000-0000-000000000003', m.id, 82
  from training_modules m where m.category = 'ai' and m.tier = 'foundation' and m.ord <= 5;
insert into training_progress (user_id, module_id, score, evidence_url)
select 'e3000000-0000-0000-0000-000000000003', m.id, 80, 'https://example.com/demo/jomar-newpatient-sop'
  from training_modules m where m.category = 'ai' and m.requires_evidence and m.tier = 'foundation';

-- Ana Bautista: AI Assisted verified. Rey Santos: foundation in progress.
insert into training_progress (user_id, module_id, score, evidence_url, verified_by, verified_at)
select 'e4000000-0000-0000-0000-000000000001', m.id, 92,
       case when m.requires_evidence then 'https://example.com/demo/ana-results-sop' end,
       case when m.requires_evidence then (select id from users where name = 'Shane') end,
       case when m.requires_evidence then now() - interval '12 days' end
  from training_modules m where m.category = 'ai' and m.tier = 'foundation';

insert into training_progress (user_id, module_id, score)
select 'e4000000-0000-0000-0000-000000000002', m.id, 85
  from training_modules m where m.category = 'ai' and m.tier = 'foundation' and m.ord <= 4;
