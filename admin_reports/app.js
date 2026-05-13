import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js';

const $ = (id) => document.getElementById(id);

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});

const loginSection = $('login-section');
const appSection = $('app-section');
const loginMsg = $('login-msg');
const listMsg = $('list-msg');
const tbody = $('tbody');
const userPill = $('user-pill');
const btnRefresh = $('btn-refresh');

/** Min time between manual list refreshes (avoids Supabase / CDN throttling when spamming Refresh). */
const REFRESH_MIN_INTERVAL_MS = 2500;

let listRefreshPromise = null;
let lastListRefreshFinishedAt = 0;

function show(el, on) {
  el.classList.toggle('hidden', !on);
}

function setLoginError(msg) {
  loginMsg.textContent = msg || '';
  loginMsg.classList.toggle('err', !!msg);
}

function clearListMessage() {
  listMsg.textContent = '';
  listMsg.classList.remove('err', 'hint');
}

function setListError(msg) {
  listMsg.textContent = msg || '';
  listMsg.classList.toggle('err', !!msg);
  listMsg.classList.toggle('hint', false);
}

function setListHint(msg) {
  listMsg.textContent = msg || '';
  listMsg.classList.toggle('hint', !!msg);
  listMsg.classList.toggle('err', false);
}

function isRateLimitedError(error) {
  if (!error) return false;
  const msg = (error.message || String(error)).toLowerCase();
  const code = String(error.code ?? '');
  if (code === '429' || error.status === 429) return true;
  if (msg.includes('rate limit') || msg.includes('too many requests')) return true;
  return false;
}

/**
 * @param {{ force?: boolean }} [opts]
 * - force: skip local throttle (use after login / after save).
 */
async function refreshList(opts = {}) {
  const force = opts.force === true;
  const now = Date.now();

  if (!force && lastListRefreshFinishedAt > 0) {
    const elapsed = now - lastListRefreshFinishedAt;
    if (elapsed < REFRESH_MIN_INTERVAL_MS) {
      const waitSec = Math.ceil((REFRESH_MIN_INTERVAL_MS - elapsed) / 1000);
      setListHint(`Please wait ${waitSec}s before refreshing again (avoids rate limits).`);
      return;
    }
  }

  if (listRefreshPromise) {
    return listRefreshPromise;
  }

  clearListMessage();
  btnRefresh.disabled = true;

  listRefreshPromise = (async () => {
    tbody.replaceChildren();
    const { data, error } = await supabase.rpc('admin_list_user_reports', {
      p_limit: 200,
    });
    if (error) {
      if (isRateLimitedError(error)) {
        setListError(
          'Server rate limit reached. Wait a minute, then try Refresh again.',
        );
      } else {
        setListError(error.message || String(error));
      }
      return;
    }
    const rows = Array.isArray(data) ? data : [];
    if (rows.length === 0) {
      const tr = document.createElement('tr');
      const td = document.createElement('td');
      td.colSpan = 10;
      td.style.color = 'var(--muted)';
      td.textContent = 'No reports yet, or you are not an admin.';
      tr.appendChild(td);
      tbody.appendChild(tr);
      return;
    }
    for (const r of rows) {
      tbody.appendChild(renderRow(r));
    }
  })();

  try {
    await listRefreshPromise;
  } finally {
    lastListRefreshFinishedAt = Date.now();
    listRefreshPromise = null;
    btnRefresh.disabled = false;
  }
}

function tdText(text) {
  const td = document.createElement('td');
  td.textContent = text ?? '';
  return td;
}

function renderRow(r) {
  const tr = document.createElement('tr');
  const id = r.id;
  const created = r.created_at
    ? new Date(r.created_at).toLocaleString()
    : '';

  tr.appendChild(tdText(created));

  const tdRep = document.createElement('td');
  tdRep.appendChild(document.createTextNode(r.reporter_username ?? ''));
  const rid = document.createElement('div');
  rid.className = 'mono';
  rid.textContent = r.reporter_id ?? '';
  tdRep.appendChild(rid);
  tr.appendChild(tdRep);

  const tdTarget = document.createElement('td');
  tdTarget.appendChild(document.createTextNode(r.reported_username ?? ''));
  const tid = document.createElement('div');
  tid.className = 'mono';
  tid.textContent = r.reported_user_id ?? '';
  tdTarget.appendChild(tid);
  tr.appendChild(tdTarget);

  const tdFrozen = document.createElement('td');
  tdFrozen.className = 'mono';
  tdFrozen.style.whiteSpace = 'nowrap';
  if (r.reported_frozen_until) {
    tdFrozen.textContent = new Date(r.reported_frozen_until).toLocaleString();
  } else {
    tdFrozen.textContent = '—';
    tdFrozen.style.color = 'var(--muted)';
  }
  tr.appendChild(tdFrozen);

  tr.appendChild(tdText(r.reason));
  tr.appendChild(tdText(r.details));

  const tdCtx = document.createElement('td');
  const pre = document.createElement('pre');
  pre.className = 'mono';
  pre.style.margin = '0';
  pre.style.whiteSpace = 'pre-wrap';
  pre.style.maxWidth = '180px';
  pre.textContent =
    r.context == null
      ? ''
      : typeof r.context === 'string'
        ? r.context
        : JSON.stringify(r.context);
  tdCtx.appendChild(pre);
  tr.appendChild(tdCtx);

  const tdStatus = document.createElement('td');
  const sel = document.createElement('select');
  sel.dataset.k = 'status';
  sel.style.minWidth = '7rem';
  for (const s of ['pending', 'reviewing', 'resolved', 'dismissed']) {
    const opt = document.createElement('option');
    opt.value = s;
    opt.textContent = s;
    if (r.status === s) opt.selected = true;
    sel.appendChild(opt);
  }
  tdStatus.appendChild(sel);
  tr.appendChild(tdStatus);

  const tdEdit = document.createElement('td');
  const labRes = document.createElement('label');
  labRes.textContent = 'Resolution';
  labRes.style.marginTop = '0';
  tdEdit.appendChild(labRes);
  const inpRes = document.createElement('input');
  inpRes.type = 'text';
  inpRes.dataset.k = 'resolution';
  inpRes.placeholder = 'e.g. no_action';
  inpRes.value = r.resolution ?? '';
  tdEdit.appendChild(inpRes);
  const labNotes = document.createElement('label');
  labNotes.textContent = 'Admin notes';
  labNotes.style.marginTop = '0.35rem';
  tdEdit.appendChild(labNotes);
  const ta = document.createElement('textarea');
  ta.dataset.k = 'admin_notes';
  ta.value = r.admin_notes ?? '';
  tdEdit.appendChild(ta);
  tr.appendChild(tdEdit);

  const labFreeze = document.createElement('label');
  labFreeze.textContent = 'Freeze reported (days, 0=clear, blank=no change)';
  labFreeze.style.marginTop = '0.35rem';
  tdEdit.appendChild(labFreeze);
  const inpFreeze = document.createElement('input');
  inpFreeze.type = 'number';
  inpFreeze.min = '0';
  inpFreeze.max = '365';
  inpFreeze.step = '1';
  inpFreeze.placeholder = 'e.g. 7';
  inpFreeze.dataset.k = 'freeze_days';
  inpFreeze.style.marginBottom = '0.35rem';
  tdEdit.appendChild(inpFreeze);

  const tdBtn = document.createElement('td');
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'btn-primary';
  btn.textContent = 'Save';
  btn.addEventListener('click', async () => {
    const status = sel.value;
    const resolution = inpRes.value;
    const admin_notes = ta.value;
    btn.disabled = true;
    const rawFreeze = inpFreeze.value.trim();
    if (rawFreeze !== '') {
      const n = parseInt(rawFreeze, 10);
      if (!Number.isFinite(n) || n < 0 || n > 365) {
        alert('Freeze days must be between 0 and 365 (or leave blank).');
        btn.disabled = false;
        return;
      }
    }

    const payload = {
      p_report_id: id,
      p_status: status,
      p_resolution: resolution || null,
      p_admin_notes: admin_notes || null,
    };
    if (rawFreeze !== '') {
      payload.p_freeze_days = parseInt(rawFreeze, 10);
    }

    const { error: upErr } = await supabase.rpc('admin_update_user_report', payload);
    btn.disabled = false;
    if (upErr) {
      if (isRateLimitedError(upErr)) {
        alert(
          'Rate limited. Wait briefly and try Save again.',
        );
      } else {
        alert(upErr.message || String(upErr));
      }
      return;
    }
    await refreshList({ force: true });
  });
  tdBtn.appendChild(btn);
  tr.appendChild(tdBtn);

  return tr;
}

async function applySession() {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (session?.user) {
    show(loginSection, false);
    show(appSection, true);
    userPill.textContent = session.user.email || session.user.id;
    $('btn-logout').classList.remove('hidden');
    await refreshList({ force: true });
  } else {
    show(loginSection, true);
    show(appSection, false);
    userPill.textContent = '';
    $('btn-logout').classList.add('hidden');
  }
}

$('btn-login').addEventListener('click', async () => {
  setLoginError('');
  const email = $('email').value.trim();
  const password = $('password').value;
  if (!email || !password) {
    setLoginError('Enter email and password.');
    return;
  }
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    setLoginError(error.message);
    return;
  }
  await applySession();
});

$('btn-logout').addEventListener('click', async () => {
  await supabase.auth.signOut();
  await applySession();
});

btnRefresh.addEventListener('click', () => refreshList({ force: false }));

supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'TOKEN_REFRESHED' && session?.user) {
    userPill.textContent = session.user.email || session.user.id;
    return;
  }
  applySession();
});

applySession();
