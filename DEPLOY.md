# Deploy — Ericka Team Portal → portal.ericka.com.au

**Architecture:** static site (HTML/CSS/JS) that talks **directly to Supabase from the
browser** using the anon public key. No server, so **no Render needed**. Hosted **free on
GitHub Pages**.

**Cost to run live: $0/month** (GitHub Pages free + Supabase free tier + GitHub free).

| Layer | Host | Cost |
|---|---|---|
| App (pages) | GitHub Pages — free, never sleeps, free SSL | $0 |
| Data | Supabase free tier | $0 |
| Code | GitHub (`EdisonCoder87/ericka-mockup`) | $0 |

---

## Status
- [x] **Step 1 — CNAME file** added (`CNAME` = `portal.ericka.com.au`) and pushed to `main`.
- [ ] **Step 2 — DNS record** at VentraIP (below).
- [ ] **Step 3 — Custom domain** turned on in GitHub → Settings → Pages + Enforce HTTPS.

---

## Step 2 — Add the DNS record at VentraIP
VentraIP → `ericka.com.au` → **Manage DNS** (a.k.a. "DNS Zone Editor") → add:

| Field | Value |
|---|---|
| Type | `CNAME` |
| Host / Name | `portal` (just the word, not the full domain) |
| Points to / Value / Target | `edisoncoder87.github.io` (no `https://`, no trailing slash) |
| TTL | default (or `3600`) |

This touches **only** the `portal` subdomain — it does NOT affect the main `ericka.com.au`
website or Zoho email.

## Step 3 — Turn it on in GitHub
`github.com/EdisonCoder87/ericka-mockup` → **Settings → Pages**
1. **Custom domain** should already show `portal.ericka.com.au` (read from the CNAME file). If
   not, type it and **Save**.
2. Wait for the green DNS-check tick (15 min–few hours).
3. Tick **☑ Enforce HTTPS** — GitHub issues the free SSL cert automatically.

## Then
Open **https://portal.ericka.com.au** — should load with the padlock. Test with admin PIN
`1988`.

**Temporary quirk:** once the CNAME file is pushed, the old
`edisoncoder87.github.io/ericka-mockup/` URL may error until Steps 2–3 are complete. Expected.

---

## Before sharing outside SIA Medical (security gate)
Login is **PIN-only** and there is **no RLS** yet — fine for the friendly SIA Medical crew, and
there's no patient data here. **Before any arm's-length paying client gets access:**
1. Turn on **Supabase Auth + Row-Level Security** (schema is already RLS-ready).
2. That's also the trigger to move to **Supabase Pro ($25/mo)** for daily backups + no pausing.

## Deferred feature (separate green-light)
**AI phone-call practice** (`AI_CALLS_DESIGN.md`) needs a small server (~$7/mo, e.g. Render) +
per-call API spend (Sonnet + TTS + STT). Not part of this deploy.
