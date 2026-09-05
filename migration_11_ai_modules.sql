-- ============================================================================
-- Ericka Portal — migration 11: the AI certification track
--   Two tiers a remote team member can earn, shown to the client as a badge:
--     * AI Assisted  (foundation) — uses AI to solve problems, communicate,
--                                   and write process. Practical: a real SOP.
--     * AI Builder   (builder)    — builds small tools and automations with
--                                   Claude Code. Practical: a working tool.
--   Modules are vertical = 'all' — the same track for medical and dental.
--   ⚠️ Do NOT re-run migration_03 after this: it does `delete from
--      module_sections` and would wipe this content.
-- Re-runnable: clears only its own modules first.
-- ============================================================================

-- Shared modules need a vertical that isn't medical- or dental-specific.
alter table training_modules drop constraint if exists training_modules_vertical_check;
alter table training_modules add constraint training_modules_vertical_check
  check (vertical in ('medical','dental','all'));

delete from module_sections where module_id in (
  select id from training_modules where category = 'ai');
delete from training_modules where category = 'ai';

-- ── The modules ─────────────────────────────────────────────────────────────
insert into training_modules
  (id, vertical, category, tier, ord, title, icon, capability_label, summary,
   requires_evidence, evidence_prompt) values
-- Level 1 — AI Assisted
('aa000000-0000-0000-0000-000000000001','all','ai','foundation',1,
 'AI at Ericka — and the one rule','🤖','AI Basics',
 'What AI is good at, where it is dangerous, and the confidentiality rule you never break.',
 false, null),
('aa000000-0000-0000-0000-000000000002','all','ai','foundation',2,
 'Prompting that actually works','💬','Prompting',
 'Context, the output you want, and how to steer a bad answer into a good one.',
 false, null),
('aa000000-0000-0000-0000-000000000003','all','ai','foundation',3,
 'Drafting patient communication','✉️','AI Comms',
 'Recall messages, arrears scripts and email replies — drafted fast, checked by you.',
 false, null),
('aa000000-0000-0000-0000-000000000004','all','ai','foundation',4,
 'Summarise and extract','📑','Summarising',
 'Turn a long report, inbox or transcript into a short list of actions.',
 false, null),
('aa000000-0000-0000-0000-000000000005','all','ai','foundation',5,
 'Problem-solving — and verifying','🔍','AI Problem-Solving',
 'Software errors, item numbers, policy questions — and how to check before you act.',
 false, null),
('aa000000-0000-0000-0000-000000000006','all','ai','foundation',6,
 'Write a process with AI','📋','Process Writing',
 'Turn what you do into a documented SOP someone else could follow.',
 true,
 'Write a real SOP for a task you actually do, using AI to draft it. Paste a link to the finished document (Google Doc, Drive file or portal page). Your manager reviews it before this module counts.'),
-- Level 2 — AI Builder
('aa000000-0000-0000-0000-000000000007','all','ai','builder',7,
 'Spreadsheets and data with AI','📊','AI Data',
 'Formulas, cleaning a messy report, and building a tracker that adds itself up.',
 false, null),
('aa000000-0000-0000-0000-000000000008','all','ai','builder',8,
 'Automations 101','⚙️','Automation Design',
 'Spot a repeatable task and map it: trigger, steps, output, and what can go wrong.',
 false, null),
('aa000000-0000-0000-0000-000000000009','all','ai','builder',9,
 'Build a small tool with Claude Code','🛠️','Building Tools',
 'From a plain-English description to a working page, step by step.',
 true,
 'Build a small working tool or automation that solves a real problem for your clinic. Paste a link to it (or to a short screen recording of it running). Your manager verifies it works before this module counts.'),
('aa000000-0000-0000-0000-000000000010','all','ai','builder',10,
 'Deploy it and hand it over','🚀','Deploy & Handover',
 'Getting it running for real, documenting it, and handing it to the team.',
 false, null),
('aa000000-0000-0000-0000-000000000011','all','ai','builder',11,
 'Guardrails — where AI must not go','🛡️','AI Guardrails',
 'Never auto-send to a patient. Human check before anything clinical or financial.',
 false, null);

-- ── Content ─────────────────────────────────────────────────────────────────

-- AI 1 · AI at Ericka ---------------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000001',1,'Why we train on this', $md$Most clinics are still arguing about whether to use AI. Ericka's position is settled: **human-led, AI-harnessed**. The care, the judgement and the responsibility stay with you. AI is the fastest junior assistant you will ever have — and it never gets tired of the boring parts.

This track certifies that you can actually do that, at two levels:

- **AI Assisted** — you use AI daily to solve problems, communicate and document process.
- **AI Builder** — you build small tools and automations that save the clinic real hours.

Clients can see these badges on their team page. They are worth something, so we do not hand them out for a quiz score alone — each level ends with a **practical** your manager checks.$md$),
('aa000000-0000-0000-0000-000000000001',2,'What it is good at — and where it fails', $md$**Strong at:** drafting, rewriting, summarising, explaining something unfamiliar, turning a mess into a structure, spotting what you missed, writing formulas and small programs.

**Weak at / dangerous:** anything where being confidently wrong causes harm.

- It will invent a fee, an item number or a policy that sounds completely real.
- It does not know today's schedule, this patient's history, or your clinic's rules unless you tell it.
- It cannot make a clinical judgement. Ever.

The rule of thumb: **AI drafts, you decide.** If being wrong would affect someone's health or someone's money, you verify before it leaves your hands.$md$),
('aa000000-0000-0000-0000-000000000001',3,'The one rule you never break', $md$**No patient-identifying information goes into a public AI tool.**

That means no names, dates of birth, addresses, phone numbers, Medicare numbers, or anything that could identify a person — not in a prompt, not pasted in as "context".

You can still use AI on almost everything, by **de-identifying** first:

> ❌ "Write an SMS to Margaret Chen, 14 Byron St, overdue for her diabetes review"
> ✅ "Write a short, warm SMS to a patient who is overdue for a diabetes review, asking them to call to book"

Then you paste the result into the practice system and add the real details there. Same speed, no breach.

If you are ever unsure whether something counts as identifying — assume it does, and ask your manager.$md$);

-- AI 2 · Prompting ------------------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000002',1,'A good prompt has four parts', $md$Most bad answers are bad questions. A prompt that works usually contains:

1. **Role / context** — "You are helping a receptionist at an Australian GP clinic."
2. **The task** — what you actually want done.
3. **The constraints** — length, tone, who is reading it, what to avoid.
4. **The format** — "as five bullet points", "as an SMS under 160 characters", "as a table".

Compare:

> ❌ "write a recall message"
> ✅ "Write an SMS for an Australian dental clinic to a patient overdue for a 6-month check-up. Warm, not pushy, under 160 characters, ends by asking them to reply or call. Australian spelling."$md$),
('aa000000-0000-0000-0000-000000000002',2,'Steering a bad answer', $md$You almost never get it perfect first time — and you should not retype the whole prompt. Just tell it what was wrong:

- "Too formal — make it sound like a person, not a letter."
- "Shorter. Half the length."
- "You invented a fee. Leave the amount out and put [FEE] instead."
- "Give me three versions with different tones."

**Ask for options.** Three drafts costs you nothing and gives you something to choose between rather than something to fix.$md$),
('aa000000-0000-0000-0000-000000000002',3,'Give it your standard', $md$The single biggest upgrade: show it a good example.

Paste in a message the clinic already sends and say *"match this tone"*. Paste your cheat sheet's booking rules and say *"use only these rules"*. AI is far better at copying a standard than inventing one.

This is also how you stop it inventing: **when the facts come from you, it cannot make them up.**$md$);

-- AI 3 · Patient comms --------------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000003',1,'Where drafting earns its keep', $md$The messages you send over and over are the ones worth templating with AI:

- **Recalls / overdue check-ups** — warm, short, one clear action.
- **Arrears** — firm but respectful; never shaming, never threatening.
- **Failed appointments** — assume the best about why they missed it.
- **Results enquiries** — what you can and cannot say on the phone.
- **Email replies** — the polite, complete answer you do not have time to write at 4:55pm.

Build the template once with AI, get it approved, then reuse it. You are not drafting from scratch every time — you are personalising an approved draft.$md$),
('aa000000-0000-0000-0000-000000000003',2,'The honesty test', $md$Everything you send has to survive being read back to the patient's face.

- **No claims you cannot verify.** If you do not know the fee, do not state one.
- **No pressure tactics.** "Your health matters to us" — not "you will lose your spot".
- **No clinical statements.** You are inviting them to book, not interpreting anything.
- **Australian spelling and plain English.** No "utilise", no "as per our records".

AI will happily write hype. Delete it. The clinic's name is on it.$md$),
('aa000000-0000-0000-0000-000000000003',3,'Never auto-send', $md$A draft is a draft. Every message that reaches a patient is read by a human first — you.

That is not a formality. It is the reason a clinic trusts a remote team with its patients at all. The moment an unreviewed AI message goes out under the clinic's name, the trust is gone and it does not come back.$md$);

-- AI 4 · Summarise & extract --------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000004',1,'From long thing to short list', $md$You will regularly face something long: a 20-page policy, a full inbox, a meeting recording, a week of reports. The skill is turning it into **what needs doing**.

Ask for the shape you want:

> "Summarise this into: 1) decisions made, 2) actions with who owns them, 3) anything still unanswered."

> "From this report, list every patient follow-up that is overdue, as a table with the reason."

The trick is naming the *output shape* up front. "Summarise this" gets you a shorter blob. "Give me the three actions" gets you a to-do list.$md$),
('aa000000-0000-0000-0000-000000000004',2,'Extracting numbers safely', $md$AI is good at pulling numbers out of a messy report — and bad at arithmetic it does in its head.

- Ask it to **extract**, then check the total yourself (or in a spreadsheet).
- Ask it to **show where each number came from**, so you can spot-check one or two.
- If a figure is going in front of a client, verify it. A wrong number in a client report costs more trust than the whole report earns.$md$),
('aa000000-0000-0000-0000-000000000004',3,'The 5-minute daily habit', $md$At the end of a shift, paste your notes in and ask for a **handover summary**: what happened, what is outstanding, what the next person needs to pick up.

Two minutes of work, and the next shift starts informed. This is the habit that makes a remote team feel like it is in the building.$md$);

-- AI 5 · Problem-solving ------------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000005',1,'Describe the problem properly', $md$When something breaks — the practice software throws an error, a printer will not connect, a form will not submit — AI is a very good first responder, *if* you describe it properly:

- **What you were doing** when it happened
- **What you expected**, and **what happened instead**
- **The exact error text** (type it out or paste it)
- **What you already tried**

That is the same information you would give a good colleague. Vague in, vague out.$md$),
('aa000000-0000-0000-0000-000000000005',2,'Verify before you act', $md$This is the module that separates a professional from a liability.

AI will confidently tell you an item number, a rebate amount, a Medicare rule or a clinic policy — and it may be wrong, out of date, or invented. Before you act on anything factual:

- **Fees, item numbers, rebates** → check the cheat sheet or the practice system. Never quote from AI.
- **Clinic rules** → check the cheat sheet or ask the manager.
- **Anything clinical** → not your call, and not AI's. Escalate.

Use AI to *understand* something and to *know what to ask*. Use the clinic's own sources for the answer that leaves your mouth.$md$),
('aa000000-0000-0000-0000-000000000005',3,'Knowing when to stop', $md$Two failed attempts at the same fix is your signal to escalate, not to try a third.

Bring your manager the short version: what is broken, what you tried, what the error says. You will have saved them the diagnosis even if you could not do the repair — and that is still a win.$md$);

-- AI 6 · Write a process ------------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000006',1,'Why processes are the real product', $md$A task you do well helps today. A task **written down** so anyone can do it helps forever — and it is what lets a clinic hand more work to the remote team.

Writing process used to be the slow, hated job. With AI it takes twenty minutes: you talk through what you do, and it structures it.$md$),
('aa000000-0000-0000-0000-000000000006',2,'How to do it in one sitting', $md$1. **Talk it out.** Write or dictate every step of the task, messily, in the order you actually do it. Do not tidy it.
2. **Hand it over:** *"Turn this into a step-by-step SOP with a purpose line, when it is triggered, numbered steps, and what to do when it goes wrong. Plain English."*
3. **Fix what it guessed.** It will smooth over the bits you skipped — those are exactly the bits a new person needs. Add them back.
4. **Test it.** Follow your own SOP once, exactly as written. Every place you had to think is a missing step.
5. **Add the exceptions.** "If the patient has no Medicare card…" — the edge cases are where the value is.$md$),
('aa000000-0000-0000-0000-000000000006',3,'Your practical for AI Assisted', $md$**To earn the AI Assisted badge, write one real SOP** for a task you actually do — recalls, arrears calls, new-patient set-up, end-of-day handover, whatever is yours.

It must be genuinely usable: someone who has never done the task should be able to follow it.

Paste the link on this module and submit it. Your manager reviews it, and once it is verified your badge lights up on the client's team page. A badge nobody checked is worth nothing — that is the point.$md$);

-- AI 7 · Spreadsheets & data --------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000007',1,'Stop fighting formulas', $md$You no longer need to know spreadsheet syntax — you need to describe what you want.

> "In Google Sheets, column C has a date and column F has yes/no. Give me a formula that counts how many rows say yes in the last 7 days."

Ask it to **explain the formula in one line** as well. That is how you stop being dependent: after ten of these you will start recognising the patterns.$md$),
('aa000000-0000-0000-0000-000000000007',2,'Cleaning a messy report', $md$Exports are always messy — names in one column, inconsistent dates, blank rows, totals in the middle of the data.

AI is excellent at describing the clean-up steps, and at writing the formula or script that does it. Give it the first few rows (**de-identified**) and say what "clean" looks like.

Golden rule: **keep the original.** Clean into a copy, always.$md$),
('aa000000-0000-0000-0000-000000000007',3,'Build a tracker that adds itself up', $md$The pattern worth learning: a sheet where you log the thing as it happens, and the summary calculates itself.

Recalls made, arrears collected, treatment follow-ups booked. No end-of-week counting, no arguing about whose number is right. Ask AI to design the columns first, then the summary formulas.

This is also the first half of the next module — you have just described an automation.$md$);

-- AI 8 · Automations 101 ------------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000008',1,'Spotting the right task', $md$Not everything should be automated. The good candidates are:

- **Repeatable** — same steps every time
- **Rule-based** — you can say exactly when to do what
- **Frequent** — daily or weekly, not twice a year
- **Low-stakes if it hiccups** — a report that runs late, not a message to a patient

If a task needs judgement every time, automating it just moves the judgement somewhere you cannot see it.$md$),
('aa000000-0000-0000-0000-000000000008',2,'Map it before you build it', $md$Every automation is four things. Write them on one page before touching a tool:

1. **Trigger** — what starts it (a time, a new row, a form submitted)
2. **Steps** — what happens, in order
3. **Output** — what exists at the end, and who sees it
4. **Failure** — what happens when it breaks, and **who finds out**

That fourth one is the one people skip. An automation that fails silently is worse than no automation, because everyone assumes it ran.$md$),
('aa000000-0000-0000-0000-000000000008',3,'Start embarrassingly small', $md$Your first automation should save about ten minutes a week and be impossible to get badly wrong. A weekly summary email. A form that fills a tracker. A checklist that resets each morning.

Ship the small one, watch it run for a fortnight, then build the next. People who start with the ambitious one usually ship nothing.$md$);

-- AI 9 · Build with Claude Code -----------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000009',1,'What "building a tool" actually means', $md$You do not need to be a programmer. With Claude Code you describe what you want in plain English and it writes the code — you steer, test and decide when it is right.

Realistic first tools:

- A **daily checklist** page the team ticks off, that resets each morning
- A **report generator** — paste in the weekly numbers, get a formatted summary
- A **tracker** for recalls or follow-ups with a running total
- A **calculator** for a fee or a quote$md$),
('aa000000-0000-0000-0000-000000000009',2,'How to work with it', $md$1. **Describe the outcome, not the code.** "A page where I tick off six tasks and it remembers what I ticked today."
2. **One change at a time.** Get it working, then ask for the next thing. Ten changes at once means you cannot tell what broke.
3. **Run it and actually use it.** Every time. Do not accept "that should work".
4. **Say what is wrong in plain English.** "The tick boxes reset when I refresh" is a perfect bug report.
5. **Ask it to explain anything you do not understand.** You are responsible for what you ship.$md$),
('aa000000-0000-0000-0000-000000000009',3,'Your practical for AI Builder', $md$**Build one small tool or automation that solves a real problem** for the clinic you support — something you or your team will actually use.

Submit a link to it, or to a short screen recording of it running. Your manager verifies it works.

Small and used beats clever and abandoned. The badge says "this person shipped something that works", and clients read it that way.$md$);

-- AI 10 · Deploy & handover ---------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000010',1,'Getting it running for real', $md$A tool on your laptop helps one person. The last mile is making it available to the team and making it survive you.

- Put it where the team already looks — the portal, a shared drive, a bookmarked link.
- Check it on a **phone**. Most of the team will open it on a phone.
- Give it a name that says what it does.$md$),
('aa000000-0000-0000-0000-000000000010',2,'Document it in five lines', $md$Nobody reads a manual for a small tool. Write five lines and put them at the top:

1. What it does
2. Who it is for
3. How to use it (one sentence)
4. What to do if it breaks — **and who to tell**
5. Who built it and when

That is the difference between a tool the team adopts and one that dies the week you take leave.$md$),
('aa000000-0000-0000-0000-000000000010',3,'Handing it over', $md$Walk one other person through it while they drive and you watch. Every question they ask is a line missing from your five.

Then hand over the ownership properly: who maintains it, and what happens to it if nobody does. A tool with no owner is a liability with a nice interface.$md$);

-- AI 11 · Guardrails ----------------------------------------------------------
insert into module_sections (module_id, ord, heading, body) values
('aa000000-0000-0000-0000-000000000011',1,'The hard lines', $md$These are not preferences. Breaking one is a serious incident:

- **No patient-identifying information into a public AI tool.** Ever.
- **Nothing reaches a patient unread by a human.** No auto-send, no auto-reply, no exceptions.
- **No clinical judgement**, from you or from AI. Escalate.
- **No fee, rebate or item number quoted from AI.** Check the clinic's own source.
- **Nothing financial acts on its own** — a person approves before money moves.$md$),
('aa000000-0000-0000-0000-000000000011',2,'Why the lines sit there', $md$Each one exists because of how the failure looks from the outside.

A wrong fee is not "a small error" — it is a clinic that quoted a patient wrong. An auto-sent message is not "a fast reply" — it is a clinic that let a machine talk to its patients. The clinic wears every one of these, and it is the clinic's reputation, not the tool's.

We move fast on drafts, structure, summaries and tools. We do not move fast on anything a patient reads or pays.$md$),
('aa000000-0000-0000-0000-000000000011',3,'If something goes wrong', $md$Say so immediately. Not at the end of the shift — immediately.

Almost every AI mistake is cheap to fix in the first ten minutes and expensive after a day. Nobody at Ericka is in trouble for reporting one quickly. The only unrecoverable version is the one that was hidden.$md$);
