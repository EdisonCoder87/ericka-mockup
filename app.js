/* ============================================================================
   Ericka Portal — shared front-end logic (login, session, data helpers)
   Talks directly to Supabase via the anon key (window.sb from config.js).
   Isolation for the bones is enforced HERE: every client-scoped query filters
   by the session's client_id. pay_rate is never selected by a client query.
   ============================================================================ */
(function () {
  const SESSION_KEY = "ericka_session";

  /* ---- session ---------------------------------------------------------- */
  function session() {
    try { return JSON.parse(localStorage.getItem(SESSION_KEY)); }
    catch (e) { return null; }
  }
  function setSession(u) { localStorage.setItem(SESSION_KEY, JSON.stringify(u)); }
  function logout() { localStorage.removeItem(SESSION_KEY); location.href = "01_welcome.html"; }

  // Home page for each role
  function homeFor(role) {
    if (role === "admin")        return "02_home.html";
    if (role === "manager")      return "10_team.html";   // Ericka Manager (Shane/Sharica)
    if (role === "team_lead")    return "10_team.html";
    if (role === "client_admin") return "08_client_home.html";
    return "05_va_home.html"; // va
  }

  /* ---- reference data --------------------------------------------------- */
  // Assignment options for a remote member: SIA Medical's 9 clinics, plus
  // "General VA" for members not tied to a clinic (e.g. an owner's own VA).
  const GENERAL_VA = "General VA";
  const CLINICS = ["Box Hill","Burwood","Croydon","Essendon","Footscray",
                   "Moonee Ponds","Montrose","Mulgrave","Berwick", GENERAL_VA];
  // Only medical client today; a clinic member belongs here. A General VA has
  // no client (client_id null) — they don't appear on any client's board.
  const SIA_MEDICAL_CLIENT_ID = "11111111-1111-1111-1111-111111111111";

  // A General VA (owner's own VA, no clinic) has NO KPI/performance dashboard.
  // Works for a session (role va + no client) or a board row (site tag).
  // Owners/managers/clients also lack a client_id, so the role check matters.
  function isGeneralVA(u) {
    if (!u) return false;
    if (u.site === GENERAL_VA) return true;
    return u.role === "va" && !u.client_id;
  }

  // Guard a page. Pass allowed roles, e.g. requireRole(['va']).
  function requireRole(roles) {
    const s = session();
    if (!s) { location.href = "01_welcome.html"; return null; }
    if (roles && roles.indexOf(s.role) === -1) { location.href = homeFor(s.role); return null; }
    return s;
  }

  /* ---- login ------------------------------------------------------------ */
  // The PIN check happens INSIDE the database (check_login, migration 15).
  // anon has no read access to users.pin or users.pay_rate, so the browser
  // can't pull PINs or pay economics even though the key is public.
  async function login(name, pin) {
    const { data, error } = await sb.rpc("check_login", {
      p_name: name, p_pin: String(pin)
    });
    if (error) throw error;
    const user = Array.isArray(data) ? data[0] : data;
    if (!user) return null;
    setSession(user);
    return user;
  }

  /* ---- dates ------------------------------------------------------------ */
  // Monday 00:00 of the week containing d (local).
  function mondayOf(d) {
    const x = new Date(d); x.setHours(0, 0, 0, 0);
    x.setDate(x.getDate() - ((x.getDay() + 6) % 7));   // 0 = Monday
    return x;
  }
  function weekStart() { return mondayOf(new Date()); }
  function hoursBetween(a, b) {
    return (new Date(b).getTime() - new Date(a).getTime()) / 3.6e6;
  }
  function weekLabelFor(d) {
    return "Week of " + mondayOf(d).toLocaleDateString("en-AU",
      { day: "numeric", month: "short", year: "numeric" });
  }

  // How far through the working week we are, 0..1. Used to judge whether a
  // VA is on pace — comparing 22 hrs against a 38-hr roster on a Tuesday is
  // meaningless without it.
  //
  // Note: the team works Manila time (AEST−2) and this reads the viewer's
  // clock. The tolerance band in paceFor() absorbs that gap — don't tighten
  // the band without handling the timezone properly first.
  function weekProgress(now) {
    now = now || new Date();
    const dow = (now.getDay() + 6) % 7;                 // 0 = Mon … 6 = Sun
    if (dow >= 5) return 1;                             // weekend: week is done
    const h = now.getHours() + now.getMinutes() / 60;
    const dayFrac = Math.min(1, Math.max(0, (h - 8) / 9));   // an 8am–5pm day
    return Math.min(1, (dow + dayFrac) / 5);
  }

  // Compare hours worked so far against the roster, pro-rated to today.
  // state: 'none' (no roster set) | 'behind' | 'on' | 'ahead'
  function paceFor(hours, rostered) {
    const r = Number(rostered || 0);
    if (!r) return { state: "none", pct: 0, expected: 0, delta: 0 };
    const expected = r * weekProgress();
    const tol = Math.max(1.5, expected * 0.1);
    const delta = hours - expected;
    return {
      state: delta > tol ? "ahead" : (delta < -tol ? "behind" : "on"),
      pct: Math.min(100, Math.round(hours / r * 100)),
      expected: expected,
      delta: delta
    };
  }

  /* ---- timesheets ------------------------------------------------------- */
  // The VA's currently-open shift (clocked in, not yet out), or null.
  async function openShift(vaId) {
    const { data, error } = await sb.from("timesheets")
      .select("*").eq("va_id", vaId).is("clock_out", null)
      .order("clock_in", { ascending: false }).limit(1).maybeSingle();
    if (error) throw error;
    return data;
  }
  async function clockIn(vaId, clientId) {
    const { data, error } = await sb.from("timesheets")
      .insert({ va_id: vaId, client_id: clientId }).select().single();
    if (error) throw error;
    return data;
  }
  async function clockOut(shiftId) {
    const { data, error } = await sb.from("timesheets")
      .update({ clock_out: new Date().toISOString() }).eq("id", shiftId)
      .select().single();
    if (error) throw error;
    return data;
  }
  // All shifts for a VA this week (most recent first).
  async function weekShifts(vaId) {
    return (await weekShiftsForMany([vaId])).get(vaId) || [];
  }
  // This week's shifts for a whole board, in one query.
  async function weekShiftsForMany(vaIds) {
    const out = new Map();
    vaIds.forEach(id => out.set(id, []));
    if (!vaIds.length) return out;
    const { data, error } = await sb.from("timesheets")
      .select("*").in("va_id", vaIds)
      .gte("clock_in", weekStart().toISOString())
      .order("clock_in", { ascending: false });
    if (error) throw error;
    (data || []).forEach(r => out.get(r.va_id).push(r));
    return out;
  }
  // Sum of COMPLETED hours this week for a VA. Billing runs off this — an
  // in-progress shift is not billable until it's closed.
  function sumHours(shifts) {
    return shifts.reduce((t, s) => t + (s.clock_out ? hoursBetween(s.clock_in, s.clock_out) : 0), 0);
  }
  // Nobody forgets to clock out for only a few minutes. Without a cap, a VA who
  // clocked in on Monday and never clocked out shows the client "on the phones
  // since 9:00am" two days later with 50 hours against a 38-hour roster.
  const MAX_OPEN_SHIFT_H = 12;    // hours of an open shift we're willing to count
  const STALE_OPEN_SHIFT_H = 16;  // beyond this, they are not "on now", just adrift

  // Hours one shift contributes: closed shifts as recorded, open shifts capped.
  function shiftHours(s, nowIso) {
    if (s.clock_out) return hoursBetween(s.clock_in, s.clock_out);
    return Math.min(MAX_OPEN_SHIFT_H, hoursBetween(s.clock_in, nowIso));
  }
  // Is this open shift plausibly someone actually on the phones right now?
  function isLiveShift(s) {
    return !!s && !s.clock_out
      && hoursBetween(s.clock_in, new Date().toISOString()) <= STALE_OPEN_SHIFT_H;
  }
  // Hours worked so far INCLUDING an open shift, counted up to now. This is
  // the honest "hours this week" figure to show against a roster.
  function sumHoursLive(shifts) {
    const now = new Date().toISOString();
    return shifts.reduce((t, s) => t + shiftHours(s, now), 0);
  }
  // Hours per day, index 0 = Monday … 6 = Sunday. Drives the coverage bars.
  function hoursByDay(shifts) {
    const out = [0, 0, 0, 0, 0, 0, 0];
    const now = new Date().toISOString();
    shifts.forEach(function (s) {
      const d = new Date(s.clock_in);
      out[(d.getDay() + 6) % 7] += shiftHours(s, now);
    });
    return out;
  }
  // The currently-open shift in a set — only if it's fresh enough to believe.
  function openIn(shifts) { return shifts.find(isLiveShift) || null; }
  // Most recent clock-out in a set, if any.
  function lastOutIn(shifts) {
    const done = shifts.filter(s => s.clock_out)
      .sort((a, b) => new Date(b.clock_out) - new Date(a.clock_out));
    return done.length ? done[0].clock_out : null;
  }

  /* ---- training --------------------------------------------------------- */
  // Display order of the three tracks. NOT alphabetical — 'ai' would sort
  // first, and the AI track is the last thing a member earns.
  const CAT_ORDER = { onboarding: 0, training: 1, ai: 2 };

  // Modules for a vertical, plus the shared ones (vertical 'all' — the AI
  // certification track, which every member takes regardless of vertical).
  async function modulesFor(vertical) {
    const { data, error } = await sb.from("training_modules")
      .select("*").in("vertical", [vertical, "all"]);
    if (error) throw error;
    return (data || []).sort((a, b) =>
      (CAT_ORDER[a.category] ?? 9) - (CAT_ORDER[b.category] ?? 9) || a.ord - b.ord);
  }
  // A single module plus its ordered content sections (for the viewer).
  async function moduleWithSections(moduleId) {
    const { data: mod, error: e1 } = await sb.from("training_modules")
      .select("*").eq("id", moduleId).maybeSingle();
    if (e1) throw e1;
    if (!mod) return null;
    const { data: secs, error: e2 } = await sb.from("module_sections")
      .select("ord,heading,body").eq("module_id", moduleId).order("ord");
    if (e2) throw e2;
    mod.sections = secs || [];
    return mod;
  }
  // Cheat sheet sections for a site (e.g. Footscray).
  async function cheatsheetForSite(site) {
    const { data, error } = await sb.from("cheatsheets")
      .select("ord,heading,body").eq("site", site).order("ord");
    if (error) throw error;
    return data || [];
  }
  // Does this site have a cheat sheet at all? (drives the sidebar link)
  async function siteHasCheatsheet(site) {
    if (!site) return false;
    const { count } = await sb.from("cheatsheets")
      .select("id", { count: "exact", head: true }).eq("site", site);
    return (count || 0) > 0;
  }
  // Reveal a hidden #nav-cheat sidebar link for a VA whose site has a sheet.
  async function revealCheatsheetNav(s) {
    const el = document.getElementById("nav-cheat");
    if (!el || !s || s.role !== "va") return;
    if (await siteHasCheatsheet(s.site)) {
      el.style.display = "";
      const label = el.querySelector(".cs-site");
      if (label) label.textContent = s.site + " Cheat Sheet";
    }
  }
  async function progressFor(userId) {
    const { data, error } = await sb.from("training_progress")
      .select("module_id").eq("user_id", userId);
    if (error) throw error;
    return (data || []).map(r => r.module_id);
  }
  // Full progress rows keyed by module_id — needed wherever the practical
  // evidence and its verification matter (the AI certification badges).
  async function progressRowsFor(userId) {
    return (await progressRowsForMany([userId])).get(userId) || new Map();
  }
  // Same, for a whole board in ONE query. Boards used to fire three queries
  // per member, which made a 12-person team a 36-round-trip page load.
  async function progressRowsForMany(userIds) {
    const out = new Map();
    userIds.forEach(id => out.set(id, new Map()));
    if (!userIds.length) return out;
    const { data, error } = await sb.from("training_progress")
      .select("user_id,module_id,score,evidence_url,verified_by,verified_at,completed_at")
      .in("user_id", userIds);
    if (error) throw error;
    (data || []).forEach(r => out.get(r.user_id).set(r.module_id, r));
    return out;
  }
  // Is this a plain web link we're willing to store and render as an anchor?
  // Anything else is shown as text — the value reaches a manager's browser and
  // the database has no column-level guard until RLS lands.
  function isSafeUrl(u) {
    return typeof u === "string" && /^https?:\/\/[^\s"'<>`]+$/i.test(u);
  }
  // A member submits the practical for a module that requires evidence.
  async function submitEvidence(userId, moduleId, url) {
    const link = String(url || "").trim();
    if (!isSafeUrl(link)) throw new Error("Paste a plain link starting with http:// or https://");
    const { error } = await sb.from("training_progress")
      .update({ evidence_url: link, verified_by: null, verified_at: null })
      .eq("user_id", userId).eq("module_id", moduleId);
    if (error) throw error;
  }
  // A manager verifies (or un-verifies) that practical.
  async function verifyEvidence(userId, moduleId, managerId, ok) {
    const { error } = await sb.from("training_progress")
      .update(ok
        ? { verified_by: managerId, verified_at: new Date().toISOString() }
        : { verified_by: null, verified_at: null })
      .eq("user_id", userId).eq("module_id", moduleId);
    if (error) throw error;
  }
  async function completeModule(userId, moduleId, score) {
    const row = { user_id: userId, module_id: moduleId };
    if (typeof score === "number") row.score = score;
    const { error } = await sb.from("training_progress").insert(row);
    // ignore duplicate-key (already complete — first pass sticks)
    if (error && error.code !== "23505") throw error;
  }
  // Quiz questions for a module (empty array = no quiz, use mark-complete).
  async function quizFor(moduleId) {
    const { data, error } = await sb.from("quiz_questions")
      .select("ord,question,options,correct,explanation")
      .eq("module_id", moduleId).order("ord");
    if (error) throw error;
    return data || [];
  }

  /* ---- productivity (team-lead entered) --------------------------------- */
  // Latest productivity row for a VA (null if none / table not present yet).
  async function productivityFor(userId) {
    const h = await productivityHistory(userId);
    return h.length ? h[0] : null;
  }
  // Every recorded period for a VA, newest first. Ordered by period_start —
  // period_label is free text and sorts alphabetically, which is wrong.
  async function productivityHistory(userId) {
    return (await productivityHistoryForMany([userId])).get(userId) || [];
  }
  // Every recorded period for a whole board, in one query.
  async function productivityHistoryForMany(userIds) {
    const out = new Map();
    userIds.forEach(id => out.set(id, []));
    if (!userIds.length) return out;
    try {
      const { data, error } = await sb.from("productivity")
        .select("*").in("user_id", userIds)
        .order("period_start", { ascending: false, nullsFirst: false })
        .order("updated_at", { ascending: false });
      if (error) throw error;
      (data || []).forEach(r => out.get(r.user_id).push(r));
    } catch (e) {}                 // table may not exist until migration 05 runs
    return out;
  }
  // Pick the row for a given period (or the newest), plus the one before it
  // so the page can show a week-on-week delta.
  function pickPeriod(history, periodStart) {
    if (!history || !history.length) return { current: null, prev: null };
    let i = 0;
    if (periodStart) {
      i = history.findIndex(r => r.period_start === periodStart);
      // A member with no row for the week being viewed reads as "no week
      // entered" — never fall back to a different week's numbers under that
      // week's heading.
      if (i < 0) return { current: null, prev: null };
    }
    return { current: history[i], prev: history[i + 1] || null };
  }
  const PROD_FIELDS = [
    // shared
    "calls_inbound","calls_missed","confirmation_calls",
    "arrears_total","arrears_answered","arrears_collected",
    // medical
    "scans",
    "cpr_total","cpr_picked_up","cpr_booked",
    "ha_due","ha_picked_up","ha_booked",
    // dental
    "recall_due","recall_contacted","recall_booked",
    "fta_total","fta_contacted","fta_rebooked",
    "otp_due","otp_contacted","otp_booked","new_patients"
  ];
  async function saveProductivity(p) {
    const row = {
      user_id: p.userId, client_id: p.clientId || null, period_label: p.period,
      // period_label is free text and can't be ordered — period_start is what
      // makes week-on-week trends possible. Always write it.
      period_start: p.periodStart || mondayOf(new Date()).toISOString().slice(0, 10),
      notes: p.notes || null, updated_by: p.by || null,
      updated_at: new Date().toISOString()
    };
    PROD_FIELDS.forEach(f => { row[f] = p[f] || 0; });
    // Conflict on the week, not its label: a label is display text and can be
    // re-typed, which would otherwise create a second row for the same week.
    const { error } = await sb.from("productivity")
      .upsert(row, { onConflict: "user_id,period_start" });
    if (error) throw error;
  }

  /* ---- metric sets (one per vertical) ------------------------------------
     What a GP practice measures and what a dental practice measures are not
     the same list — a dentist has never heard of a Care Plan Review. Both the
     entry form and the scoreboard render from this config, so adding a third
     vertical is a config change, not a code change.

     Each group is a block of columns. `rev` makes the group earn revenue:
       {from:'x', rate:'y'}  → count x × perf_rates.y
       {from:'x', entered:true} → x is already a dollar figure
     A field with `pctOf` shows a percentage of that other field beside it.
     ---------------------------------------------------------------------- */
  const METRIC_SETS = {
    medical: {
      label: "Medical",
      source: "Calls from 3CX · bookings from HotDoc/Pracsoft",
      groups: [
        { name: "Inbound", fields: [
          { k: "calls_inbound", label: "Answered", hint: "3CX" },
          { k: "calls_missed",  label: "Missed",   hint: "3CX" },
          { k: "scans",         label: "Scans",    hint: "" } ] },
        { name: "Confirmation", fields: [
          { k: "confirmation_calls", label: "Calls", hint: "drives FTA down" } ] },
        { name: "Arrears", rev: { from: "arrears_collected", entered: true }, fields: [
          { k: "arrears_total",     label: "Calls",  hint: "total" },
          { k: "arrears_answered",  label: "Ans",    hint: "picked up", pctOf: "arrears_total" },
          { k: "arrears_collected", label: "Coll $", hint: "entered", money: true } ] },
        { name: "Care Plan Review", rev: { from: "cpr_booked", rate: "cp_value" }, fields: [
          { k: "cpr_total",     label: "Calls", hint: "total" },
          { k: "cpr_picked_up", label: "Pick",  hint: "", pctOf: "cpr_total" },
          { k: "cpr_booked",    label: "Book",  hint: "→ revenue" } ] },
        { name: "Health Assessment", rev: { from: "ha_booked", rate: "ha_value" }, fields: [
          { k: "ha_due",       label: "Due",  hint: "count" },
          { k: "ha_picked_up", label: "Pick", hint: "", pctOf: "ha_due" },
          { k: "ha_booked",    label: "Book", hint: "→ revenue" } ] }
      ],
      booked: ["cpr_booked", "ha_booked"]
    },
    dental: {
      label: "Dental",
      source: "Calls from the phone system · bookings from the practice software",
      groups: [
        { name: "Inbound", fields: [
          { k: "calls_inbound", label: "Answered",     hint: "phone system" },
          { k: "calls_missed",  label: "Missed",       hint: "phone system" },
          { k: "new_patients",  label: "New patients", hint: "booked" } ] },
        { name: "Confirmation", fields: [
          { k: "confirmation_calls", label: "Calls", hint: "drives FTA down" } ] },
        { name: "Recalls", rev: { from: "recall_booked", rate: "recall_value" }, fields: [
          { k: "recall_due",       label: "Due",  hint: "overdue" },
          { k: "recall_contacted", label: "Cont", hint: "", pctOf: "recall_due" },
          { k: "recall_booked",    label: "Book", hint: "→ revenue" } ] },
        { name: "Failed appts", rev: { from: "fta_rebooked", rate: "fta_value" }, fields: [
          { k: "fta_total",     label: "FTAs", hint: "in period" },
          { k: "fta_contacted", label: "Cont", hint: "", pctOf: "fta_total" },
          { k: "fta_rebooked",  label: "Rebk", hint: "→ recovered" } ] },
        { name: "Unscheduled tx", rev: { from: "otp_booked", rate: "otp_value" }, fields: [
          { k: "otp_due",       label: "Open", hint: "not booked" },
          { k: "otp_contacted", label: "Cont", hint: "", pctOf: "otp_due" },
          { k: "otp_booked",    label: "Book", hint: "→ revenue" } ] },
        { name: "Arrears", rev: { from: "arrears_collected", entered: true }, fields: [
          { k: "arrears_total",     label: "Calls",  hint: "total" },
          { k: "arrears_answered",  label: "Ans",    hint: "picked up", pctOf: "arrears_total" },
          { k: "arrears_collected", label: "Coll $", hint: "entered", money: true } ] }
      ],
      booked: ["recall_booked", "fta_rebooked", "otp_booked"]
    }
  };
  function metricSet(vertical) { return METRIC_SETS[vertical] || METRIC_SETS.medical; }

  const RATE_DEFAULTS = {
    cp_value: 79.70, ha_value: 246.65,
    recall_value: 210.00, fta_value: 210.00, otp_value: 650.00
  };
  const RATE_KEYS = Object.keys(RATE_DEFAULTS);

  // Configurable values used to auto-calc revenue from booked counts.
  async function perfRates() {
    try {
      const { data } = await sb.from("perf_rates").select("*").eq("id", 1).maybeSingle();
      if (data) {
        const out = {};
        RATE_KEYS.forEach(k => { out[k] = Number(data[k] != null ? data[k] : RATE_DEFAULTS[k]); });
        return out;
      }
    } catch (e) {}
    return Object.assign({}, RATE_DEFAULTS);
  }
  async function savePerfRates(vals) {
    const row = { id: 1, updated_at: new Date().toISOString() };
    RATE_KEYS.forEach(k => { if (vals[k] != null) row[k] = vals[k]; });
    const { error } = await sb.from("perf_rates").upsert(row, { onConflict: "id" });
    if (error) throw error;
  }

  // Revenue for one productivity row, broken down by the groups that earn it.
  function perfDerived(p, rates, vertical) {
    p = p || {};
    const set = metricSet(vertical);
    const parts = [];
    let total = 0;
    set.groups.forEach(function (g) {
      if (!g.rev) return;
      const amt = g.rev.entered
        ? Number(p[g.rev.from] || 0)
        : Number(p[g.rev.from] || 0) * Number(rates[g.rev.rate] || 0);
      parts.push({ group: g.name, amount: amt });
      total += amt;
    });
    return { parts: parts, total: total, byGroup: function (n) {
      const f = parts.find(x => x.group === n); return f ? f.amount : 0; } };
  }

  // Calls answered as a share of calls offered. The most credible single
  // number an owner gets, because it comes off the phone system.
  function answerRate(p) {
    // calls_missed is null on any week entered before it existed. A missing
    // value is NOT zero — reporting 100% off a blank would fabricate the most
    // credible number on the page.
    if (!p || p.calls_missed == null) return null;
    const ans = Number(p.calls_inbound || 0), miss = Number(p.calls_missed);
    if (!ans && !miss) return null;
    return ans / (ans + miss);
  }
  // Total appointments booked, per the vertical's definition of "booked".
  function bookedTotal(p, vertical) {
    if (!p) return 0;
    return metricSet(vertical).booked.reduce((t, k) => t + Number(p[k] || 0), 0);
  }
  // Week-on-week change, as a signed fraction. null when there's nothing to
  // compare against or the previous value was zero.
  function trend(now, before) {
    if (before == null || now == null) return null;
    const a = Number(now), b = Number(before);
    if (!b) return null;
    return (a - b) / b;
  }
  // Small ▲/▼ chip. `good` says which direction is the good one.
  function trendChip(t, good) {
    if (t == null || Math.abs(t) < 0.005) return "";
    const up = t > 0;
    const positive = good === "down" ? !up : up;
    const col = positive ? "var(--ok)" : "var(--danger)";
    return '<span style="font-size:11px;font-weight:700;color:' + col + ';margin-left:5px">'
      + (up ? "▲" : "▼") + Math.abs(Math.round(t * 100)) + "%</span>";
  }

  // Leaderboard for one vertical, rendered from that vertical's metric set.
  // Rows are board rows (.name/.site/.vertical/.productivity). Revenue desc.
  function scoreboardFor(list, rates, vertical) {
    const set   = metricSet(vertical);
    const money = v => "$" + Math.round(v).toLocaleString();
    const pct   = (a, b) => b ? Math.round(a / b * 100) + "%" : "–";
    const stick = "position:sticky;left:0;background:#fff;z-index:1;text-align:left";
    const rev   = "background:#faf4e8";                     // revenue column tint

    const rows = list.map(v => ({ v: v, d: perfDerived(v.productivity, rates, vertical) }))
                     .sort((a, b) => b.d.total - a.d.total);

    // A group whose revenue is entered directly (arrears) already shows that
    // dollar figure as one of its fields — it gets no separate rev column.
    const hasRevCol = g => !!(g.rev && !g.rev.entered);

    // Flatten the config into column definitions, one pass reused everywhere.
    const cols = [];
    set.groups.forEach(function (g) {
      g.fields.forEach(f => cols.push({ type: "field", g: g, f: f }));
      if (hasRevCol(g)) cols.push({ type: "rev", g: g });
    });

    const tot = {}; cols.forEach(c => { if (c.type === "field") tot[c.f.k] = 0; });
    const totRev = {}; set.groups.forEach(g => { if (g.rev) totRev[g.name] = 0; });
    let tAll = 0, counted = 0;

    const body = rows.map(function (r, i) {
      const p = r.v.productivity;
      const who = '<td style="' + stick + '"><b>' + (i === 0 && p ? "🥇 " : i === 1 && p ? "🥈 " : i === 2 && p ? "🥉 " : "")
        + r.v.name + '</b><div style="font-size:11px;color:var(--grey)">📍 ' + r.v.site + "</div></td>";
      if (!p) {
        // +1 for the Total $ column, which isn't in `cols`
        return "<tr>" + who + '<td colspan="' + (cols.length + 1) + '" style="color:var(--grey);text-align:center">'
          + "Awaiting team-lead entry</td></tr>";
      }
      counted++;
      tAll += r.d.total;
      set.groups.forEach(g => { if (g.rev) totRev[g.name] += r.d.byGroup(g.name); });
      const cells = cols.map(function (c) {
        if (c.type === "rev") return '<td style="' + rev + '">' + money(r.d.byGroup(c.g.name)) + "</td>";
        const raw = Number(p[c.f.k] || 0);
        tot[c.f.k] += raw;
        const shown = c.f.money ? money(raw) : raw;
        const sub = c.f.pctOf
          ? ' <span style="color:var(--grey);font-size:11px">' + pct(raw, p[c.f.pctOf]) + "</span>" : "";
        return "<td>" + shown + sub + "</td>";
      }).join("");
      return "<tr>" + who + cells + '<td style="' + rev + ';font-weight:700">' + money(r.d.total) + "</td></tr>";
    }).join("");

    const totalRow = counted
      ? '<tr style="border-top:2px solid var(--line);font-weight:700;background:var(--cream)">'
        + '<td style="' + stick + ';background:var(--cream)">Team total</td>'
        + cols.map(c => c.type === "rev"
            ? '<td style="' + rev + '">' + money(totRev[c.g.name]) + "</td>"
            : "<td>" + (c.f.money ? money(tot[c.f.k]) : tot[c.f.k]) + "</td>").join("")
        + '<td style="' + rev + '">' + money(tAll) + "</td></tr>"
      : "";

    // Two header rows: group spans on top, field labels underneath.
    const head1 = set.groups.map(g =>
      '<th colspan="' + (g.fields.length + (hasRevCol(g) ? 1 : 0)) + '">' + g.name + "</th>").join("");
    const head2 = cols.map(c => "<th>" + (c.type === "rev" ? "$" : c.f.label) + "</th>").join("");

    return '<div class="panel" style="overflow-x:auto"><table class="scoreboard">'
      + "<thead>"
      + '<tr><th rowspan="2" style="' + stick + '">' + set.label + " team</th>" + head1
      +   '<th rowspan="2">Total $</th></tr>'
      + "<tr>" + head2 + "</tr>"
      + "</thead><tbody>" + body + totalRow + "</tbody></table></div>";
  }

  // A board can mix verticals (the whole-team view does), and the two metric
  // sets don't share columns — so render one table per vertical present.
  function buildScoreboard(list, rates) {
    const verticals = [];
    list.forEach(v => { const t = v.vertical || "medical"; if (verticals.indexOf(t) === -1) verticals.push(t); });
    return verticals.map(function (t) {
      const rows = list.filter(v => (v.vertical || "medical") === t);
      const head = verticals.length > 1
        ? '<div class="section-h" style="margin-top:26px">' + metricSet(t).label
          + " <span>" + rows.length + " member" + (rows.length === 1 ? "" : "s") + "</span></div>"
        : "";
      return head + scoreboardFor(rows, rates, t);
    }).join("");
  }

  /* ---- client-admin board (view-only, scoped to one client) ------------- */
  // Returns each VA on the client with training volume, capabilities (from
  // completed modules), week hours + billable amount. NO pay_rate is fetched.
  async function clientBoard(clientId, periodStart) {
    const { data: vas, error: e1 } = await sb.from("users")
      // note: pay_rate NOT selected. rostered_hours is not pay data.
      .select("id,name,vertical,billable_rate,site,rostered_hours")
      .eq("client_id", clientId).eq("role", "va").eq("active", true)
      .order("site").order("name");
    if (e1) throw e1;
    if (!vas || !vas.length) return [];

    const verticals = [...new Set(vas.map(v => v.vertical))];
    const modsByVertical = {};
    for (const v of verticals) modsByVertical[v] = await modulesFor(v);

    const ids = vas.map(v => v.id);
    const [progressAll, shiftsAll, historyAll] = await Promise.all([
      progressRowsForMany(ids), weekShiftsForMany(ids), productivityHistoryForMany(ids)
    ]);

    const out = [];
    for (const va of vas) {
      const mods    = modsByVertical[va.vertical] || [];
      const rows    = progressAll.get(va.id) || new Map();
      const doneSet = new Set(rows.keys());
      const shifts  = shiftsAll.get(va.id) || [];
      const billableHours = sumHours(shifts);          // closed shifts only
      const hours   = sumHoursLive(shifts);            // includes the open one
      const history = historyAll.get(va.id) || [];
      const period  = pickPeriod(history, periodStart);
      const open    = openIn(shifts);
      out.push(Object.assign(
        vaProgress(mods, doneSet, rows),
        {
          id: va.id, name: va.name, vertical: va.vertical,
          site: va.site || "Unassigned",
          hours: hours,
          billableHours: billableHours,
          billable: billableHours * Number(va.billable_rate || 0),
          rostered: Number(va.rostered_hours || 0),
          pace: paceFor(hours, va.rostered_hours),
          byDay: hoursByDay(shifts),
          openSince: open ? open.clock_in : null,
          lastOut: lastOutIn(shifts),
          history: history,
          productivity: period.current,
          prevProductivity: period.prev
        }
      ));
    }
    return out;
  }

  // Every period any of this client's VAs has data for, newest first.
  // Drives the period picker on the owner's page.
  async function periodsForClient(clientId) {
    const { data, error } = await sb.from("productivity")
      .select("period_label,period_start").eq("client_id", clientId)
      .order("period_start", { ascending: false, nullsFirst: false });
    if (error) return [];
    const seen = new Set(), out = [];
    (data || []).forEach(function (r) {
      const key = r.period_start || r.period_label;
      if (seen.has(key)) return;
      seen.add(key); out.push(r);
    });
    return out;
  }

  // Shared progress summary for a VA (used by client + team boards).
  // Splits onboarding / training / the AI track, and returns the checklist.
  function vaProgress(mods, doneSet, rows) {
    rows = rows || new Map();
    const onb = mods.filter(m => m.category === "onboarding");
    const trn = mods.filter(m => m.category === "training");
    const ai  = mods.filter(m => m.category === "ai");
    const doneMods = mods.filter(m => doneSet.has(m.id));
    return {
      modulesDone: doneMods.length, modulesTotal: mods.length,
      onbDone: onb.filter(m => doneSet.has(m.id)).length, onbTotal: onb.length,
      trnDone: trn.filter(m => doneSet.has(m.id)).length, trnTotal: trn.length,
      aiDone:  ai.filter(m => doneSet.has(m.id)).length,  aiTotal:  ai.length,
      // The AI track has its own badges — keep its labels out of the general
      // capability chips so the card doesn't turn into a wall of tags.
      capabilities: [...new Set(doneMods.filter(m => m.category !== "ai")
                                        .map(m => m.capability_label))],
      badges: aiBadges(ai, doneSet, rows),
      modules: mods.map(m => {
        const r = rows.get(m.id) || null;
        return {
          id: m.id, ord: m.ord, title: m.title, icon: m.icon,
          category: m.category, tier: m.tier,
          requiresEvidence: !!m.requires_evidence,
          evidencePrompt: m.evidence_prompt,
          done: doneSet.has(m.id),
          evidenceUrl: r ? r.evidence_url : null,
          verifiedAt: r ? r.verified_at : null
        };
      })
    };
  }

  // The two AI certification tiers. A badge is earned only when every module
  // in the tier is complete AND the tier's practical has been verified by a
  // manager — a badge a quiz alone can mint is worth nothing to a client.
  const AI_TIERS = [
    { tier: "foundation", label: "AI Assisted", icon: "🤖" },
    { tier: "builder",    label: "AI Builder",  icon: "🛠️" }
  ];
  function aiBadges(aiMods, doneSet, rows) {
    return AI_TIERS.map(function (t) {
      const set  = aiMods.filter(m => m.tier === t.tier);
      const done = set.filter(m => doneSet.has(m.id)).length;
      const evi  = set.filter(m => m.requires_evidence);
      const verified = evi.length > 0 && evi.every(m => {
        const r = rows.get(m.id); return r && r.verified_at; });
      const submitted = evi.some(m => {
        const r = rows.get(m.id); return r && r.evidence_url && !r.verified_at; });
      return {
        tier: t.tier, label: t.label, icon: t.icon,
        done: done, total: set.length,
        earned: set.length > 0 && done === set.length && verified,
        awaitingVerification: submitted
      };
    });
  }

  // Whole-team board for admin / team_lead: every active VA across all
  // clients, with client + site + onboarding/training progress + drill-down.
  // includeDemo: owners see the seeded demo clinics; managers running the real
  // team do not, so demo people can't be mistaken for staff to follow up.
  async function teamBoard(includeDemo) {
    let q = sb.from("users")
      .select("id,name,vertical,site,client_id,rostered_hours,is_demo")
      .eq("role", "va").eq("active", true);
    if (!includeDemo) q = q.eq("is_demo", false);
    const { data: vas, error } = await q.order("name");
    if (error) throw error;
    if (!vas || !vas.length) return [];
    const { data: clients } = await sb.from("clients").select("id,name");
    const clientName = {};
    (clients || []).forEach(c => { clientName[c.id] = c.name; });
    const ids = vas.map(v => v.id);
    const [progressAll, shiftsAll, historyAll] = await Promise.all([
      progressRowsForMany(ids), weekShiftsForMany(ids), productivityHistoryForMany(ids)
    ]);
    const modsCache = {};
    const out = [];
    for (const va of vas) {
      if (!modsCache[va.vertical]) modsCache[va.vertical] = await modulesFor(va.vertical);
      const rows = progressAll.get(va.id) || new Map();
      const shifts = shiftsAll.get(va.id) || [];
      const hours = sumHoursLive(shifts);
      const hist = historyAll.get(va.id) || [];
      const prod = hist.length ? hist[0] : null;
      // full history so the entry form can load whichever week is selected
      out.push(Object.assign(
        vaProgress(modsCache[va.vertical], new Set(rows.keys()), rows),
        {
          id: va.id, name: va.name, vertical: va.vertical,
          site: va.site || "Unassigned",
          client: clientName[va.client_id] || "—",
          client_id: va.client_id,
          is_demo: !!va.is_demo,
          rostered: Number(va.rostered_hours || 0),
          hours: hours,
          pace: paceFor(hours, va.rostered_hours),
          history: hist,
          productivity: prod
        }
      ));
    }
    return out;
  }

  /* ---- admin aggregate (all VAs) ---------------------------------------- */
  async function adminStats() {
    const { data: vas } = await sb.from("users")
      .select("id,vertical").eq("role", "va").eq("active", true)
      .eq("is_demo", false);        // demo clinics never inflate the real stats
    let totalHours = 0, totalDone = 0, totalMods = 0;
    const modsCache = {};
    const ids = (vas || []).map(v => v.id);
    const [progressAll, shiftsAll] = await Promise.all([
      progressRowsForMany(ids), weekShiftsForMany(ids)
    ]);
    for (const va of (vas || [])) {
      if (!modsCache[va.vertical]) modsCache[va.vertical] = await modulesFor(va.vertical);
      const mods = modsCache[va.vertical];
      const done = progressAll.get(va.id) || new Map();
      totalMods += mods.length;
      totalDone += mods.filter(m => done.has(m.id)).length;
      totalHours += sumHours(shiftsAll.get(va.id) || []);
    }
    return {
      activeVAs: (vas || []).length,
      weekHours: totalHours,
      trainingPct: totalMods ? Math.round((totalDone / totalMods) * 100) : 0
    };
  }

  /* ---- admin: member management (admin + Ericka manager) ---------------- */
  // Every remote team member (role = va), for the admin page. Never selects
  // pay_rate — managers must not see pay economics. Newest first.
  async function listMembers(includeDemo) {
    let q = sb.from("users")
      .select("id,name,role,site,vertical,active,created_at,rostered_hours,is_demo")
      .eq("role", "va");
    if (!includeDemo) q = q.eq("is_demo", false);   // demo clinics are owner-only
    const { data, error } = await q
      .order("active", { ascending: false })
      .order("created_at", { ascending: false });
    if (error) throw error;
    return data || [];
  }

  // Onboard a new remote team member. Managers create VAs at rate 0 (pay
  // economics stay with the owner); admin may pass billable/pay explicitly.
  async function createMember(m) {
    const row = {
      name: (m.name || "").trim(),
      pin: String(m.pin || "").trim(),
      role: m.role || "va",
      // explicit null = General VA (no client); undefined = default to SIA Medical
      client_id: (m.clientId === undefined ? SIA_MEDICAL_CLIENT_ID : m.clientId),
      vertical: m.vertical || "medical",
      site: m.site || null,
      billable_rate: m.billable_rate || 0,
      pay_rate: m.pay_rate || 0,
      rostered_hours: m.rostered_hours || 0,
      active: true
    };
    if (!row.name)            throw new Error("Name is required.");
    if (!/^\d{4,6}$/.test(row.pin)) throw new Error("PIN must be 4–6 digits.");
    const { data, error } = await sb.from("users").insert(row).select("id,name").single();
    if (error) throw error;
    return data;
  }

  // Reassign clinic / activate-deactivate a member.
  async function updateMember(userId, fields) {
    const patch = {};
    if ("site"   in fields) patch.site   = fields.site || null;
    if ("active" in fields) patch.active = !!fields.active;
    if ("rostered_hours" in fields) {
      const h = Number(fields.rostered_hours);
      if (isNaN(h) || h < 0 || h > 80) throw new Error("Rostered hours must be between 0 and 80.");
      patch.rostered_hours = h;
    }
    const { error } = await sb.from("users").update(patch).eq("id", userId);
    if (error) throw error;
  }

  // Reset any member's PIN (admin/manager), or your own ("Change my PIN").
  async function resetPin(userId, newPin) {
    const pin = String(newPin || "").trim();
    if (!/^\d{4,6}$/.test(pin)) throw new Error("PIN must be 4–6 digits.");
    const { error } = await sb.from("users").update({ pin }).eq("id", userId);
    if (error) throw error;
  }
  const changeMyPin = resetPin;   // same operation, scoped to the caller's id

  /* ---- expose ----------------------------------------------------------- */
  window.ericka = {
    CLINICS, GENERAL_VA, SIA_MEDICAL_CLIENT_ID, isGeneralVA,
    listMembers, createMember, updateMember, resetPin, changeMyPin,
    session, setSession, logout, requireRole, homeFor, login,
    weekStart, mondayOf, weekLabelFor, hoursBetween, weekProgress, paceFor,
    openShift, clockIn, clockOut, weekShifts, weekShiftsForMany, sumHours, sumHoursLive,
    shiftHours, isLiveShift, isSafeUrl,
    hoursByDay, openIn, lastOutIn,
    modulesFor, moduleWithSections, progressFor, progressRowsFor, progressRowsForMany,
    completeModule, quizFor, submitEvidence, verifyEvidence, AI_TIERS,
    cheatsheetForSite, siteHasCheatsheet, revealCheatsheetNav,
    clientBoard, teamBoard, adminStats, periodsForClient,
    productivityFor, productivityHistory, productivityHistoryForMany,
    pickPeriod, saveProductivity, PROD_FIELDS,
    METRIC_SETS, metricSet, RATE_KEYS, RATE_DEFAULTS,
    perfRates, savePerfRates, perfDerived, buildScoreboard,
    answerRate, bookedTotal, trend, trendChip,
    // small helper: bail out gracefully if keys aren't set yet
    ready() {
      if (!window.ERICKA_CONFIGURED) {
        document.body.innerHTML =
          '<div style="font-family:Inter,sans-serif;max-width:520px;margin:16vh auto;padding:32px;' +
          'text-align:center;color:#241b33"><h2 style="font-family:Georgia,serif">Almost there</h2>' +
          '<p style="color:#6a6076;line-height:1.6">Supabase keys aren\'t set yet. Paste your Project URL ' +
          'and anon key into <b>config.js</b>, then reload.</p></div>';
        return false;
      }
      return true;
    }
  };
})();
