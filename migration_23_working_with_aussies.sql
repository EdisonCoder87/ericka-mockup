-- ============================================================================
-- Ericka Portal — migration 23: onboarding module "Working with Australian Businesses"
--   One shared onboarding module (vertical = 'all') that every remote member
--   takes, medical and dental. Sits at onboarding position 2 (after the
--   welcome / meet-the-practice module), so the other onboarding modules
--   shift down one place the FIRST time this runs.
--   Core lesson: in Australia a "yes" is a promise. Ask the questions first.
--   Sources: AU-PH offshoring guides (Access Offshoring "The yes trap",
--   MyBPO 2026 management guide, Team Up Now / Julius Schoenfeld on the
--   different ways of saying yes, and his "balance the owner's energy" rule).
-- Re-runnable: clears only its own sections + quiz, never shifts twice.
-- ============================================================================

do $$
begin
  if not exists (select 1 from training_modules
                 where id = 'a5000000-0000-0000-0000-000000000001') then
    update training_modules set ord = ord + 1
     where category = 'onboarding' and vertical in ('medical','dental') and ord >= 2;
    insert into training_modules (id, vertical, category, ord, title, icon, capability_label, summary)
    values ('a5000000-0000-0000-0000-000000000001', 'all', 'onboarding', 2,
            'Working with Australian Businesses', '🌏', 'Australian Workplace Ready',
            'In Australia a "yes" is a promise. Learn the 10 things Australian owners expect, and the questions to ask before you say yes.');
  end if;
end $$;

delete from quiz_questions  where module_id = 'a5000000-0000-0000-0000-000000000001';
delete from module_sections where module_id = 'a5000000-0000-0000-0000-000000000001';

insert into module_sections (module_id, ord, heading, body) values
('a5000000-0000-0000-0000-000000000001', 1, 'Why this module matters', $b$Most Filipino team members are hardworking, kind and respectful. Australian clinic owners love that. But there is one habit that causes more problems than any skill gap: **saying "yes" when you are not sure, and not asking questions.**

In the Philippines, saying yes keeps harmony. It shows respect, and asking too many questions can feel like you are troubling your boss or showing you are not capable (hiya).

In Australia it is the **opposite.** An Australian owner hears "yes" as: *I understand, I can do it, and it will be done.* When it is not done, or done wrong, they do not think "she was being polite". They think "I can't rely on her".

The good news: this is a habit, not a talent. You can learn it in a week. The 10 things below are what Australian owners expect, with the exact words to use.$b$),

('a5000000-0000-0000-0000-000000000001', 2, '1. In Australia, "yes" is a promise', $b$A Filipino "yes" can mean *I heard you*, *I'll try*, *I'm not sure*, or even *I don't understand*. An Australian "yes" only means one thing: **I will deliver this.**

So before you say yes, make sure you can answer three things:
- **What** exactly am I delivering?
- **By when?**
- **What could stop me?**

If you can't answer all three, don't say yes yet. Ask first.

**Instead of:** "Yes, noted."
**Say:** "Yes, I'll have the recall list cleaned up by Friday 3pm your time. I'll message you if anything gets in the way."

"I'll try my best" is not an answer in Australia. It sounds like a maybe. If you can do it, say yes with a time. If you can't, say what you *can* do.$b$),

('a5000000-0000-0000-0000-000000000001', 3, '2. Asking questions shows you are good, not weak', $b$Australian owners **respect** the person who asks good questions before starting. They lose respect for the person who says nothing, guesses, and gets it wrong.

A wrong guess costs the owner twice: once to do it wrong, once to fix it. A 30 second question costs nothing.

In a clinic this is even more important. Our golden rule from Welcome to Ericka still applies: **a patient's health and their money must always be right. Never guess on either.**

If you are unsure, ask. Every time. Nobody at Ericka will ever be in trouble for asking a question. You can be in trouble for guessing.$b$),

('a5000000-0000-0000-0000-000000000001', 4, '3. The 4 questions to ask before you start any task', $b$When you get a new task, and anything about it is not clear, ask these before you begin:

1. **"When do you need this by?"** Is there a deadline, or is it whenever I can?
2. **"What does good look like?"** What should the finished result look like? Can you show me an example?
3. **"How important is this compared to my other work?"** Should I stop what I'm doing, or do it after?
4. **"Who do I go to if I get stuck?"**

You don't need all four every time. A simple task may need only one. But **deadline** and **what good looks like** are the two that prevent most mistakes.

**Example message to the practice manager:**
"Hi Rad, happy to do this. Two quick questions so I get it right: when do you need it by, and do you have an example of how you'd like it set out?"$b$),

('a5000000-0000-0000-0000-000000000001', 5, '4. Play it back in your own words', $b$The fastest way to prove you understood is to **repeat the task back** in your own words. This catches mistakes before they happen, and owners love it.

**Template:**
"Just to confirm: you'd like me to [task], by [time], and it's done when [result]. I'll let you know when it's finished."

**Example:**
"Just to confirm: you'd like me to call the 40 patients overdue for a recall, book as many as I can, and leave a note in each file. I'll send you the numbers by 4pm Thursday."

If you got something wrong, the owner will fix it now, in 10 seconds, instead of next week. That is not embarrassing. That is professional.$b$),

('a5000000-0000-0000-0000-000000000001', 6, '5. Bad news early is good news', $b$In Australia, the worst thing is not a problem. **The worst thing is a surprise.**

If you are going to miss a deadline, tell the owner **as soon as you know**, not at the deadline. An owner told on Tuesday can plan around it. An owner told on Friday afternoon cannot.

**Flag it like this:**
"Hi Nikki, heads up: the billing report will be late. Two of the HICAPS claims don't match and I need the practice manager to check them. I can have the rest done today and the full report by Monday 10am. Is that okay?"

Notice the shape: **what happened, why, what I can do, by when.** That is a message an Australian owner trusts.

Hiding a problem, or saying everything is fine when it isn't, is the fastest way to lose a client's trust. Raising it early is the fastest way to earn it.$b$),

('a5000000-0000-0000-0000-000000000001', 7, '6. It is okay to say "no" (the right way)', $b$Australians would much rather hear an honest "I can't do that by Friday" than a "yes" that turns into a missed deadline.

You don't need to say a hard "no". **Offer the choice instead:**
- "I can do the recall calls or the reports by Friday, but not both. Which is more important?"
- "I can't finish all of it today. I can do the urgent part now and the rest by tomorrow 12pm. Does that work?"
- "I haven't done this before. Can you show me once, then I'll do the rest?"

This is not rude and it is not disrespectful. To an Australian owner it shows that you are honest and that you manage your own workload.$b$),

('a5000000-0000-0000-0000-000000000001', 8, '7. Australians are direct. It is not anger.', $b$Australians say things plainly. "This isn't right, can you redo it?" is a normal sentence at work. It is **about the work, not about you**, and they will have forgotten it by lunch.

Don't take it personally, don't go quiet, and don't over-apologise. Reply simply:
"Thanks for letting me know. I'll fix the dates and send it back by 2pm."

**When the owner is stressed, be the calm one.** Clinic owners are busy and often under pressure. If they message in a rush, don't rush back or panic with them. Be steady, clear and short. Julius Schoenfeld (Team Up Now) puts it well: *balance the owner's energy, don't mirror it.* The VA who stays calm when the owner is stressed becomes the person they can't do without.$b$),

('a5000000-0000-0000-0000-000000000001', 9, '8. First names, and your ideas are wanted', $b$Australian workplaces are "flat". Everyone, including the owner and the doctors, is usually called by their **first name.** No "Sir" or "Ma'am" needed. Using first names is not disrespectful here, it is normal and friendly. (With patients, follow the clinic's script.)

Australian owners also **want your ideas.** If you see a faster way to do something, or a mistake in a process, say so:
"I noticed we call the same patients twice when they're on both lists. Would it help if I merged them first?"

You are not overstepping. You are doing what a good team member does. Waiting quietly to be told is seen as not caring, even when that is not true.$b$),

('a5000000-0000-0000-0000-000000000001', 10, '9. Own it and close the loop', $b$Australian owners expect you to **finish the job end to end** and tell them it's done. They should never have to chase you.

- When a task is done, send a short message: "Done. 32 of 40 recall patients booked, 8 left voicemails, notes are in each file."
- If you're waiting on someone else, say who and what: "Waiting on Dr Tan to approve the script, I'll follow up at 2pm."
- If something is stuck, don't leave it sitting. Follow up, or escalate (see How We Communicate & Escalate).

**Under promise, over deliver.** A realistic deadline that you beat is worth more than an ambitious one you miss. Australians don't like overselling or big talk (they call it "tall poppy"). Quiet, reliable results are what earn respect.$b$),

('a5000000-0000-0000-0000-000000000001', 11, '10. Time, deadlines and Aussie English', $b$**Time zones.** Victoria and NSW change clocks for daylight saving; the Philippines doesn't.
- **First Sunday in October to first Sunday in April:** Melbourne is **3 hours ahead** of Manila.
- **April to October:** Melbourne is **2 hours ahead.**
- Brisbane (Queensland) has no daylight saving: always **2 hours ahead.**
Always write deadlines in the **client's time**: "Friday 3pm Melbourne time".

**Deadlines are real.** "COB" means close of business, about 5pm their time. "EOD" means end of day. "ASAP" means today if possible. If no time is given, ask (see section 3). Being on time for your shift and meetings matters a lot; late without a message is noticed.

**Aussie English you will hear:**
- **No worries** = you're welcome / that's fine
- **How are you going?** = how are you? (answer "Good thanks, how are you?")
- **Arvo** = afternoon · **Reckon** = think · **Heaps** = a lot · **Keen** = interested
- **Cheers / Ta** = thanks · **Yeah nah** = no · **Nah yeah** = yes
- **Can you chase that up?** = please follow up on it
- Australians also joke and use sarcasm a lot. If you're not sure if they're joking, it's fine to smile and ask.$b$),

('a5000000-0000-0000-0000-000000000001', 12, 'Key Takeaways — The Australian way', $b$- "Yes" in Australia = **I understand, I can do it, here is when.** "I'll try" sounds like maybe.
- Before you start: ask **"When do you need it by?"** and **"What does good look like?"**
- Play it back: "Just to confirm, you'd like me to... by..."
- **Bad news early.** What happened, why, what I can do, by when.
- Can't do it all? **Offer the choice:** "I can do A or B by Friday. Which matters more?"
- Direct feedback is about the work, not you. Reply calmly, fix it, move on.
- When the owner is stressed, **be the calm one.**
- First names. Share your ideas. Close the loop with "Done" messages.
- Write every deadline in the **client's time zone.**
- Never guess on a patient's health or money. **Ask.**$b$);

insert into quiz_questions (module_id, ord, question, options, correct, explanation) values
('a5000000-0000-0000-0000-000000000001',1,$q$An Australian practice manager asks you to update the recall list. You're not sure what format she wants. What should you do?$q$,$j$["Say yes and do it the way you think is best","Say yes, then ask a colleague later","Say you're happy to do it and ask what good looks like or for an example","Wait until she follows up"]$j$::jsonb,2,$e$Ask before you start. "What does good look like?" prevents doing it twice.$e$),
('a5000000-0000-0000-0000-000000000001',2,$q$To an Australian owner, what does your "yes" mean?$q$,$j$["I heard you","I'll try my best","I understand, I can do it, and it will be done by a time","Maybe, depending on my workload"]$j$::jsonb,2,$e$In Australia a yes is a promise: understanding, ability and a time.$e$),
('a5000000-0000-0000-0000-000000000001',3,$q$It's Tuesday and you realise you will miss Friday's deadline. When should you tell the owner?$q$,$j$["Now, with why and a new time","Friday, at the deadline","Only if they ask","Never, just work overtime and hope"]$j$::jsonb,0,$e$Bad news early is good news. Tell them as soon as you know: what happened, why, what you can do, by when.$e$),
('a5000000-0000-0000-0000-000000000001',4,$q$You're asked to do two tasks by Friday but only have time for one. What's the best reply?$q$,$j$["Say yes to both and try","Say no","\"I can do A or B by Friday, but not both. Which matters more?\"","Do the easier one without telling anyone"]$j$::jsonb,2,$e$Offering the choice is honest and shows you manage your own workload.$e$),
('a5000000-0000-0000-0000-000000000001',5,$q$The owner messages: "This isn't right, can you redo it?" What does this usually mean?$q$,$j$["They are angry with you personally","It's normal direct feedback about the work","You are about to lose your job","You should apologise many times"]$j$::jsonb,1,$e$Australians are direct. It's about the work. Reply calmly, fix it, move on.$e$),
('a5000000-0000-0000-0000-000000000001',6,$q$The clinic owner is stressed and sending rushed messages. What should you do?$q$,$j$["Match their energy and reply fast and urgent","Stay calm, clear and short","Ignore them until they calm down","Tell them to relax"]$j$::jsonb,1,$e$Balance the owner's energy, don't mirror it. The calm VA becomes the one they rely on.$e$),
('a5000000-0000-0000-0000-000000000001',7,$q$It's November. A Melbourne client wants a report by 3pm Melbourne time. What time is that in Manila?$q$,$j$["3pm","1pm","12pm","6pm"]$j$::jsonb,2,$e$From October to April, Melbourne is on daylight saving and 3 hours ahead, so 3pm Melbourne = 12pm Manila.$e$),
('a5000000-0000-0000-0000-000000000001',8,$q$You finish a task the owner gave you. What should you do?$q$,$j$["Nothing, they'll see it","Wait for them to ask","Send a short \"Done\" message with the result","Start a new task without saying anything"]$j$::jsonb,2,$e$Close the loop. Owners should never have to chase you.$e$);
