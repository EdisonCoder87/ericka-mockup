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
    if (role === "team_lead")    return "10_team.html";
    if (role === "client_admin") return "08_client_home.html";
    return "05_va_home.html"; // va
  }

  // Guard a page. Pass allowed roles, e.g. requireRole(['va']).
  function requireRole(roles) {
    const s = session();
    if (!s) { location.href = "01_welcome.html"; return null; }
    if (roles && roles.indexOf(s.role) === -1) { location.href = homeFor(s.role); return null; }
    return s;
  }

  /* ---- login ------------------------------------------------------------ */
  async function login(name, pin) {
    const { data, error } = await sb
      .from("users")
      .select("id,name,role,client_id,vertical,active")
      .eq("name", name).eq("pin", String(pin)).eq("active", true)
      .maybeSingle();
    if (error) throw error;
    if (!data) return null;
    setSession(data);
    return data;
  }

  /* ---- dates ------------------------------------------------------------ */
  // Monday 00:00 of the current week (local) → ISO
  function weekStart() {
    const d = new Date(); d.setHours(0, 0, 0, 0);
    const dow = (d.getDay() + 6) % 7;            // 0 = Monday
    d.setDate(d.getDate() - dow);
    return d;
  }
  function hoursBetween(a, b) {
    return (new Date(b).getTime() - new Date(a).getTime()) / 3.6e6;
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
    const { data, error } = await sb.from("timesheets")
      .select("*").eq("va_id", vaId)
      .gte("clock_in", weekStart().toISOString())
      .order("clock_in", { ascending: false });
    if (error) throw error;
    return data || [];
  }
  // Sum of completed hours this week for a VA.
  function sumHours(shifts) {
    return shifts.reduce((t, s) => t + (s.clock_out ? hoursBetween(s.clock_in, s.clock_out) : 0), 0);
  }

  /* ---- training --------------------------------------------------------- */
  async function modulesFor(vertical) {
    // onboarding first (category sorts before 'training'), then by ord
    const { data, error } = await sb.from("training_modules")
      .select("*").eq("vertical", vertical)
      .order("category", { ascending: true }).order("ord", { ascending: true });
    if (error) throw error;
    return data || [];
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
    try {
      const { data, error } = await sb.from("productivity")
        .select("*").eq("user_id", userId)
        .order("updated_at", { ascending: false }).limit(1).maybeSingle();
      if (error) throw error;
      return data;
    } catch (e) { return null; }   // table may not exist until migration 05 runs
  }
  async function saveProductivity(p) {
    const row = {
      user_id: p.userId, client_id: p.clientId || null,
      period_label: p.period,
      calls: p.calls || 0, bookings: p.bookings || 0, payments: p.payments || 0,
      notes: p.notes || null, updated_by: p.by || null,
      updated_at: new Date().toISOString()
    };
    const { error } = await sb.from("productivity")
      .upsert(row, { onConflict: "user_id,period_label" });
    if (error) throw error;
  }

  /* ---- client-admin board (view-only, scoped to one client) ------------- */
  // Returns each VA on the client with training volume, capabilities (from
  // completed modules), week hours + billable amount. NO pay_rate is fetched.
  async function clientBoard(clientId) {
    const { data: vas, error: e1 } = await sb.from("users")
      .select("id,name,vertical,billable_rate,site")       // note: pay_rate NOT selected
      .eq("client_id", clientId).eq("role", "va").eq("active", true)
      .order("site").order("name");
    if (e1) throw e1;
    if (!vas || !vas.length) return [];

    const verticals = [...new Set(vas.map(v => v.vertical))];
    const modsByVertical = {};
    for (const v of verticals) modsByVertical[v] = await modulesFor(v);

    const out = [];
    for (const va of vas) {
      const mods  = modsByVertical[va.vertical] || [];
      const doneSet = new Set(await progressFor(va.id));
      const shifts = await weekShifts(va.id);
      const hours  = sumHours(shifts);
      const prod   = await productivityFor(va.id);
      out.push(Object.assign(
        vaProgress(mods, doneSet),
        {
          id: va.id, name: va.name, vertical: va.vertical,
          site: va.site || "Unassigned",
          hours: hours,
          billable: hours * Number(va.billable_rate || 0),
          productivity: prod
        }
      ));
    }
    return out;
  }

  // Shared progress summary for a VA (used by client + team boards).
  // Splits onboarding vs training and returns the full module checklist.
  function vaProgress(mods, doneSet) {
    const onb = mods.filter(m => m.category === "onboarding");
    const trn = mods.filter(m => m.category === "training");
    const doneMods = mods.filter(m => doneSet.has(m.id));
    return {
      modulesDone: doneMods.length, modulesTotal: mods.length,
      onbDone: onb.filter(m => doneSet.has(m.id)).length, onbTotal: onb.length,
      trnDone: trn.filter(m => doneSet.has(m.id)).length, trnTotal: trn.length,
      capabilities: doneMods.map(m => m.capability_label),
      modules: mods.map(m => ({
        ord: m.ord, title: m.title, icon: m.icon,
        category: m.category, done: doneSet.has(m.id)
      }))
    };
  }

  // Whole-team board for admin / team_lead: every active VA across all
  // clients, with client + site + onboarding/training progress + drill-down.
  async function teamBoard() {
    const { data: vas, error } = await sb.from("users")
      .select("id,name,vertical,site,client_id")
      .eq("role", "va").eq("active", true).order("name");
    if (error) throw error;
    if (!vas || !vas.length) return [];
    const { data: clients } = await sb.from("clients").select("id,name");
    const clientName = {};
    (clients || []).forEach(c => { clientName[c.id] = c.name; });
    const modsCache = {};
    const out = [];
    for (const va of vas) {
      if (!modsCache[va.vertical]) modsCache[va.vertical] = await modulesFor(va.vertical);
      const doneSet = new Set(await progressFor(va.id));
      const prod = await productivityFor(va.id);
      out.push(Object.assign(
        vaProgress(modsCache[va.vertical], doneSet),
        {
          id: va.id, name: va.name, vertical: va.vertical,
          site: va.site || "Unassigned",
          client: clientName[va.client_id] || "—",
          client_id: va.client_id,
          productivity: prod
        }
      ));
    }
    return out;
  }

  /* ---- admin aggregate (all VAs) ---------------------------------------- */
  async function adminStats() {
    const { data: vas } = await sb.from("users")
      .select("id,vertical").eq("role", "va").eq("active", true);
    let totalHours = 0, totalDone = 0, totalMods = 0;
    const modsCache = {};
    for (const va of (vas || [])) {
      if (!modsCache[va.vertical]) modsCache[va.vertical] = await modulesFor(va.vertical);
      const mods = modsCache[va.vertical];
      const done = await progressFor(va.id);
      totalMods += mods.length;
      totalDone += done.filter(id => mods.some(m => m.id === id)).length;
      totalHours += sumHours(await weekShifts(va.id));
    }
    return {
      activeVAs: (vas || []).length,
      weekHours: totalHours,
      trainingPct: totalMods ? Math.round((totalDone / totalMods) * 100) : 0
    };
  }

  /* ---- expose ----------------------------------------------------------- */
  window.ericka = {
    session, setSession, logout, requireRole, homeFor, login,
    weekStart, hoursBetween,
    openShift, clockIn, clockOut, weekShifts, sumHours,
    modulesFor, moduleWithSections, progressFor, completeModule, quizFor,
    cheatsheetForSite, siteHasCheatsheet, revealCheatsheetNav,
    clientBoard, teamBoard, adminStats,
    productivityFor, saveProductivity,
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
