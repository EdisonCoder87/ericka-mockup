// Runs the Ericka SQL migrations against Supabase via the Management API.
// Usage:  SUPABASE_PAT=sbp_xxx node run_migrations.js
const fs = require('fs');

const REF = 'bewfcqcmleuznaaptqiq';               // ericka-portal project ref
const PAT = process.env.SUPABASE_PAT;
const FILES = [
  'migration_01_sites.sql',
  'migration_02_structure.sql',
  'migration_03_content.sql',
  'migration_04_quizzes.sql',
  'migration_05_productivity.sql',
  'migration_06_scorecard.sql',
];

(async () => {
  if (!PAT) { console.error('Missing SUPABASE_PAT env var'); process.exit(1); }
  for (const f of FILES) {
    if (!fs.existsSync(f)) { console.log(`SKIP ${f} (not found)`); continue; }
    const query = fs.readFileSync(f, 'utf8');
    process.stdout.write(`\n=== ${f} ... `);
    const res = await fetch(`https://api.supabase.com/v1/projects/${REF}/database/query`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${PAT}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ query }),
    });
    const text = await res.text();
    if (res.ok) {
      console.log(`OK (${res.status})`);
    } else {
      console.log(`FAILED (${res.status})`);
      console.log(text.slice(0, 1500));
      process.exit(1);
    }
  }
  console.log('\n✅ All migrations applied.');
})();
