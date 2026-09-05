-- ============================================================================
-- Ericka Portal — migration 12: quizzes for the AI certification track
--   Same gate as every other module: >= 75% to complete. The two practical
--   modules (AI 6 and AI 9) additionally need manager verification.
--   ⚠️ Do NOT re-run migration_04 after this: it does `delete from
--      quiz_questions` and would wipe these.
-- Re-runnable: clears only the AI modules' questions first.
-- ============================================================================

delete from quiz_questions where module_id in (
  select id from training_modules where category = 'ai');

-- AI 1 · AI at Ericka ---------------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000001',1,$q$A patient is overdue for a review and you want AI to draft the SMS. What do you paste in?$q$,$j$["Their full name and address so it sounds personal","A de-identified description of the situation","Their Medicare number for accuracy","Their file from the practice system"]$j$::jsonb,1,$e$Describe the situation without identifying anyone, then add the real details in the practice system afterwards.$e$),
('aa000000-0000-0000-0000-000000000001',2,$q$AI tells you a Medicare rebate is $91.50. What do you do?$q$,$j$["Quote it to the patient","Check the clinic's own source before quoting anything","Round it to $90","Ask AI again to confirm"]$j$::jsonb,1,$e$Never quote a fee, rebate or item number from AI. Asking it twice just gets you the same invention twice.$e$),
('aa000000-0000-0000-0000-000000000001',3,$q$What does "human-led, AI-harnessed" mean in practice?$q$,$j$["AI decides, you check afterwards","AI drafts, you decide","AI handles patients so you handle admin","You only use AI when you are busy"]$j$::jsonb,1,$e$AI drafts and speeds you up. The judgement and the responsibility stay with you.$e$);

-- AI 2 · Prompting ------------------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000002',1,$q$Which prompt will get the better result?$q$,$j$["Write a recall message","Write an SMS for an Australian dental clinic to a patient overdue for a check-up. Warm, under 160 characters, ends with a call to action","Write something for recalls please","Recall SMS, make it good"]$j$::jsonb,1,$e$Role, task, constraints and format. Vague in, vague out.$e$),
('aa000000-0000-0000-0000-000000000002',2,$q$The first draft is too formal. What is the fastest fix?$q$,$j$["Retype the whole prompt","Tell it what is wrong: too formal, make it sound like a person","Give up and write it yourself","Accept it — it is close enough"]$j$::jsonb,1,$e$Steer it with a short correction. You do not need to start again.$e$),
('aa000000-0000-0000-0000-000000000002',3,$q$What is the single best way to stop AI inventing your clinic's rules?$q$,$j$["Ask it to be accurate","Paste in the real rules and tell it to use only those","Use shorter prompts","Ask the same question twice"]$j$::jsonb,1,$e$When the facts come from you, it cannot make them up.$e$);

-- AI 3 · Patient comms --------------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000003',1,$q$An AI-drafted arrears message is ready to go. What happens next?$q$,$j$["Send it — it was drafted from an approved template","You read it before it reaches the patient","Schedule it to auto-send overnight","Send it if it is under 160 characters"]$j$::jsonb,1,$e$Nothing reaches a patient unread by a human. No exceptions.$e$),
('aa000000-0000-0000-0000-000000000003',2,$q$The draft says "Don't lose your spot — book today!". What is wrong with it?$q$,$j$["Nothing, it creates urgency","It uses pressure tactics we do not use","It is too short","It should mention the fee"]$j$::jsonb,1,$e$Warm and clear, never pressure. It has to survive being read back to the patient's face.$e$),
('aa000000-0000-0000-0000-000000000003',3,$q$The draft states a fee you have not verified. What do you do?$q$,$j$["Leave it in, AI is usually right","Take the amount out or verify it against the clinic's source","Add 'approximately' in front of it","Ask the patient to confirm the fee"]$j$::jsonb,1,$e$Never state a fee you have not verified. A patient's money must always be accurate.$e$);

-- AI 4 · Summarise & extract --------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000004',1,$q$What turns "summarise this" into something useful?$q$,$j$["Asking for it to be shorter","Naming the output shape — decisions, actions with owners, open questions","Pasting more of the document","Asking twice and comparing"]$j$::jsonb,1,$e$Name the shape you want and you get a to-do list instead of a shorter blob.$e$),
('aa000000-0000-0000-0000-000000000004',2,$q$AI extracts figures from a report and gives you a total. What should you do before it goes to a client?$q$,$j$["Nothing, extraction is reliable","Verify the numbers yourself","Ask it to double-check","Round the total"]$j$::jsonb,1,$e$It is good at extracting and unreliable at arithmetic. A wrong number in a client report costs more trust than the report earns.$e$),
('aa000000-0000-0000-0000-000000000004',3,$q$What is the end-of-shift habit from this module?$q$,$j$["Email everyone your notes","Ask AI for a handover summary: what happened, what is outstanding, what is next","Clock out promptly","File the day's paperwork"]$j$::jsonb,1,$e$Two minutes of work and the next shift starts informed.$e$);

-- AI 5 · Problem-solving ------------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000005',1,$q$Which description will get you a useful answer?$q$,$j$["Pracsoft is broken","Pracsoft won't save a new booking. It shows 'Error 4021' when I click Save. I have restarted it once","It's not working again","The computer has an error"]$j$::jsonb,1,$e$What you did, what you expected, the exact error, what you tried. Same as briefing a good colleague.$e$),
('aa000000-0000-0000-0000-000000000005',2,$q$AI explains a Medicare rule confidently. Can you act on it?$q$,$j$["Yes, if it sounds right","Only after checking the clinic's own source","Yes, if you ask it to confirm","Only if it is about billing"]$j$::jsonb,1,$e$Use AI to understand and to know what to ask. Use the clinic's sources for the answer that leaves your mouth.$e$),
('aa000000-0000-0000-0000-000000000005',3,$q$You have tried the same fix twice and it still fails. What now?$q$,$j$["Try a third approach","Escalate with what you tried and what the error says","Work around it quietly","Leave it for the next shift"]$j$::jsonb,1,$e$Two failed attempts is the signal to escalate. You have still saved them the diagnosis.$e$);

-- AI 6 · Write a process ------------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000006',1,$q$After AI drafts your SOP, what is the most important next step?$q$,$j$["Format it nicely","Follow it yourself once, exactly as written","Send it to the team","Add a cover page"]$j$::jsonb,1,$e$Every place you had to stop and think is a missing step.$e$),
('aa000000-0000-0000-0000-000000000006',2,$q$AI smooths over a step you skipped in your messy notes. Why does that matter?$q$,$j$["It makes the document longer","The skipped bits are exactly what a new person needs","It changes the formatting","It does not matter"]$j$::jsonb,1,$e$You know the gaps by heart. Someone new does not.$e$),
('aa000000-0000-0000-0000-000000000006',3,$q$What earns the AI Assisted badge?$q$,$j$["Passing all six quizzes","Passing the quizzes and having a real SOP verified by your manager","Completing the first module","Using AI every day for a month"]$j$::jsonb,1,$e$A badge a quiz alone can mint is worth nothing to a client. The practical is the point.$e$);

-- AI 7 · Spreadsheets & data --------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000007',1,$q$What should you ask for alongside a formula?$q$,$j$["A shorter version","A one-line explanation of how it works","The same formula for Excel","Nothing else"]$j$::jsonb,1,$e$The explanation is how you stop being dependent — you start recognising the patterns.$e$),
('aa000000-0000-0000-0000-000000000007',2,$q$Before cleaning a messy export, what do you always do?$q$,$j$["Delete the blank rows","Keep the original and clean into a copy","Sort it alphabetically","Email it to your manager"]$j$::jsonb,1,$e$Always keep the original. Clean into a copy.$e$),
('aa000000-0000-0000-0000-000000000007',3,$q$What makes a tracker worth building?$q$,$j$["It looks professional","You log as you go and the summary calculates itself","It has lots of columns","It is colour-coded"]$j$::jsonb,1,$e$No end-of-week counting and no arguing about whose number is right.$e$);

-- AI 8 · Automations 101 ------------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000008',1,$q$Which task is the best automation candidate?$q$,$j$["Deciding which patients need urgent care","A weekly summary report built from a tracker","Answering a distressed patient","Approving a refund"]$j$::jsonb,1,$e$Repeatable, rule-based, frequent, and low-stakes if it hiccups.$e$),
('aa000000-0000-0000-0000-000000000008',2,$q$Which part of the map do people most often skip?$q$,$j$["The trigger","The steps","What happens when it fails, and who finds out","The output"]$j$::jsonb,2,$e$An automation that fails silently is worse than none — everyone assumes it ran.$e$),
('aa000000-0000-0000-0000-000000000008',3,$q$How big should your first automation be?$q$,$j$["Big enough to impress the client","Small — about ten minutes a week saved, hard to get wrong","Whatever takes the longest today","It should replace a whole role"]$j$::jsonb,1,$e$Ship the small one, watch it run, then build the next. People who start ambitious usually ship nothing.$e$);

-- AI 9 · Build with Claude Code -----------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000009',1,$q$How should you describe what you want built?$q$,$j$["In technical terms so it understands","The outcome in plain English","With a list of programming languages","As briefly as possible"]$j$::jsonb,1,$e$Describe the outcome, not the code. Steering is your job; writing it is the tool's.$e$),
('aa000000-0000-0000-0000-000000000009',2,$q$Why ask for one change at a time?$q$,$j$["It is faster","When something breaks you can tell what caused it","It costs less","It produces shorter code"]$j$::jsonb,1,$e$Ten changes at once means you cannot tell what broke.$e$),
('aa000000-0000-0000-0000-000000000009',3,$q$What does the AI Builder badge tell a client?$q$,$j$["This person has watched AI training","This person shipped something that works","This person can write code from scratch","This person passed a test"]$j$::jsonb,1,$e$Small and used beats clever and abandoned. A manager verifies it runs.$e$);

-- AI 10 · Deploy & handover ---------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000010',1,$q$What must you check before handing a tool to the team?$q$,$j$["That it has a logo","That it works on a phone","That it is in the right font","That it prints"]$j$::jsonb,1,$e$Most of the team will open it on a phone.$e$),
('aa000000-0000-0000-0000-000000000010',2,$q$Which line do people most often leave out of the five-line doc?$q$,$j$["What it does","What to do if it breaks, and who to tell","Who it is for","How to use it"]$j$::jsonb,1,$e$Without it, the tool dies the week you take leave.$e$),
('aa000000-0000-0000-0000-000000000010',3,$q$What is the best way to hand a tool over?$q$,$j$["Send a link and instructions","Walk someone through it while they drive and you watch","Record a long video","Write a full manual"]$j$::jsonb,1,$e$Every question they ask is a line missing from your documentation.$e$);

-- AI 11 · Guardrails ----------------------------------------------------------
insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('aa000000-0000-0000-0000-000000000011',1,$q$Which of these is a hard line, not a preference?$q$,$j$["Using Australian spelling","Nothing reaches a patient unread by a human","Keeping drafts short","Using the same tool every time"]$j$::jsonb,1,$e$No auto-send, no auto-reply, no exceptions.$e$),
('aa000000-0000-0000-0000-000000000011',2,$q$Why do these lines exist?$q$,$j$["Compliance paperwork","Because the clinic wears every failure, and it is their reputation","To slow the work down","Because AI is unreliable at everything"]$j$::jsonb,1,$e$We move fast on drafts, structure and tools. Not on anything a patient reads or pays.$e$),
('aa000000-0000-0000-0000-000000000011',3,$q$You realise an AI mistake went out an hour ago. What do you do?$q$,$j$["Fix it quietly","Report it immediately","Mention it at the end of the shift","Wait to see if anyone notices"]$j$::jsonb,1,$e$Cheap to fix in ten minutes, expensive after a day. Nobody is in trouble for reporting one quickly.$e$);
