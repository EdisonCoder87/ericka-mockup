# AI Phone-Call Practice — design note (NOT built yet)

This is the "next stage" idea: a VA practises a realistic patient call and gets scored — the same
engine SIA Dental's training tool uses, retargeted to medical reception.

## Why it's not in the bones
The rest of the portal is a static site + Supabase (no server, ~$0 to run). AI calls need:
- A **server** (Flask/Node) to hold API keys and orchestrate the turn-by-turn conversation.
- **Speech-to-text** (patient hears the VA / VA speaks) — e.g. Whisper/Groq.
- **Text-to-speech** for the AI "patient" voice — e.g. OpenAI TTS.
- **An LLM** (Claude Sonnet) to play the patient + score the VA against a rubric.
- **Real per-call cost** — roughly $0.10–0.25 per practice call. That's a spend decision.

So it's a supervised build, not an overnight one.

## Recommended shape (when green-lit)
1. **Reuse the SIA Dental training engine** (`training/app.py` voice pipeline + Sonnet/Haiku scoring)
   — it's ~90% domain-agnostic. Fork it as a small `ericka-voice` service on Render.
2. **Scenarios as data**, per module — e.g. Triage module → "caller with chest pain", Billing module →
   "patient angry about a gap fee (JADE)". Store scenarios in Supabase alongside the module.
3. **Scoring rubric** grounded in this manual: did they triage correctly? verify identity? quote the
   right fee? escalate appropriately? Score → store in `training_progress` next to the quiz score.
4. **Gate**: a module could require *both* the quiz and one passed call before it's "complete".
5. **Cost control**: rate-limit calls per VA/day; show a running cost estimate; keep it after-hours-style
   opt-in first (mirrors the Ovie trial approach).

## First step to unblock
Edison supplies 2–3 real Footscray call situations + how a great receptionist handles each — that
becomes the AI scoring ground truth (same first-unblock as the dental tool).
