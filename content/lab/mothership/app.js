// Character sheet state: all editable fields as JSON, saved to localStorage keyed by character ID.

// TODO: image, seeing original values

const STORAGE_PREFIX = 'mothership-char-';

// When set, all changes save to this key. When null, charId is editable and we only load on type (no save).
let lockedCharacterKey = null;

// When true, we don't save to localStorage.
let localStorageDisabled = false;

// Journal: multiple pages; current page text is in the textarea, rest in memory.
let journalPages = [''];
let journalPageIndex = 0;

const emptyState = (charId) => ({
  charId: charId || '',
  charName: '',
  pronouns: '',
  charClass: '',
  personalNotes: '',
  highScore: 0,  
  strength: 0,
  speed: 0,
  intellect: 0,
  combat: 0,
  sanity: 0,
  fear: 0,
  body: 0,
  conditions: '',
  health: 0,
  'health-max': 0,
  wounds: 0,
  'wounds-max': 0,
  stress: 0,
  'stress-min': 0,
  loadout: '',
  trinket: '',
  patch: '',
  'armor-points': 0,
  credits: 0,
  skills: [],
  imageUrl: '',
  journalPages: [''],
  journalPageIndex: 0,
});

// Build state object from form (all inputs, textareas, checkboxes).
function getStateFromForm() {
  const id = (el) => el && el.value !== undefined ? el.value : '';
  const num = (el) => {
    if (!el || el.type !== 'number') return 0;
    const n = parseInt(el.value, 10);
    return Number.isNaN(n) ? 0 : n;
  };

  const journalEl = document.getElementById('journal');
  if (journalEl) journalPages[journalPageIndex] = journalEl.value;

  return {
    charId: id(document.getElementById('charId')),
    charName: id(document.getElementById('charName')),
    pronouns: id(document.getElementById('pronouns')),
    charClass: id(document.getElementById('charClass')),
    personalNotes: id(document.getElementById('personalNotes')),
    highScore: num(document.getElementById('highScore')),
    strength: num(document.getElementById('strength')),
    speed: num(document.getElementById('speed')),
    intellect: num(document.getElementById('intellect')),
    combat: num(document.getElementById('combat')),
    sanity: num(document.getElementById('sanity')),
    fear: num(document.getElementById('fear')),
    body: num(document.getElementById('body')),
    conditions: id(document.getElementById('conditions')),
    health: num(document.getElementById('health')),
    'health-max': num(document.getElementById('health-max')),
    wounds: num(document.getElementById('wounds')),
    'wounds-max': num(document.getElementById('wounds-max')),
    stress: num(document.getElementById('stress')),
    'stress-min': num(document.getElementById('stress-min')),
    loadout: id(document.getElementById('loadout')),
    trinket: id(document.getElementById('trinket')),
    patch: id(document.getElementById('patch')),
    'armor-points': num(document.getElementById('armor-points')),
    credits: num(document.getElementById('credits')),
    skills: getSkillsState(),
    imageUrl: id(document.getElementById('imageUrl')),
    journalPages: journalPages.slice(),
    journalPageIndex,
  };
}

function getSkillsState() {
  const skills = [];
  document.querySelectorAll('[id^="skill-"]').forEach((el) => {
    if (el.id && el.type === 'checkbox' && el.checked)
      skills.push(el.id.replace(/^skill-/, ''));
  });
  return skills;
}

function applyStateToForm(state) {
  if (!state || typeof state !== 'object') return;
  const set = (id, value) => {
    const el = document.getElementById(id);
    if (!el) return;
    if (el.type === 'checkbox') el.checked = !!value;
    else if (value !== undefined && value !== null) el.value = String(value);
  };
  Object.keys(state).forEach((key) => {
    if (key === 'skills') {
      const s = state.skills;
      if (Array.isArray(s)) {
        const ids = new Set(s.map((n) => String(n).trim()).filter(Boolean));
        document.querySelectorAll('[id^="skill-"]').forEach((el) => {
          if (el.type === 'checkbox' && el.id)
            el.checked = ids.has(el.id.replace(/^skill-/, ''));
        });
      } else if (s && typeof s === 'object') {
        Object.keys(s).forEach((skillId) => set(skillId, s[skillId]));
      }
    } else if (key !== 'journalPages' && key !== 'journalPageIndex') {
      set(key, state[key]);
    }
  });
  if (Array.isArray(state.journalPages) && state.journalPages.length)
    journalPages = state.journalPages.slice();
  else if (state.journal !== undefined && typeof state.journal === 'string')
    journalPages = [state.journal];
  else
    journalPages = [''];
  if (state.journalPageIndex !== undefined)
    journalPageIndex = Math.min(Math.max(0, parseInt(state.journalPageIndex, 10) || 0), Math.max(0, journalPages.length - 1));
  updateJournalUI();
  updateTraumaResponse();
  updateCharacterImage();
  updatePageTitle();
}

const DEFAULT_TITLE = 'Mothership Character Sheet';

function updatePageTitle() {
  const nameEl = document.getElementById('charName');
  const name = nameEl && (nameEl.value || '').trim();
  document.title = name || DEFAULT_TITLE;
}

// Key we save to: only when locked.
function getCharacterKey() {
  return lockedCharacterKey;
}

// Key for copy URL / display: locked key or current input.
function getCharacterKeyForDisplay() {
  if (lockedCharacterKey) return lockedCharacterKey;
  const el = document.getElementById('charId');
  return el && el.value ? String(el.value).trim() : '';
}

function saveToStorage() {
  const key = getCharacterKey();
  if (!key || localStorageDisabled) {
    setSaveStatus('unsaved');
    return;
  }
  setSaveStatus('saving');
  try {
    const state = getStateFromForm();
    localStorage.setItem(STORAGE_PREFIX + key, JSON.stringify(state));
    setSaveStatus('saved');
  } catch (e) {
    setSaveStatus('error');
  }
}

function updateLockUI() {
  const input = document.getElementById('charId');
  const btn = document.getElementById('lock-character-btn');
  if (input) input.disabled = !!lockedCharacterKey;
  if (btn) btn.disabled = !!lockedCharacterKey;
  setSaveStatus((lockedCharacterKey && !localStorageDisabled) ? 'saved' : 'unsaved');
}

function setSaveStatus(status) {
  const el = document.getElementById('save-status');
  if (!el) return;
  el.classList.remove('saved', 'unsaved', 'saving', 'error');
  el.classList.add(status);
  /* Do not update text content, because it's meant to look like a physical
   * label, so it shouldn't change. That's why we have the indicator light. */
}

// Trauma response: automatically fills textarea based on class
function updateTraumaResponse() {
  const classInput = document.getElementById('charClass');
  const traumaTextarea = document.getElementById('traumaResponse');
  if (!classInput || !traumaTextarea) return;

  // Mapping of character class to trauma response
  const traumaResponses = {
    teamster: '[+] on panic, 1 per session.',
    android: 'Close friendlies have [-] on fear.',
    marine: 'Panic -> close friendlies roll fear.',
    scientist: 'Sanity fail -> close friendlies +1 stress.',
    suit: 'Rest of party has +1 minimum stress.'
  };

  const characterClass = (classInput.value || '').trim().toLowerCase();

  if (traumaResponses.hasOwnProperty(characterClass)) {
    traumaTextarea.value = traumaResponses[characterClass];
  } else {
    traumaTextarea.value = '';
  }
}

function updateCharacterImage() {
  const input = document.getElementById('imageUrl');
  const img = document.getElementById('character-image');
  if (!input || !img) return;
  const url = (input.value || '').trim();
  if (url) {
    img.src = url;
    img.alt = 'Character image';
    img.style.display = '';
  } else {
    img.removeAttribute('src');
    img.alt = '';
    img.style.display = 'none';
  }
}

function setupCharacterImage() {
  const input = document.getElementById('imageUrl');
  if (!input) return;
  input.addEventListener('input', () => {
    updateCharacterImage();
  });
  input.addEventListener('change', () => {
    updateCharacterImage();
  });
}

function setupPageTitle() {
  const nameEl = document.getElementById('charName');
  if (!nameEl) return;
  nameEl.addEventListener('input', updatePageTitle);
  nameEl.addEventListener('change', updatePageTitle);
}

// Ensure trauma response updates when the class changes
(function setupTraumaAutoFill() {
  const classInput = document.getElementById('charClass');
  if (!classInput) return;
  classInput.addEventListener('input', updateTraumaResponse);
  // Also update immediately in case a value is pre-filled
  updateTraumaResponse();
})();


function loadFromStorage(key) {
  if (!key) return null;
  try {
    const raw = localStorage.getItem(STORAGE_PREFIX + key);
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    return null;
  }
}

// Copy current sheet URL with character key to clipboard.
function setupCopyUrl() {
  const btn = document.getElementById('copyUrl');
  if (!btn) return;
  btn.addEventListener('click', () => {
    const key = getCharacterKeyForDisplay();
    const url = key
      ? `${window.location.origin}${window.location.pathname}?c=${encodeURIComponent(key)}`
      : window.location.href;
    navigator.clipboard.writeText(url).then(() => {}, () => {});
  });
}

// When user types in charId, load that character from localStorage or by fetching the JSON file.
let charIdLoadTimeout = null;
function setupCharIdLoadOnType() {
  const input = document.getElementById('charId');
  if (!input) return;
  input.addEventListener('input', () => {
    if (charIdLoadTimeout) clearTimeout(charIdLoadTimeout);
    charIdLoadTimeout = setTimeout(async () => {
      charIdLoadTimeout = null;
      const key = (input.value || '').trim();
      if (!key || !/^[a-z0-9_-]+$/i.test(key)) return;
      let state = loadFromStorage(key);
      if (!state) {
        try {
          const r = await fetch(`characters/${key}.json`);
          if (r.ok) state = await r.json();
        } catch (e) {
          // No file or network error; leave form as-is.
        }
      }
      if (state) {
        applyStateToForm(state);
        input.value = key;
      }
    }, 350);
  });
}

// Lock: save current form to charId and set locked. Cannot unlock (skeuomorphic: control is one-way).
function setupLockButton() {
  const btn = document.getElementById('lock-character-btn');
  const input = document.getElementById('charId');
  if (!btn || !input) return;
  btn.addEventListener('click', () => {
    if (lockedCharacterKey) return;
    const key = (input.value || '').trim();
    if (!key) return;
    if (!/^[a-z0-9_-]+$/i.test(key)) return;
    lockedCharacterKey = key;
    const url = `${window.location.origin}${window.location.pathname}?c=${encodeURIComponent(key)}`;
    history.replaceState(null, '', url);
    updateLockUI();
    saveToStorage();
  });
}

function updateJournalUI() {
  const ta = document.getElementById('journal');
  const info = document.getElementById('journal-page-info');
  const prevBtn = document.getElementById('journal-prev');
  const nextBtn = document.getElementById('journal-next');
  if (ta) ta.value = journalPages[journalPageIndex] ?? '';
  if (info) info.value = `${journalPageIndex + 1}/${journalPages.length}`;
  if (prevBtn) prevBtn.disabled = journalPageIndex <= 0;
  if (nextBtn) nextBtn.disabled = false;
}

function setupJournalPages() {
  const prevBtn = document.getElementById('journal-prev');
  const nextBtn = document.getElementById('journal-next');
  const ta = document.getElementById('journal');
  if (!ta) return;

  prevBtn?.addEventListener('click', () => {
    if (journalPageIndex <= 0) return;
    journalPages[journalPageIndex] = ta.value;
    journalPageIndex -= 1;
    updateJournalUI();
    saveToStorage();
  });

  nextBtn?.addEventListener('click', () => {
    journalPages[journalPageIndex] = ta.value;
    if (journalPageIndex >= journalPages.length - 1) {
      journalPages.push('');
      journalPageIndex = journalPages.length - 1;
    } else {
      journalPageIndex += 1;
    }
    updateJournalUI();
    saveToStorage();
  });

  ta.addEventListener('input', saveToStorage);
  updateJournalUI();
}

// Bind every editable field so changes update state and persist to localStorage.
function bindPersist() {
  const persist = () => saveToStorage();

  const inputs = document.querySelectorAll(
    '.sheet-layout input:not([type="button"]):not([type="submit"]), .sheet-layout textarea'
  );
  inputs.forEach((el) => {
    el.addEventListener('input', persist);
    el.addEventListener('change', persist);
  });

  document.querySelectorAll('.sheet-layout input[type="checkbox"]').forEach((el) => {
    el.addEventListener('change', persist);
  });
}

function setPrintLoadMessage(text) {
  const el = document.getElementById('print-load-msg');
  if (el) el.value = text || '';
}

function setupPrintLoadButtons() {
  const printBtn = document.getElementById('print-json-btn');
  const loadBtn = document.getElementById('load-json-btn');
  const clearBtn = document.getElementById('clear-json-btn');
  const modal = document.getElementById('load-modal');
  const loadInput = document.getElementById('load-json-input');
  const modalCancel = document.getElementById('load-modal-cancel');
  const modalSubmit = document.getElementById('load-modal-submit');
  const backdrop = modal?.querySelector('.load-modal-backdrop');

  if (printBtn) {
    printBtn.addEventListener('click', () => {
      const key = getCharacterKeyForDisplay();
      if (!key) {
        setPrintLoadMessage('Enter or lock a character ID first.');
        return;
      }
      const state = getStateFromForm();
      state.charId = key;
      try {
        const json = JSON.stringify(state, null, 2);
        navigator.clipboard.writeText(json).then(
          () => setPrintLoadMessage('Copied to clipboard.'),
          () => setPrintLoadMessage('Clipboard copy failed.')
        );
      } catch (e) {
        setPrintLoadMessage('Failed to serialize state.');
      }
    });
  }

  if (clearBtn) {
    clearBtn.addEventListener('click', async () => {
      const charKey = getCharacterKeyForDisplay();
      if (charKey) localStorage.removeItem(STORAGE_PREFIX + charKey);

      let state = null;

      let reloadedFromFetch = false;
      if (charKey) {
        try {
          const r = await fetch(`characters/${charKey}.json`);
          if (r.ok) {
            const fetched = await r.json();
            if (fetched && typeof fetched === 'object') {
              state = fetched;
              reloadedFromFetch = true;
            }
          }
        } catch (e) {
          // No static file or network error; keep state null.
        }
      }

      // If no state fetched, create an empty one (with charKey if it exists) to force overwrite.
      if (!state) state = emptyState(charKey);
      applyStateToForm(state);
      const el = document.getElementById('charId');
      if (el) el.value = charKey;
      lockedCharacterKey = charKey;
      updateLockUI();

      setPrintLoadMessage(reloadedFromFetch ? 'Reset character.' : 'Cleared character.');
    });
  }

  function openLoadModal() {
    if (modal && loadInput) {
      loadInput.value = '';
      modal.setAttribute('data-open', 'true');
      loadInput.focus();
    }
  }

  function closeLoadModal() {
    if (modal) modal.removeAttribute('data-open');
  }

  if (loadBtn) loadBtn.addEventListener('click', openLoadModal);
  if (modalCancel) modalCancel.addEventListener('click', closeLoadModal);
  if (backdrop) backdrop.addEventListener('click', closeLoadModal);

  if (modalSubmit && loadInput) {
    modalSubmit.addEventListener('click', () => {
      let state;
      try {
        state = JSON.parse(loadInput.value);
      } catch (e) {
        setPrintLoadMessage('Invalid JSON.');
        return;
      }
      if (!state || typeof state !== 'object') {
        setPrintLoadMessage('Invalid JSON.');
        return;
      }
      const charId = state.charId;
      if (!charId || typeof charId !== 'string' || !/^[a-z0-9_-]+$/i.test(charId.trim())) {
        setPrintLoadMessage('Valid character ID (charId) required in JSON.');
        return;
      }
      const key = charId.trim();
      try {
        localStorage.setItem(STORAGE_PREFIX + key, JSON.stringify(state));
      } catch (e) {
        setPrintLoadMessage('Failed to save to storage.');
        return;
      }
      applyStateToForm(state);
      const charIdEl = document.getElementById('charId');
      if (charIdEl) charIdEl.value = key;
      lockedCharacterKey = key;
      updateLockUI();
      const url = `${window.location.origin}${window.location.pathname}?c=${encodeURIComponent(key)}`;
      history.replaceState(null, '', url);
      setPrintLoadMessage(`Loaded character "${key}".`);
      closeLoadModal();
    });
  }
}

// Load character: only when ?c= is set. Otherwise charId starts empty; user types to load or lock to save.
async function setup() {
  const urlParams = new URLSearchParams(window.location.search);
  const charKey = urlParams.get('c');
  const localKey = urlParams.get('local');
  if (localKey === 'false' || localKey === '0') { // localKey tells us to ignore local storage
    localStorageDisabled = true;
  }

  setupCopyUrl();
  setupCharIdLoadOnType();
  setupLockButton();
  setupPrintLoadButtons();
  setupCharacterImage();
  setupPageTitle();
  bindPersist();
  setupJournalPages();
  updateLockUI();

  if (!charKey || !/^[a-z0-9_-]+$/i.test(charKey)) {
    setSaveStatus('unsaved');
    applyStateToForm(emptyState(null));
    return;
  }

  let state = localStorageDisabled ? null : loadFromStorage(charKey);

  if (!state) {
    try {
      const r = await fetch(`characters/${charKey}.json`);
      if (r.ok) state = await r.json();
    } catch (e) {
      // No static file or network error; keep state null.
    }
  }

  if (!state) state = emptyState(charKey);

  applyStateToForm(state);
  const el = document.getElementById('charId');
  if (el) el.value = charKey;
  lockedCharacterKey = charKey;
  updateLockUI();
}

// ---- Number increment/decrement buttons (wedge buttons next to Cur/Max cells) ----
function setupNumButtons() {
  document.querySelectorAll('.num-btn-inc').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-target');
      const input = document.getElementById(id);
      if (input && input.type === 'number') {
        input.stepUp();
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });
  });
  document.querySelectorAll('.num-btn-dec').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-target');
      const input = document.getElementById(id);
      if (input && input.type === 'number') {
        input.stepDown();
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });
  });
}

// ---- Dice rolls: two d10 (0–9), one panic (1–20) ----
function triggerPanicFlash() {
  const el = document.getElementById('panic-flash');
  if (!el) return;
  el.classList.remove('panic-flash--show');
  el.offsetHeight; // reflow so animation can run again
  el.classList.add('panic-flash--show');
  const onEnd = () => {
    el.removeEventListener('animationend', onEnd);
    el.classList.remove('panic-flash--show');
  };
  el.addEventListener('animationend', onEnd);
}

function setupDiceRolls() {
  document.querySelectorAll('.die-roll-cell').forEach((cell) => {
    const input = cell.querySelector('.die-roll-input');
    const rollBtn = cell.querySelector('.num-btn-roll');
    const resetBtn = cell.querySelector('.num-btn-reset');
    if (!input || !rollBtn || !resetBtn) return;

    const isPanic = cell.classList.contains('die-roll-cell-panic');

    rollBtn.addEventListener('click', () => {
      if (isPanic) {
        input.value = String(Math.floor(Math.random() * 20) + 1);
        if (Math.random() < 0.05) triggerPanicFlash();
      } else {
        input.value = String(Math.floor(Math.random() * 10));
      }
    });

    resetBtn.addEventListener('click', () => {
      input.value = '';
    });
  });
}

// Credits +/- buttons with step (1, 10, 100, 1000), allow negative credit values
function setupCreditsButtons() {
  document.querySelectorAll('.num-btn-plus, .num-btn-minus').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-target');
      const delta = parseInt(btn.getAttribute('data-delta'), 10);
      const input = document.getElementById(id);
      if (!input || input.type !== 'number') return;
      const cur = parseInt(input.value || '0', 10) || 0;
      const next = cur + delta; // allow negative numbers
      input.value = String(next);
      input.dispatchEvent(new Event('input', { bubbles: true }));
    });
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    setupNumButtons();
    setupCreditsButtons();
    setupDiceRolls();
    setup();
  });
} else {
  setupNumButtons();
  setupCreditsButtons();
  setupDiceRolls();
  setup();
}
