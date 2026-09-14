-- ============================================================================
-- Ericka Portal — migration 20: mark the demo dental account's AI practicals as
--   verified, so both AI tiers read "earned" and the AI CERTIFIED banner shows.
--   (The two requires_evidence AI modules need a verified_at to count.)
-- Re-runnable.
-- ============================================================================

update training_progress
set evidence_url = coalesce(evidence_url, 'https://drive.google.com/demo-ericka-practical'),
    verified_by  = 'a0000000-0000-0000-0000-000000000001',
    verified_at  = coalesce(verified_at, now())
where user_id = 'adde0000-0000-0000-0000-0000000000de'
  and module_id in ('aa000000-0000-0000-0000-000000000006',
                    'aa000000-0000-0000-0000-000000000009');
