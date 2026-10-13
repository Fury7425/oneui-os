// One icon registry, used by taskbar, finder and app drawer.
const S = (d, extra = '') => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" ${extra}>${d}</svg>`;
const F = d => `<svg viewBox="0 0 24 24" fill="currentColor">${d}</svg>`;
const APPS = {
  account:   ['Account',      'oklch(0.55 0.18 258)', S('<circle cx="12" cy="9" r="3.5"/><path d="M5.5 19.5a7 7 0 0113 0"/>')],
  ai:        ['Galaxy AI',    'oklch(0.58 0.19 275)', F('<path d="M10 3l1.8 5.2L17 10l-5.2 1.8L10 17l-1.8-5.2L3 10l5.2-1.8zM18 14l.9 2.1L21 17l-2.1.9L18 20l-.9-2.1L15 17l2.1-.9z"/>')],
  calculator:['Calculator',   'oklch(0.3 0.01 285)',  S('<path d="M7 7h4M9 5v4M14 7h4M7 15l3 3M10 15l-3 3M14 15h4M14 18h4"/>'), 'dark-bg'],
  calendar:  ['Calendar',     '#fff',                 `<svg viewBox="0 0 24 24"><rect x="5" y="3.5" width="14" height="2.4" rx="1.2" fill="oklch(0.68 0.15 150)"/><text x="12" y="18" text-anchor="middle" font-family="One, sans-serif" font-weight="700" font-size="11.5" fill="oklch(0.22 0.01 285)">12</text></svg>`, 'light'],
  camera:    ['Camera',       '#fff',                 `<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="7" fill="oklch(0.22 0.01 285)"/><circle cx="12" cy="12" r="3" fill="oklch(0.45 0.05 260)"/><circle cx="18" cy="5.5" r="1.3" fill="oklch(0.63 0.21 15)"/></svg>`, 'light'],
  camshare:  ['Camera Share', 'oklch(0.58 0.2 288)',  S('<rect x="3" y="7" width="13" height="10" rx="2"/><path d="M16 10.5l5-3v9l-5-3"/>')],
  care:      ['Device Care',  'oklch(0.66 0.12 200)', S('<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0112 7.5 4.3 4.3 0 0119.5 10c0 5.4-7.5 10-7.5 10z"/><path d="M8 12h2l1.2-2 1.6 4 1.2-2h2"/>')],
  clock:     ['Clock',        '#fff',                 `<svg viewBox="0 0 24 24" fill="none" stroke-linecap="round"><circle cx="12" cy="12" r="8" stroke="oklch(0.22 0.01 285)" stroke-width="1.8"/><path d="M12 7.5V12l3.5 2" stroke="oklch(0.55 0.2 280)" stroke-width="2"/></svg>`, 'light'],
  cloud:     ['Samsung Cloud','oklch(0.62 0.14 240)', F('<path d="M7 18.5a4.5 4.5 0 01-.6-9A6.5 6.5 0 0119 10.5a4 4 0 01-1 8z"/>')],
  contacts:  ['Contacts',     'oklch(0.62 0.2 30)',   F('<circle cx="12" cy="9" r="3.6"/><path d="M5 19.5a7 7 0 0114 0z"/>')],
  files:     ['My Files',     'oklch(0.78 0.16 70)',  F('<path d="M3 7a2.5 2.5 0 012.5-2.5H10l2 2.5h6.5A2.5 2.5 0 0121 9.5v8a2.5 2.5 0 01-2.5 2.5h-13A2.5 2.5 0 013 17.5z"/>')],
  gallery:   ['Gallery',      'oklch(0.63 0.21 15)',  F('<circle cx="12" cy="7.5" r="3.3"/><circle cx="7.6" cy="12.6" r="3.3" opacity=".85"/><circle cx="16.4" cy="12.6" r="3.3" opacity=".85"/><circle cx="12" cy="16.8" r="3.3" opacity=".7"/>')],
  health:    ['Health',       'oklch(0.68 0.14 175)', F('<circle cx="13" cy="5.5" r="2.2"/><path d="M9 21l2-6-3-2 2.5-4.5 4 2.5 3 .5-.5 2-3.5-.5-1 3 2 2.5V21h-2v-2.5l-1.5-1.5L11 21z"/>')],
  internet:  ['Internet',     'oklch(0.55 0.2 280)',  S('<circle cx="12" cy="12" r="7.5"/><ellipse cx="12" cy="12" rx="11" ry="3.8" transform="rotate(-25 12 12)"/>')],
  knox:      ['Knox',         'oklch(0.42 0.1 260)',  S('<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8-7.5 9.5-4.3-1.5-7.5-4.9-7.5-9.5V6z"/><path d="M9 12l2 2 4-4"/>')],
  messages:  ['Messages',     'oklch(0.63 0.17 250)', F('<path d="M12 4.5c4.7 0 8.5 3.1 8.5 7s-3.8 7-8.5 7c-.9 0-1.8-.1-2.7-.4L5.5 19.5l1.1-3.1C5 15.1 3.5 13.4 3.5 11.5c0-3.9 3.8-7 8.5-7z"/>')],
  music:     ['Music',        'oklch(0.62 0.17 300)', F('<path d="M9 17.5V6l11-2.5V15h-2V7.5l-7 1.6v8.4z"/><circle cx="6.5" cy="17.5" r="2.8"/><circle cx="17.5" cy="15" r="2.8"/>')],
  notes:     ['Notes',        'oklch(0.62 0.2 28)',   F('<path d="M6 3.5h9.5L20 8v10.5a2 2 0 01-2 2H6a2 2 0 01-2-2v-13a2 2 0 012-2z"/><path d="M15.5 3.5V8H20" fill="oklch(1 0 0 / .45)"/>')],
  phone:     ['Phone',        'oklch(0.66 0.17 148)', F('<path d="M7.5 3.5l2.5 4-1.8 1.8a11 11 0 006.5 6.5l1.8-1.8 4 2.5-1 3.3c-.3.8-1.1 1.2-2 1A16 16 0 013.2 7.5c-.2-.9.2-1.7 1-2z"/>')],
  recorder:  ['Voice Recorder','oklch(0.6 0.21 25)',  S('<path d="M4 12h1M7 9v6M10 6v12M13 9v6M16 7v10M19 11v2"/>')],
  settings:  ['Settings',     'oklch(0.52 0.015 270)',S('<circle cx="12" cy="12" r="3"/><path d="M12 2.5l1.6 2.6 3-.6.6 3 2.6 1.6-1.4 2.9 1.4 2.9-2.6 1.6-.6 3-3-.6L12 21.5l-1.6-2.6-3 .6-.6-3-2.6-1.6 1.4-2.9-1.4-2.9 2.6-1.6.6-3 3 .6z"/>')],
  share:     ['Quick Share',  'oklch(0.68 0.13 230)', S('<circle cx="12" cy="12" r="8.5"/><path d="M8.5 10.5h7l-2.5-2.5M15.5 13.5h-7l2.5 2.5"/>')],
  store:     ['Galaxy Store', 'oklch(0.62 0.21 0)',   F('<path d="M5.5 8.5h13l-1 10.5a2 2 0 01-2 1.8h-7a2 2 0 01-2-1.8z"/><path d="M9 8.5V7a3 3 0 016 0v1.5" fill="none" stroke="currentColor" stroke-width="1.8"/>')],
  terminal:  ['Terminal',     'oklch(0.24 0.012 285)',S('<path d="M5 16l5-4-5-4M12 17h7"/>'), 'dark-bg'],
  things:    ['SmartThings',  'oklch(0.66 0.12 215)', F('<circle cx="12" cy="6" r="2.4"/><circle cx="6" cy="12" r="2.4"/><circle cx="18" cy="12" r="2.4"/><circle cx="12" cy="18" r="2.4"/>')],
  update:    ['Galaxy Update','oklch(0.66 0.17 148)', S('<path d="M20 12a8 8 0 11-2.6-5.9M20 4v4.5h-4.5"/>')],
  wallet:    ['Wallet',       'oklch(0.26 0.01 285)', F('<rect x="3" y="6" width="18" height="13" rx="3"/><rect x="5" y="3.5" width="12" height="4" rx="1.5" opacity=".55"/>'), 'dark-bg'],
  weather:   ['Weather',      'oklch(0.7 0.12 235)',  F('<circle cx="9" cy="9" r="4" fill="oklch(0.9 0.14 90)"/><path d="M8 19.5h9a4 4 0 00.5-8 5.5 5.5 0 00-10.6 1.5A3.3 3.3 0 008 19.5z"/>')],
  video:     ['Video Player', 'oklch(0.58 0.2 288)',  F('<path d="M8 5.5l11 6.5-11 6.5z"/>')],
};
const icon = (key, cls = '') => { const [, bg, svg, x = ''] = APPS[key]; return `<span class="app ${x} ${cls}" style="background:${bg}">${svg}</span>`; };

