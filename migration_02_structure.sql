-- ============================================================================
-- Ericka Portal — migration 02: training content structure + team_lead role
-- Run in Supabase SQL Editor (choose "Run without RLS"). Run BEFORE migration 03.
-- Idempotent where practical; safe to re-run.
-- ============================================================================

-- 1. Modules gain a category (onboarding vs training) + a short summary -------
alter table training_modules add column if not exists category text not null default 'training';
alter table training_modules add column if not exists summary  text;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'training_modules_category_check') then
    alter table training_modules add constraint training_modules_category_check
      check (category in ('onboarding','training'));
  end if;
end $$;

-- 2. Module body content lives in sections (markdown; easy to author/edit) ----
create table if not exists module_sections (
  id         uuid primary key default gen_random_uuid(),
  module_id  uuid not null references training_modules(id) on delete cascade,
  ord        int  not null,
  heading    text,
  body       text,               -- markdown
  created_at timestamptz default now()
);
create index if not exists module_sections_module_idx on module_sections (module_id, ord);
grant select on module_sections to anon;

-- 3. Site-scoped cheat sheet (Footscray etc.) --------------------------------
create table if not exists cheatsheets (
  id         uuid primary key default gen_random_uuid(),
  site       text not null,
  ord        int  not null,
  heading    text,
  body       text,               -- markdown
  created_at timestamptz default now()
);
create index if not exists cheatsheets_site_idx on cheatsheets (site, ord);
grant select on cheatsheets to anon;

-- 4. New role: team_lead (whole-team progress view, no system admin) ----------
alter table users drop constraint if exists users_role_check;
alter table users add constraint users_role_check
  check (role in ('admin','va','client_admin','team_lead'));

-- Demo team lead (sees every remote VA across clients/sites)
insert into users (name, pin, role, client_id, vertical, billable_rate, pay_rate, site)
select 'Joan Cruz (Team Lead)','5555','team_lead', null, null, 0, 0, null
where not exists (select 1 from users where name = 'Joan Cruz (Team Lead)');

-- 5. Replace the placeholder medical modules with the real onboarding+training
--    set. Deleting medical modules cascades to their sections + progress.
delete from training_modules where vertical = 'medical';

-- Onboarding modules (category = onboarding) ---------------------------------
insert into training_modules (id, vertical, category, ord, title, icon, capability_label, summary) values
 ('f1000000-0000-0000-0000-000000000001','medical','onboarding',1,'Welcome & The Ericka Way','👋','Ericka Standard','Who we are, malasakit, and the standard every Ericka VA carries into a clinic.'),
 ('f1000000-0000-0000-0000-000000000002','medical','onboarding',2,'Meet SIA Medical & Your Clinic','🏥','Clinic Orientation','The SIA Medical group, the Footscray clinic and the team you support.'),
 ('f1000000-0000-0000-0000-000000000003','medical','onboarding',3,'Your Systems & Logins','💻','Systems Access','Pracsoft, Medical Director, HotDoc, 3CX and remote-desktop/IT support.'),
 ('f1000000-0000-0000-0000-000000000004','medical','onboarding',4,'How We Communicate & Escalate','💬','Comms & Escalation','Bubble messages, WhatsApp, reception email and when to escalate.'),
 ('f1000000-0000-0000-0000-000000000005','medical','onboarding',5,'Privacy & Confidentiality','🔒','Privacy & Confidentiality','The golden rule of patient privacy and the Australian Privacy Principles.'),
 ('f1000000-0000-0000-0000-000000000006','medical','onboarding',6,'Complete Your Training','🎓','Onboarding Complete','The gateway step: finish all training modules before going live.');

-- Training modules (category = training) -------------------------------------
insert into training_modules (id, vertical, category, ord, title, icon, capability_label, summary) values
 ('f2000000-0000-0000-0000-000000000001','medical','training',1,'Phone Skills & Triage','📞','Phone Triage','Answering the SIA way, the 6-category triage safety net and difficult calls.'),
 ('f2000000-0000-0000-0000-000000000002','medical','training',2,'The Appointment Book','📅','Appointment Book','Searching, booking, moving and cancelling in Pracsoft.'),
 ('f2000000-0000-0000-0000-000000000003','medical','training',3,'Booking Rules & Doctor Preferences','👩‍⚕️','Doctor Booking Rules','Why every doctor is different and how to book them correctly.'),
 ('f2000000-0000-0000-0000-000000000004','medical','training',4,'Medicare & Billing Basics','💳','Medicare & Billing','Bulk-billing vs mixed billing, concession cards, fees and rebates.'),
 ('f2000000-0000-0000-0000-000000000005','medical','training',5,'Payments, HotDoc & Pre-Auth','🧾','Payments & Pre-Auth','Taking payments, payment requests and telehealth pre-authorisation.'),
 ('f2000000-0000-0000-0000-000000000006','medical','training',6,'Appointment Types & Procedures','⏱️','Appointment Types','Short/medium/long rules and the key procedures you''ll book.'),
 ('f2000000-0000-0000-0000-000000000007','medical','training',7,'Nurse & Treatment Room','🩺','Nurse & Treatment Room','Nurse services, treatment-room billing and matching durations.'),
 ('f2000000-0000-0000-0000-000000000008','medical','training',8,'Vaccinations & Immunisation','💉','Vaccinations','Government vs private, travel vaccines and AIR uploads.'),
 ('f2000000-0000-0000-0000-000000000009','medical','training',9,'Allied Health Bookings','🦶','Allied Health','Podiatry, physio, psychology and exercise physiology bookings.'),
 ('f2000000-0000-0000-0000-000000000010','medical','training',10,'Results, Certificates & Records','📄','Results & Records','Handling results, certificates, scanning and record requests.');

-- 6. Re-seed demo progress against the NEW modules (name-based = robust to ids)
-- Bea: onboarding 1-5 done + training 1-3 done
insert into training_progress (user_id, module_id)
select u.id, m.id from users u, training_modules m
where u.name='Bea Villanueva' and m.vertical='medical' and (
  (m.category='onboarding' and m.ord <= 5) or (m.category='training' and m.ord <= 3))
on conflict (user_id, module_id) do nothing;

-- Joy: onboarding 1-3 done
insert into training_progress (user_id, module_id)
select u.id, m.id from users u, training_modules m
where u.name='Joy Tolentino' and m.vertical='medical' and m.category='onboarding' and m.ord <= 3
on conflict (user_id, module_id) do nothing;

-- Grace: onboarding 1-2 done
insert into training_progress (user_id, module_id)
select u.id, m.id from users u, training_modules m
where u.name='Grace Mendoza' and m.vertical='medical' and m.category='onboarding' and m.ord <= 2
on conflict (user_id, module_id) do nothing;
