-- ============================================================================
-- Ericka Portal — migration 04: module quizzes
-- Run in Supabase SQL Editor AFTER migrations 01, 02, 03 ("Run without RLS").
-- A module with quiz questions requires a passing score (>=75%) to complete;
-- modules without questions keep the simple "mark complete" button.
-- Re-runnable: clears existing questions first.
-- ============================================================================

create table if not exists quiz_questions (
  id          uuid primary key default gen_random_uuid(),
  module_id   uuid not null references training_modules(id) on delete cascade,
  ord         int  not null,
  question    text not null,
  options     jsonb not null,          -- array of answer strings
  correct     int  not null,           -- 0-based index of the correct option
  explanation text,
  created_at  timestamptz default now()
);
create index if not exists quiz_questions_module_idx on quiz_questions (module_id, ord);
grant select on quiz_questions to anon;

-- Record the score a VA achieved (first pass sticks).
alter table training_progress add column if not exists score int;

delete from quiz_questions;

-- ==========================================================================
-- ONBOARDING QUIZZES
-- ==========================================================================

-- O1 · Welcome & The Ericka Way
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f1000000-0000-0000-0000-000000000001',1,$q$When you answer the phone, who do you represent?$q$,$j$["Just Ericka","Just the clinic","Both Ericka and the clinic you support","Only yourself"]$j$::jsonb,2,$e$You represent both Ericka and the clinic (SIA Medical) at the same time.$e$),
('f1000000-0000-0000-0000-000000000001',2,$q$What does "malasakit" mean?$q$,$j$["A booking system","Genuine care","A billing code","A type of appointment"]$j$::jsonb,1,$e$Malasakit is genuine care — the heart of the Ericka way.$e$),
('f1000000-0000-0000-0000-000000000001',3,$q$Which two things must ALWAYS be accurate?$q$,$j$["A patient's health and their money","Their name and address","The time and the date","The room and the doctor"]$j$::jsonb,0,$e$A patient's health and their money must always be right — never guess on either.$e$);

-- O2 · Meet SIA Medical & Your Clinic
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f1000000-0000-0000-0000-000000000002',1,$q$Which clinic are you supporting?$q$,$j$["Essendon","Footscray","Burwood","Box Hill"]$j$::jsonb,1,$e$You support the Footscray clinic at 190 Barkly Street.$e$),
('f1000000-0000-0000-0000-000000000002',2,$q$Where do the full doctor rules and fees live?$q$,$j$["You must memorise them","In the Footscray Cheat Sheet","In HotDoc","In your email"]$j$::jsonb,1,$e$The cheat sheet holds all the particulars so you can reference them on live calls.$e$),
('f1000000-0000-0000-0000-000000000002',3,$q$What is the after-hours service called?$q$,$j$["DoctorDoctor","NurseOnCall","HealthDirect","After Hours GP"]$j$::jsonb,0,$e$DoctorDoctor is the bulk-billed after-hours service.$e$);

-- O3 · Your Systems & Logins
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f1000000-0000-0000-0000-000000000003',1,$q$Which system is the appointment book and billing?$q$,$j$["Medical Director","HotDoc","Pracsoft","3CX"]$j$::jsonb,2,$e$Pracsoft is the appointment book and billing/receipting system.$e$),
('f1000000-0000-0000-0000-000000000003',2,$q$Which system holds clinical records, results and letters (the orange "C")?$q$,$j$["Pracsoft","Medical Director","HotDoc","3CX"]$j$::jsonb,1,$e$Medical Director (MD), opened via the orange "C" icon.$e$),
('f1000000-0000-0000-0000-000000000003',3,$q$Can you give a clinic or portal login to a patient?$q$,$j$["Yes if they ask nicely","Only the wifi password","No, never","Only with manager approval"]$j$::jsonb,2,$e$Credentials are confidential and are never given to patients.$e$);

-- O4 · How We Communicate & Escalate
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f1000000-0000-0000-0000-000000000004',1,$q$How do you reach a doctor quickly (e.g. a late patient)?$q$,$j$["Call their personal mobile","Send a Bubble message","Email reception and wait","Post in WhatsApp only"]$j$::jsonb,1,$e$Use a Bubble message with the patient name, DOB and concern.$e$),
('f1000000-0000-0000-0000-000000000004',2,$q$Where do complaints and manager requests go?$q$,$j$["The doctor","The Practice Manager (Lisa)","IT support","HotDoc"]$j$::jsonb,1,$e$Complaints go to the Practice Manager, ideally by email for a timestamp.$e$),
('f1000000-0000-0000-0000-000000000004',3,$q$When escalating a caller's concern, what should you capture?$q$,$j$["Caller name, patient DOB, callback number and the concern","Just their first name","Only the doctor they want","Nothing — pass it straight through"]$j$::jsonb,0,$e$Capture caller name, patient DOB, a good callback number and the concern.$e$);

-- O5 · Privacy & Confidentiality
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f1000000-0000-0000-0000-000000000005',1,$q$Can you confirm to a caller whether someone is even a patient?$q$,$j$["Yes","Only to close family","No","Only to the police"]$j$::jsonb,2,$e$The golden rule: we cannot confirm someone is a patient, no matter who asks.$e$),
('f1000000-0000-0000-0000-000000000005',2,$q$Before discussing a file, how do you verify identity?$q$,$j$["Name and DOB","Medicare number only","Their address only","No need to verify"]$j$::jsonb,0,$e$Verify with name and DOB before discussing any file.$e$),
('f1000000-0000-0000-0000-000000000005',3,$q$About results, what may you tell a patient?$q$,$j$["The full results","Only whether the results are in","The diagnosis","Nothing at all"]$j$::jsonb,1,$e$You may only say whether results are in — never the content — and follow the doctor's annotation.$e$);

-- ==========================================================================
-- TRAINING QUIZZES
-- ==========================================================================

-- T1 · Phone Skills & Triage
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000001',1,$q$A caller reports chest pain and difficulty breathing. What do you do?$q$,$j$["Book the next available appointment","Call 000 / direct them to Emergency","Take a message for the doctor","Book a telehealth appointment"]$j$::jsonb,1,$e$Chest pain / difficulty breathing is Category 1 — call 000 or go to ED.$e$),
('f2000000-0000-0000-0000-000000000001',2,$q$If you are unsure how urgent a situation is, you should:$q$,$j$["Guess and book accordingly","Escalate to a nurse or doctor","Tell them to wait and see","Book them in two weeks"]$j$::jsonb,1,$e$When in doubt, escalate to a nurse or doctor.$e$),
('f2000000-0000-0000-0000-000000000001',3,$q$In the JADE method for difficult calls, what does the "D" stand for?$q$,$j$["Delay","Demonise (the cost, not the patient)","Deny","Discount"]$j$::jsonb,1,$e$Justify, Apologise, Demonise the cost (Medicare doesn't cover running a centre), Explain.$e$),
('f2000000-0000-0000-0000-000000000001',4,$q$A caller is rude and ranting. What is the best action?$q$,$j$["Argue your point","Hang up immediately","Ask them to put the complaint in writing","Offer a discount"]$j$::jsonb,2,$e$Ask them to submit the complaint in writing; don't argue. Complaints go to the PM.$e$);

-- T2 · The Appointment Book
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000002',1,$q$Which shortcut finds the next available appointment?$q$,$j$["F2","Shift+F5","Ctrl+Q","Alt+F4"]$j$::jsonb,1,$e$Shift+F5 (or right-click > Find Next Unbooked). F2 finds an existing appointment.$e$),
('f2000000-0000-0000-0000-000000000002',2,$q$A patient will be more than 15 minutes late for the last appointment. What is required?$q$,$j$["Just book them in","The doctor's explicit OK, or rebook","Always rebook automatically","Charge a late fee"]$j$::jsonb,1,$e$Over 15 minutes late needs the doctor's explicit approval, otherwise rebook.$e$),
('f2000000-0000-0000-0000-000000000002',3,$q$What is the default policy on walk-ins?$q$,$j$["Always welcome","No — check with the doctor for each request","Only in the morning","Anytime with any doctor"]$j$::jsonb,1,$e$Default is no walk-ins; check with the doctor for each request.$e$),
('f2000000-0000-0000-0000-000000000002',4,$q$A new patient finds English difficult. What should you book?$q$,$j$["A 10-minute standard consult","A long first consult","Telehealth only","Nurse only"]$j$::jsonb,1,$e$Book a long first consult — they take longer, and a short slot leads to billing complaints.$e$);

-- T3 · Booking Rules & Doctor Preferences
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000003',1,$q$Before adding a "fit" (squeezed-in) appointment, you must:$q$,$j$["Just add it","Get the doctor's approval","Ask the patient","Charge extra"]$j$::jsonb,1,$e$Never add fit appointments without the doctor's approval.$e$),
('f2000000-0000-0000-0000-000000000003',2,$q$A telehealth Medicare rebate applies only if the patient:$q$,$j$["Always gets one","Has been seen face-to-face within the last 12 months","Is over 65","Has private health"]$j$::jsonb,1,$e$Telehealth rebates require a face-to-face visit within the last 12 months.$e$),
('f2000000-0000-0000-0000-000000000003',3,$q$Where is the current per-doctor rules table kept?$q$,$j$["In this module","In the Footscray Cheat Sheet","In HotDoc","In your email"]$j$::jsonb,1,$e$The cheat sheet holds the current, source-of-truth doctor rules.$e$),
('f2000000-0000-0000-0000-000000000003',4,$q$Which doctors perform IUD insertions?$q$,$j$["Any doctor","Dr Tang or Dr John","The nurse","The podiatrist"]$j$::jsonb,1,$e$IUD insertions are done by Dr Tang or Dr John (Tang preferred).$e$);

-- T4 · Medicare & Billing Basics
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000004',1,$q$What billing model does the clinic use?$q$,$j$["Fully bulk billed","Mixed billing","Private only","Free"]$j$::jsonb,1,$e$Footscray runs a mixed billing model — most patients pay a gap and claim a rebate.$e$),
('f2000000-0000-0000-0000-000000000004',2,$q$When a patient asks if they are bulk-billed, you should:$q$,$j$["Assume yes","Assume no","Ask what card they have and the letters in the bottom-right corner","Charge the full fee"]$j$::jsonb,2,$e$Ask what card they hold and the letters bottom-right — AGE/CAR/DSP are BB.$e$),
('f2000000-0000-0000-0000-000000000004',3,$q$Which group is bulk-billed?$q$,$j$["Everyone","Children 16 and under, DVA, and pensioners/DSP over 65","Only new patients","Only telehealth patients"]$j$::jsonb,1,$e$Children under 16, DVA card holders, and pensioners/DSP over 65 (per concession rules).$e$),
('f2000000-0000-0000-0000-000000000004',4,$q$Where should you quote current fees from?$q$,$j$["Memory","The cheat sheet fee tables","Whatever the patient says","HotDoc reminders"]$j$::jsonb,1,$e$Always quote from the current cheat sheet fee tables — never memory, as they change.$e$);

-- T5 · Payments, HotDoc & Pre-Auth
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000005',1,$q$A HotDoc telehealth booking places what hold, and how long to complete pre-auth?$q$,$j$["$50, 30 minutes","$90, 90 minutes","$120, 24 hours","No hold"]$j$::jsonb,1,$e$A $90 hold; the patient must complete pre-auth within 90 minutes or it cancels.$e$),
('f2000000-0000-0000-0000-000000000005',2,$q$How should a bulk-billed or DVA telehealth appointment be booked?$q$,$j$["As a private telehealth type","As a Phone Consult (Ctrl+Q) — no pre-auth","It cannot be booked","Always with a $90 hold"]$j$::jsonb,1,$e$BB/DVA telehealth = Phone Consult (Ctrl+Q); no pre-auth is triggered.$e$),
('f2000000-0000-0000-0000-000000000005',3,$q$Paying on the same day as the consult lets you:$q$,$j$["Waive the fee","Transmit the Medicare claim for the patient","Skip the receipt","Nothing"]$j$::jsonb,1,$e$Same-day payment means the Medicare claim can be transmitted for them.$e$),
('f2000000-0000-0000-0000-000000000005',4,$q$In a HotDoc payment request, the Reference field should contain:$q$,$j$["The patient's name","The Pracsoft receipt/invoice number","The doctor's mobile","Nothing"]$j$::jsonb,1,$e$Reference = the Pracsoft receipt/invoice number; description = the consult type.$e$);

-- T6 · Appointment Types & Procedures
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000006',1,$q$Long (1-hour) appointments may only be booked:$q$,$j$["Anytime","10am-3pm (ending by 4pm) and only when two nurses are on","After 6pm","On weekends only"]$j$::jsonb,1,$e$Long appts (iron infusion, health assessment) run 10am-3pm, ending by 4pm, with two nurses.$e$),
('f2000000-0000-0000-0000-000000000006',2,$q$How is an iron infusion booked?$q$,$j$["Straight in with the nurse","Discuss with the doctor first, then nurse 1hr + doctor 10 min","Telehealth","Nurse 10 min only"]$j$::jsonb,1,$e$Must be discussed with the doctor first; existing patients only.$e$),
('f2000000-0000-0000-0000-000000000006',3,$q$How many health assessments can be booked per day?$q$,$j$["Unlimited","A maximum of 2, not back-to-back","5","1 only"]$j$::jsonb,1,$e$Max 2 per day and don't book them back-to-back.$e$),
('f2000000-0000-0000-0000-000000000006',4,$q$Before quoting a procedure charge, you should:$q$,$j$["Guess from the fee list","Double-check the amount with the doctor","Charge the highest fee","Not quote anything"]$j$::jsonb,1,$e$Always double-check the charge with the doctor before quoting it.$e$);

-- T7 · Nurse & Treatment Room
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000007',1,$q$A NEW patient wants a nurse-only service. Usually they must first:$q$,$j$["See a doctor first","Book straight with the nurse","Pay a deposit","Do nothing special"]$j$::jsonb,0,$e$New patients usually need a doctor first (they may need tests or a prescription).$e$),
('f2000000-0000-0000-0000-000000000007',2,$q$Many nurse services are billed as:$q$,$j$["Bulk-billed consults","Fixed, non-rebatable fees under TRM (treatment room)","Long consults","Free"]$j$::jsonb,1,$e$Services like holter/BP monitors and AIR uploads are fixed TRM fees, non-rebatable.$e$),
('f2000000-0000-0000-0000-000000000007',3,$q$For a treatment-room service that requires payment, you should:$q$,$j$["Bill it later","Take payment at booking and note how they paid","Waive it","Charge double"]$j$::jsonb,1,$e$Take payment at the time of booking and note how they paid on the appointment.$e$),
('f2000000-0000-0000-0000-000000000007',4,$q$A childhood immunisation is booked as:$q$,$j$["Nurse only, 20 min","10 min nurse + 10 min doctor","Doctor only","1 hour"]$j$::jsonb,1,$e$Childhood immunisation = 10 min nurse + 10 min doctor.$e$);

-- T8 · Vaccinations & Immunisation
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000008',1,$q$Who can administer a yellow fever vaccine?$q$,$j$["Any nurse","A certified GP only","Reception","The pharmacist"]$j$::jsonb,1,$e$Yellow fever can only be given by a certified GP — nurses cannot inject it.$e$),
('f2000000-0000-0000-0000-000000000008',2,$q$The first dose of a childhood-schedule vaccine usually needs:$q$,$j$["A nurse only","A doctor","No appointment","A specialist"]$j$::jsonb,1,$e$The first dose usually needs a doctor (first visit to the clinic).$e$),
('f2000000-0000-0000-0000-000000000008',3,$q$An AIR immunisation upload for a patient with NO Medicare requires:$q$,$j$["Nothing extra","An IHI number first","A referral","A doctor consult"]$j$::jsonb,1,$e$No Medicare means they need an IHI number before the AIR upload can be done.$e$),
('f2000000-0000-0000-0000-000000000008',4,$q$A travel vaccination consult is booked with:$q$,$j$["A doctor","The nurse (Christine) — fee applies, no rebate","Reception","A pharmacist"]$j$::jsonb,1,$e$Travel vax consults are with the nurse (Christine); a discussion fee applies with no rebate.$e$);

-- T9 · Allied Health Bookings
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000009',1,$q$Physiotherapy appointments are booked in:$q$,$j$["Pracsoft","Google Calendar (red = new, blue = follow-up)","Cliniko","HotDoc"]$j$::jsonb,1,$e$Physio is booked in Google Calendar — red marks a new patient, blue a follow-up.$e$),
('f2000000-0000-0000-0000-000000000009',2,$q$Psychology consults are:$q$,$j$["Face-to-face only","Telehealth only, and need a Mental Health Treatment Plan","Bulk-billed for everyone","Booked in Cliniko"]$j$::jsonb,1,$e$Psychology is telehealth only, 1 hour, and needs an MHTP (else private).$e$),
('f2000000-0000-0000-0000-000000000009',3,$q$The psychologist's personal email:$q$,$j$["Can be given to patients","Is never given to patients","Is on the website","Is for bookings only"]$j$::jsonb,1,$e$That email is never given to patients — used only for provider cancellations.$e$),
('f2000000-0000-0000-0000-000000000009',4,$q$A care plan allows how many bulk-billed allied-health sessions per year?$q$,$j$["3","5","10","Unlimited"]$j$::jsonb,1,$e$Up to 5 bulk-billed allied-health sessions per year with a care plan + referral/EPC.$e$);

-- T10 · Results, Certificates & Records
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('f2000000-0000-0000-0000-000000000010',1,$q$About a patient's results, you may tell them:$q$,$j$["The full results","Only whether the results are in","The diagnosis","Nothing at all"]$j$::jsonb,1,$e$Only whether results are in — never the content.$e$),
('f2000000-0000-0000-0000-000000000010',2,$q$A result annotated "Discuss" by the doctor means:$q$,$j$["No action needed","Book the patient in for a consult","Send it by SMS","Ignore it"]$j$::jsonb,1,$e$"Discuss" = book a consult; "No action" = nothing to discuss.$e$),
('f2000000-0000-0000-0000-000000000010',3,$q$When scanning, a document to be kept on the patient goes to:$q$,$j$["Holding File","Store To Patient","The bin","Email"]$j$::jsonb,1,$e$Store To Patient for documents kept on the file; everything else to the Holding File.$e$),
('f2000000-0000-0000-0000-000000000010',4,$q$A lawyer or insurer report request requires:$q$,$j$["A quick phone call","A formal letter plus the patient's signed consent","Just an email","Nothing"]$j$::jsonb,1,$e$Require a formal letter and the patient's signed consent before acting.$e$);
