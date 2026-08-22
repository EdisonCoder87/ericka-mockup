-- ============================================================================
-- Ericka Portal — migration 03: module content + Footscray cheat sheet
-- Run in Supabase SQL Editor AFTER migration 02 (choose "Run without RLS").
-- Re-runnable: clears existing sections/cheatsheet first.
-- ============================================================================

delete from module_sections;
delete from cheatsheets where site = 'Footscray';

-- ==========================================================================
-- ONBOARDING MODULES
-- ==========================================================================

-- O1 · Welcome & The Ericka Way ------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f1000000-0000-0000-0000-000000000001',1,'Who we are', $md$**Ericka** provides healthcare virtual assistants to Australian clinics. When you pick up the phone, you represent **two** teams at once: Ericka, and the clinic you support (right now, **SIA Medical Footscray**).

Our promise is **malasakit** — genuine care. We are *human-led, AI-harnessed*: technology helps us, but the warmth and judgement are yours.$md$),
('f1000000-0000-0000-0000-000000000001',2,'Your role as a remote receptionist', $md$You are often the **first voice** a patient hears. Your job covers:

- **Booking** appointments correctly (right doctor, right length, right rules)
- **Triage** — recognising when something is urgent
- **Billing** — knowing who is bulk-billed and who pays a gap
- **Admin** — messages, results enquiries, certificates, record requests

You work remotely, but you are part of the Footscray team. Be punctual, **clock in/out** on your timesheet, and treat every patient like family.$md$),
('f1000000-0000-0000-0000-000000000001',3,'The standard we hold', $md$Two things must always be **accurate**: a patient's **health** and their **money**.

- If you are not sure about something clinical or a fee — **do not guess**. Check the cheat sheet, or ask.
- Protect **confidentiality** at all times (more in the Privacy module).
- Be warm, but **escalate** when a situation is beyond you.

Getting it *right* matters more than getting it *fast*.$md$);

-- O2 · Meet SIA Medical & Your Clinic -----------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f1000000-0000-0000-0000-000000000002',1,'About SIA Medical', $md$SIA Medical is a multi-site GP group across Melbourne — including **Footscray, Essendon, Burwood, Box Hill, Croydon, Montrose, Moonee Ponds and Mulgrave**.

You are supporting the **Footscray** clinic:
- **190 Barkly Street, Footscray VIC 3011** (beside Chemist Warehouse, paid parking)
- **Open:** Mon–Thu 8am–11pm · Fri 8am–9pm · Sat 8am–6pm · Sun 9am–6pm (public holidays may vary)$md$),
('f1000000-0000-0000-0000-000000000002',2,'The clinic team', $md$- **Doctors (GPs):** a full list with each doctor's rooms, abbreviations and individual booking rules is in the **Footscray Cheat Sheet**.
- **Nurses:** Brendon (Registered Nurse), Christine (Enrolled Nurse).
- **Allied health:** Podiatry, Physiotherapy, Psychology, Exercise Physiology.
- **Practice Manager:** Lisa Bajada — complaints and manager-level issues go to her.$md$),
('f1000000-0000-0000-0000-000000000002',3,'Facts you''ll use every day', $md$- **Phone:** (03) 8538 8111  ·  **Fax:** (03) 8538 8112
- **Reception email:** footscrayreception@siamedical.com.au
- **After hours:** DoctorDoctor (bulk-billed after-hours home-visit service)

You don't need to memorise the detail — the **Footscray Cheat Sheet** keeps all the particulars in one place for live calls.$md$);

-- O3 · Your Systems & Logins --------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f1000000-0000-0000-0000-000000000003',1,'The core systems', $md$- **Pracsoft** — the appointment book + billing/receipting.
- **Medical Director (MD)** — clinical records, results, letters/certificates. Opened via the orange **"C"** icon.
- **HotDoc** — online bookings, SMS reminders, and **payment requests**.
- **3CX** — the phone system you answer calls on.$md$),
('f1000000-0000-0000-0000-000000000003',2,'Remote desktop & IT support', $md$You work through a **remote desktop (RD)**. If an RD or system problem is stopping you:

- **IT = Jose Health IT.** Non-urgent → email support.coordinator@jose-healthit.com.au. Urgent → phone (they prefer phone for urgent).
- Always say you are a **remote receptionist from SIA** and state **which site** you're working.$md$),
('f1000000-0000-0000-0000-000000000003',3,'Handling logins securely', $md$Credentials are **confidential**:

- Never share a login, and never give a clinic/portal login to a **patient**.
- Store your access securely; don't write passwords where others can see.
- The specific usernames/portals for Footscray are in the cheat sheet; **passwords are provided to you securely by your manager**, not stored in the portal.$md$);

-- O4 · How We Communicate & Escalate ------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f1000000-0000-0000-0000-000000000004',1,'Reaching a doctor — Bubble', $md$To reach a doctor quickly (e.g. a late patient, or an urgent query), send a **Bubble message** in Pracsoft/MD. Keep it short and complete:

> **Patient name · DOB · the concern**

Bubble the doctor *first* when a patient will be late, before accepting the change.$md$),
('f1000000-0000-0000-0000-000000000004',2,'Team channels', $md$- **SIA Footscray WhatsApp group** + **Pracsoft messenger** — quick questions to the in-clinic team.
- **Reception email** (footscrayreception@siamedical.com.au) — anything that needs a written record.

If you can't get a quick answer, leave a clear note for in-clinic reception and let the patient know you'll get back to them.$md$),
('f1000000-0000-0000-0000-000000000004',3,'When and how to escalate', $md$- **Complaints / manager requests →** Practice Manager (Lisa), via email for a timestamp.
- **Clinical urgency →** nurse/doctor immediately (see Triage).
- **IT problems →** Jose Health IT.

Always capture: **caller name · patient DOB · good callback number · the concern.** Never promise an outcome you can't control (e.g. a specific fee waiver or a doctor's decision).$md$);

-- O5 · Privacy & Confidentiality ----------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f1000000-0000-0000-0000-000000000005',1,'The golden rule', $md$**We cannot confirm that someone is even a patient**, or share *any* appointment or health information, to anyone — no matter how much they push.

> "Just as a blanket rule, we can't tell people who have an appointment regardless of who they are, for privacy reasons. We can't even say if they are a patient." — Lisa

Stay calm and repeat that you're unable to share any information.$md$),
('f1000000-0000-0000-0000-000000000005',2,'The Australian Privacy Principles (in short)', $md$Patient health information is sensitive and protected. In plain terms:

- Only **collect** what you need to provide care.
- Only **use** it for that care.
- **Store** it securely and never disclose it improperly.
- Patients can **request** their records (via the proper signed process).$md$),
('f1000000-0000-0000-0000-000000000005',3,'Privacy in practice', $md$- **Verify identity** (name + DOB) before discussing a file.
- Some emails are **never** given to patients (e.g. the psychologist's personal email).
- **Record transfers** need a signed transfer form; turnaround ~7 days.
- **Results:** you may only say whether results are *in* — never the content — and follow the doctor's "Discuss / No action" annotation.$md$);

-- O6 · Complete Your Training (gateway) ---------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f1000000-0000-0000-0000-000000000006',1,'Before you go live', $md$The final onboarding step is to **complete all 10 training modules**. They cover:

Phone & triage · the appointment book · doctor booking rules · Medicare & billing · payments & pre-auth · appointment types & procedures · nurse & treatment room · vaccinations · allied health · results & records.$md$),
('f1000000-0000-0000-0000-000000000006',2,'How it works', $md$- Work through each training module **in order** and mark it complete as you go.
- Your **manager and team lead** can see your progress.
- Onboarding is only finished once your training modules are done.$md$),
('f1000000-0000-0000-0000-000000000006',3,'Keep the cheat sheet handy', $md$The **Footscray Cheat Sheet** (in your sidebar) holds the doctor rules, fees, item numbers and key contacts you'll reference on live calls. Keep it open while you work — you're not expected to memorise it.$md$);

-- ==========================================================================
-- TRAINING MODULES
-- ==========================================================================

-- T1 · Phone Skills & Triage --------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000001',1,'Answering the SIA way', $md$- Warm greeting, identify the clinic, and help efficiently.
- Get the patient's **name and DOB early** — you'll need them to find or create the file.
- Note anything time-sensitive (running late, urgent concern) and act on it.$md$),
('f2000000-0000-0000-0000-000000000001',2,'The triage safety net (6 categories)', $md$Triage is about spotting danger. When in doubt, **escalate to a nurse/doctor**.

- **Cat 1 (emergency):** chest pain, difficulty breathing, extensive burns → **Call 000 / go to ED.**
- **Cat 2:** heavy bleeding, head/spinal injury, snakebite, in labour → nurse/doctor **immediately**.
- **Cat 3:** can't urinate, poisoning/overdose, possible fracture, eye injury → come in now; advise nurse.
- **Cat 4:** unwell child, pregnancy pain/bleeding, assault, visual disturbance → come in today or call if worsening.
- **Cat 5:** fever + vomiting <24h, severe rash, cut → appointment within 24h.
- **Cat 6:** adult fever, neck stiffness/altered consciousness → nurse/doctor immediately.

(Reference: the HotDoc Triage webinar in your onboarding links.)$md$),
('f2000000-0000-0000-0000-000000000001',3,'Difficult calls — the JADE method', $md$For pushback (e.g. about mixed-billing gaps), use **JADE**:

- **Justify** — why we moved to mixed billing.
- **Apologise** — acknowledge it's a big change.
- **Demonise** *(the cost, not the patient)* — Medicare doesn't cover the cost of running a centre.
- **Explain** — we kept the gap as low as we could to keep providing quality care.

If a caller is **rude or ranting**, tell them you can't assist while they're behaving that way and ask them to put the complaint **in writing**; complaints go to the Practice Manager. Don't argue.$md$);

-- T2 · The Appointment Book ---------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000002',1,'Searching & finding', $md$- **Find an existing appointment:** press **F2** or right-click → *Find Appointment*. Enter surname then first name, adjust the dates, search.
- **Find the next available:** press **Shift+F5** or right-click → *Find Next Unbooked Appointment*, choose the doctor/specialist, search.$md$),
('f2000000-0000-0000-0000-000000000002',2,'Booking a new patient', $md$Create the patient file with:

First name · Last name · DOB · Sex · Address · Email · Contact number (**tick to send SMS**) · allocate a **Chart Number** · Medicare card details.

Tip: for new patients who find English difficult, book a **long** first consult (they take longer, and a 10-min slot leads to a "why was I charged long?" complaint).$md$),
('f2000000-0000-0000-0000-000000000002',3,'Move, cancel & late patients', $md$- **Reschedule/move:** find the appointment → right-click **Cut** → paste into the new slot/doctor.
- **Cancel:** select the appointment → right-click **Delete**. Check with in-clinic reception whether a cancellation fee applies.
- **Late:** if >10 min, ask how long. **Anything over 15 min late needs the doctor's explicit OK or it's a rebook** — bubble the doctor first.
- **Walk-ins:** default is **no** — check with the doctor for each request.$md$);

-- T3 · Booking Rules & Doctor Preferences -------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000003',1,'Why every doctor is different', $md$Each GP sets their **own** availability, appointment lengths and rules (new-patient policy, telehealth, WorkCover, procedures they perform). **Always check before booking.**

The full, current **per-doctor table** lives in the **Footscray Cheat Sheet** — treat it as the source of truth.$md$),
('f2000000-0000-0000-0000-000000000003',2,'Common patterns to know', $md$- Some doctors are **OTSP / not accepting new patients** except specific cases (e.g. Dr He).
- **New patients** often need a **double appointment**.
- Some require **credit-card details on file** before a telehealth booking (e.g. Dr Andres).
- **Telehealth rebate** applies only if the patient has been seen **face-to-face in the last 12 months** — otherwise it's a private fee.
- The right **doctor for the service** matters (e.g. IUD insertions = Dr Tang or Dr John).$md$),
('f2000000-0000-0000-0000-000000000003',3,'Golden habits', $md$- **Never add "fit" appointments without the doctor's approval.**
- Don't book long procedures outside their allowed windows.
- If a doctor/nurse has already booked something outside the normal rules, **leave it as is**.$md$);

-- T4 · Medicare & Billing Basics ----------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000004',1,'Bulk-billing vs mixed billing', $md$Footscray runs a **mixed billing** model — most patients pay a gap and claim a Medicare **rebate**.

**Bulk-billed (BB)** groups include: children **16 and under**, **DVA** card holders, and **pensioners/DSP over 65** — plus concession rules below.$md$),
('f2000000-0000-0000-0000-000000000004',2,'Concession cards — ask, never assume', $md$When a patient asks "am I bulk-billed?", **ask what card they have and the letters in the bottom-right corner:**

- **AGE** (65+), **CAR**, **DSP** → bulk-billed.
- **HCC / JSP / PPS** etc → charged at the health-care-card rate (doctor's discretion).
- An **AGE pension card is not the same as an HCC** — don't treat them alike.

If someone seems distressed about paying, gently ask about concession/pension cards in case they *should* be BB.$md$),
('f2000000-0000-0000-0000-000000000004',3,'Fees, rebates & item numbers', $md$Fees vary by **time** (standard vs long; after-hours and weekend loadings) and by **telehealth vs face-to-face**.

**Always quote fees from the current fee tables in the Footscray Cheat Sheet** — never from memory, as they change. The cheat sheet also lists the common **item numbers** and rebates.$md$);

-- T5 · Payments, HotDoc & Pre-Auth --------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000005',1,'Requesting a payment (HotDoc)', $md$**HotDoc Dashboard → Payments → Payment Requests → New Payment Request** (green button) → Find Patient → Select → choose the appointment (or *Skip Step*) → confirm mobile & practitioner → **Reference** = Pracsoft receipt/invoice number → **Description** = consult type → enter **amount** → **Send Now**.

The payment link goes to the patient's mobile.$md$),
('f2000000-0000-0000-0000-000000000005',2,'Telehealth pre-authorisation', $md$- A HotDoc telehealth/private booking places a **$90 hold**; the patient must complete pre-auth within **90 minutes** or the appointment cancels.
- Pre-auth is valid within **7 days**; bookings further out expire to "Card Details Stored".
- **BB / DVA** patients → book as **Phone Consult (Ctrl+Q)** — **no** pre-auth triggered.
- **TAC/WC** vary — see the special-billing notes.$md$),
('f2000000-0000-0000-0000-000000000005',3,'Cards, receipts & Medicare claims', $md$- Procedures (e.g. IUD) use a **credit-card authority form**; the fee is processed after the procedure.
- **Ensure the patient doesn't leave without paying**, and double-check the amount with the doctor.
- **Same-day payment** → the Medicare claim can be transmitted for them. **Paid later** (for an earlier consult) → email the receipt so they claim it themselves.$md$);

-- T6 · Appointment Types & Procedures -----------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000006',1,'Appointment length rules', $md$- **Short — 10 min:** most injections, short procedures. Can be booked anytime, alongside long appointments.
- **Medium — 20–30 min:** longer procedures. **Cannot overlap** another 30-min-or-longer appointment.
- **Long — 1 hour:** iron infusions, health assessments. **Only 10 AM–3 PM (ending by 4 PM), and only when two nurses are on shift.**
- **Never** book two long procedures / iron infusions / health assessments at the same time.$md$),
('f2000000-0000-0000-0000-000000000006',2,'Key procedures at a glance', $md$- **Iron infusion:** discuss with the doctor first → then nurse **1 hr** + doctor **10 min**; existing patients only.
- **IUD / Implanon:** consult first (doctor decides), then a procedure appointment with the **credit-card authority form**.
- **Health assessments:** max **2 per day**, don't book back-to-back.
- **Care plans:** bulk-billed; typically GP 20 min + nurse.

Exact fees, item numbers and durations are in the cheat sheet.$md$),
('f2000000-0000-0000-0000-000000000006',3,'Always', $md$- Many procedures need **doctor approval first**.
- Confirm the **correct doctor** performs the procedure.
- **Double-check the charge** with the doctor before quoting it.$md$);

-- T7 · Nurse & Treatment Room -------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000007',1,'What the nurses do', $md$Immunisations, dressings, holter & BP monitors, spirometry, iron infusions (with a doctor), and AIR immunisation uploads.

A **new** patient wanting a nurse-only service usually needs to see a **doctor first** (the doctor may need to order tests or prescribe).$md$),
('f2000000-0000-0000-0000-000000000007',2,'Treatment-room (TRM) billing', $md$Many nurse services are **fixed, non-rebatable fees billed under TRM** — e.g. 24-hr holter/BP monitors, AIR uploads, some dressings.

- Take payment **at the time of booking** where required, and note **how** they paid on the appointment.
- Some services (e.g. holter) also need a copy of the patient's licence uploaded.$md$),
('f2000000-0000-0000-0000-000000000007',3,'Matching durations', $md$Nurse and doctor times must line up — e.g. childhood immunisation = **10 min nurse + 10 min doctor**; iron infusion = **1 hr nurse + 10 min doctor**.

Use the **Appointment Type table** in the cheat sheet for the correct durations, codes and fees.$md$);

-- T8 · Vaccinations & Immunisation --------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000008',1,'Government vs private', $md$- **Childhood schedule** (Infanrix Hexa, Prevenar 13, Rotarix, MMR, etc.) — government funded; the **first dose usually needs a doctor**.
- **Catch-up & program vaccines** (shingles, RSV in pregnancy, flu for 65+, etc.) — check eligibility; many still need a doctor.$md$),
('f2000000-0000-0000-0000-000000000008',2,'Travel vaccinations', $md$- **Travel vax consult** is with the **nurse (Christine)** — a discussion fee applies, no rebate; **yellow fever is not included** and can only be given by a **certified GP** (nurses can't inject it).
- Some travel vaccines are private and stocked in-clinic; patients may split doses across follow-up visits (only the injection fee applies on follow-ups).$md$),
('f2000000-0000-0000-0000-000000000008',3,'AIR & immunisation records', $md$- Uploading immunisation history to **AIR** (Brendan) — a fee applies; **no Medicare → an IHI number is needed first**.
- Bring originals/documents; new-patient uploads take longer as they're entered manually.

The full **vaccine price list** and item codes are in the cheat sheet.$md$);

-- T9 · Allied Health Bookings -------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000009',1,'Providers & systems', $md$- **Podiatry** (Peter) — booked in **Cliniko**, 20-min appointments.
- **Physiotherapy** (Alessandro / Evado) — booked in **Google Calendar**; **red = new patient, blue = follow-up**.
- **Psychology** (Leanne) — **Pracsoft**, **telehealth only**, 1 hour, needs a **Mental Health Treatment Plan**.
- **Exercise Physiology** (Jessica) — EPC + care plan required for bulk billing.$md$),
('f2000000-0000-0000-0000-000000000009',2,'Referrals & rebates', $md$- **Referral + EPC/care plan** → Medicare rebate or bulk-billed (depending on the provider).
- **No referral/EPC** → fully private (can claim via private health if covered).
- A care plan allows up to **5 bulk-billed allied-health sessions per year**.$md$),
('f2000000-0000-0000-0000-000000000009',3,'Cancellations', $md$- **Physio:** email newport@evadostudios.com.au **and** notify the SIA FS WhatsApp group.
- **Psychology:** email l_piller@hotmail.com with patient details + reason — **this email is never given to patients.**
- Cancellation fees may apply and are encoded into the patient's Pracsoft account.$md$);

-- T10 · Results, Certificates & Records ---------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('f2000000-0000-0000-0000-000000000010',1,'Checking results', $md$In **Pracsoft**, search the patient → open **MD (orange "C")** → **Results** tab (also check Letters, Documents, Correspondence, and *Check Holding File*).

- You may **only** tell a patient whether results are **in** — never the content.
- Follow the doctor's annotation: **"Discuss"** = book a consult; **"No action"** = nothing to discuss.$md$),
('f2000000-0000-0000-0000-000000000010',2,'Certificates & letters', $md$Medical/carer certificates: **MD → Letters → Letter Writer → File → New**, choose the "Medical Certificate" template and the doctor.

- Add the doctor's **digital signature** before sending, and email from the reception address.
- **No backdating** a certificate unless the patient was seen that day.$md$),
('f2000000-0000-0000-0000-000000000010',3,'Scanning & record requests', $md$- **Scanning:** documents to be kept on the patient → **Store To Patient**; everything else → **Holding File**.
- **Record transfer:** needs a **signed** transfer form; ~7 days as the doctor reviews first.
- **Lawyer/insurer reports:** require a **formal letter + the patient's signed consent** — not just an email — before we act.$md$);

-- ==========================================================================
-- FOOTSCRAY CHEAT SHEET  (site-scoped; VAs at Footscray + managers)
-- ==========================================================================
insert into cheatsheets (site, ord, heading, body) values
('Footscray',1,'📇 Key Contacts & Details', $md$- **Address:** 190 Barkly Street, Footscray VIC 3011 (beside Chemist Warehouse)
- **Phone:** (03) 8538 8111 · **Fax:** (03) 8538 8112
- **Reception email:** footscrayreception@siamedical.com.au
- **Hours:** Mon–Thu 8am–11pm · Fri 8am–9pm · Sat 8am–6pm · Sun 9am–6pm
- **IT (Jose Health IT):** support.coordinator@jose-healthit.com.au · (03) 8456 5300 *(urgent = phone)*
- **After hours:** DoctorDoctor (bulk-billed home visits)
- **ABN (SIA Footscray):** 56 600 038 211$md$),
('Footscray',2,'🩺 Our Doctors, Rooms & Abbreviations', $md$| Room | Doctor | Abbr |
|---|---|---|
| 6-206 | Dr Kidd Leong | HKL |
| 16-216 | Dr John He | JH |
| 3-203 | Dr Zun May Tang | ZMT |
| 2-202 | Dr Lyra Rinaudo | LR |
| 14-220 | Dr Aly Sir Tang | AST |
| 4-204 | Dr Omar Zuleta | OZ |
| 5-205 | Dr Malcolm Webb | MW |
| 7-207 | Dr Andres Acosta Rippe | AAR |
| 8-208 | Dr Victor Luu | VL |
| 9-209 | Dr Darren Loo | HL |
| 10-210 | Dr Yu Gen Lim | YG |
| TRM-215 | Treatment Room | TRM |
| 213 | Peter Shaker (Podiatry) | PS |$md$),
('Footscray',3,'📋 Doctor Availability & Key Rules', $md$*Always check before booking. Highlights only — confirm current rules with in-clinic reception.*

- **Dr John He (JH):** OTSP / not accepting new patients except specific cases (pre-employment, correctional methadone/suboxone/buvidal, new iron infusions, referred by family/friends, prior SIA Box Hill patients, ToP). Max 2 care plans/day; none Thursdays. No new WorkCover.
- **Dr Aly Sir Tang (AST):** No walk-ins (approval required). COVID-symptomatic must mask. No telehealth Sundays; no Sunday baby immunisations.
- **Dr Kidd Leong (HKL):** Medical cannabis ($200, item 36); ADHD assessments; telehealth for new patients (no rebate). Check TGA approval letter on file before a cannabis script.
- **Dr Victor Luu (VL):** No new WorkCover; last appointment of day — late patients rescheduled.
- **Dr Andres (AAR):** New patients need a **double appt** + full PS profile + **credit-card details on file**; telehealth 6–8pm only, not weekends/after 8pm unless higher TH fee ($117); 12-hr cancellation notice.
- **Dr Omar (OZ):** Accepts WorkCover/TAC (double appts). DNA fees apply. Can do Implanon/IUD.
- **Dr Lyra (LR):** IUD, Implanon, medical termination, family planning; new patient = double appt.$md$),
('Footscray',4,'💵 Consultation Fees & Rebates', $md$| When | Consult | Fee | Rebate |
|---|---|---|---|
| Mon–Fri 8am–8pm | Standard | $93.00 | $45.05 |
| Mon–Fri 8am–8pm | Long | $137.00 | $87.10 |
| After 8pm / Sat after 1pm / Sun / PH | Standard | $123.00 | $58.65 |
| After 8pm / Sat after 1pm / Sun / PH | Long | $164.00 | $100.55 |
| Sat before 1pm | Standard | $104.00 | $45.05 |
| Sat before 1pm | Long | $148.00 | $87.10 |
| Telehealth (seen F2F within 12 mths) | Standard | $95.00 | $45.05 |

**Bulk-billed (Mon–Fri 8am–6pm):** DVA, pensioners & DSP (65+), children ≤16 — subject to concession rules.$md$),
('Footscray',5,'🧰 Treatment Room & Procedure Fees', $md$| Service | Fee |
|---|---|
| Wound dressing | $20+ (complexity) |
| Ear syringing | $35 |
| Procedure fee | $80+ (complexity) |
| Cryotherapy | $15+ |
| Iron infusion | $230–$280 |
| 24-hr Holter monitor | $50 |
| 24-hr BP monitor | $50 |
| VIC Roads assessment | $150 |
| Medical marijuana assessment | $200 (rebate $82.90) |

*Full item-number tables (IUD, Implanon, yellow fever, travel vax, etc.) are in the manual.*$md$),
('Footscray',6,'🗣️ Staff Languages', $md$| Person | Speaks |
|---|---|
| Lisa Bajada (PM) | English |
| Sue | English, Indonesian |
| Neil / Arriane / Shane / Lyca | English, Tagalog |
| Hasan | English, Urdu, Hindi |
| Daniela / Lorena | English, Spanish |
| Sarah | English, Cantonese |
| Pino | English, Mandarin, Taiwanese, Japanese |
| Eunice | English, Tagalog, Mandarin, Hokkien |

Doctors: Dr He (Mandarin), Dr Tang/Loo (Cantonese, Mandarin), Dr Andres/Omar (Spanish), Dr Victor (Vietnamese).$md$),
('Footscray',7,'🤝 Allied Health & On-Site Services', $md$- **Podiatry (Peter Shaker):** Thu 9–5, Cliniko, 20-min. Care plan + concession = BB; else private ($90 initial / $80 follow-up).
- **Physio (Alessandro / Evado):** Tue 10–2, Thu 8–12, Google Calendar. Gap $30 with care plan + concession; else $115 private.
- **Psychology (Leanne Piller):** Tue & Thu 9–3, Pracsoft, **telehealth only**, 1 hr, needs MHTP; else $150 private. *(Email l_piller@hotmail.com — never give to patients.)*
- **On site:** Pathology (Australian Clinical Labs), Cardio Lab (every 2nd Thu), Apex Hearing/Audiology (every 2nd Tue), Chemist Warehouse downstairs.$md$),
('Footscray',8,'💬 Difficult-Situation Scripts', $md$**Mixed billing (JADE):** Justify → Apologise → Demonise the cost (Medicare doesn't cover running a centre) → Explain we kept the gap as low as possible.

**Records transfer request:** "We can help transfer your records — please fill out this form and let us know where to send them" (~7 days).

**Rude/ranting caller:** "Due to your behaviour I'm unable to assist right now — please submit your complaint in writing and it will be actioned." Complaints → Practice Manager (Lisa), by email.

**Reschedule (couldn't reach by phone):** email — *"We've tried to reach you to reschedule your appointment with Dr XX on [date/time]. Please call us on (03) 8538 8111 to rebook."*$md$),
('Footscray',9,'🔐 Systems & Logins', $md$| System | Use | Login |
|---|---|---|
| Pracsoft | Appointments + billing | via remote desktop |
| Medical Director (orange "C") | Clinical records, results, letters | via remote desktop |
| HotDoc | Online bookings, reminders, payments | footscrayreception@siamedical.com.au |
| 3CX | Phone system | provided by manager |
| Reception email | Records/correspondence | footscrayreception@siamedical.com.au |

**Passwords are provided to you securely by your manager — they are not stored in this portal.** Never share a login or give one to a patient.$md$);
