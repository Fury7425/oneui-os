document.querySelectorAll('[data-apps]').forEach(el => {
  const items = el.dataset.apps.split(' ').map(t => t.split(':'));
  const labelled = el.closest('.finder, .drawer');
  const html = items.map(([k, st = ''], n) => {
    const i = icon(k, st === 'cur' ? 'run cur' : st);
    return labelled ? `<div class="tile" style="--i:${n}">${i}<span>${APPS[k][0]}</span></div>` : i;
  }).join('');
  if (labelled) el.innerHTML = html; else el.outerHTML = html;
});

document.querySelector('[data-recent]').innerHTML = document.querySelector('[data-recent]').dataset.recent.split('|')
  .map(t => `<span class="chip">${t}<span class="x"><svg class="ico" viewBox="0 0 24 24"><path d="M7 7l10 10M17 7L7 17"/></svg></span></span>`).join('');

// DeX window controls: minimise, maximise, full screen, close
const CTL = ['<path d="M6 12h12"/>', '<path d="M14 4h6v6M10 20H4v-6M20 4l-6.5 6.5M4 20l6.5-6.5"/>', '<path d="M4 9V4h5M15 4h5v5M20 15v5h-5M9 20H4v-5"/>', '<path d="M7 7l10 10M17 7L7 17"/>'];
document.querySelectorAll('[data-ctls]').forEach(el => el.innerHTML = CTL.map((p, i) =>
  `<span class="c${i === 3 ? ' close' : ''}"><svg class="ico" viewBox="0 0 24 24">${p}</svg></span>`).join(''));

// notifications (pill stack, newest first)
const N = [
  ['share',    'Quick Share',     'now', '3 photos from Galaxy S26 Ultra', '<i class="thumb" style="background:oklch(0.7 0.09 40)"></i>'],
  ['messages', 'Mina',            '2m',  'Are we still on for 7?', '<span class="count">3</span>'],
  ['update',   'Galaxy Update',   '12m', 'Kernel 6.17.3 installs on restart', '<span class="count">2</span>'],
  ['recorder', 'Screenshot saved','18m', 'Tap to view or edit', '<i class="thumb" style="background:oklch(0.62 0.05 260)"></i>'],
  ['cloud',    'Samsung Cloud',   '1h',  'Backup complete · 2.1 GB', ''],
  ['ai',       'Do not disturb',  '',    'On until 10:00', '<svg class="ico" viewBox="0 0 24 24" style="color:var(--ink-2)"><path d="M7 10l5 5 5-5"/></svg>'],
];
document.querySelector('[data-notifs]').innerHTML = N.map(([k, t, w, b, end]) =>
  `<div class="notif glass">${icon(k)}<div><div class="h"><b>${t}</b><time>${w}</time></div><p>${b}</p></div>${end}</div>`).join('') +
  `<div class="nfoot"><span class="btn">Notification settings</span><span class="btn">Clear</span></div>`;

// terminal right pane: a btop-style monitor
const CPU = [23, 41, 12, 67, 8, 35, 19, 54];
document.querySelector('[data-mon]').innerHTML = '<div class="h">btop · 8 cores · 3.1 GHz</div>' +
  CPU.map((v, i) => `<div class="bar">cpu${i}<u style="--v:${v}%"></u><em>${v}%</em></div>`).join('') +
  '<div class="bar">mem <u style="--v:16%"></u><em>5.2G</em></div><div class="bar">swap<u style="--v:2%"></u><em>0.1G</em></div>' +
  '<div class="procs"><b>pid</b><b>name</b><b>cpu</b><b>mem</b>' +
  [['1204', 'one-shell', '6.1', '412M'], ['2210', 'settings', '2.4', '188M'], ['2391', 'quickshare', '1.2', '96M']].map(r => r.map(c => `<span>${c}</span>`).join('')).join('') + '</div>';

// params
const q = new URLSearchParams(location.search);
const theme = q.get('theme') === 'dark' ? 'dark' : 'light';
const view = ['desktop', 'finder', 'drawer', 'notifs', 'overview'].includes(q.get('view')) ? q.get('view') : 'desktop';
document.documentElement.dataset.theme = theme;
document.documentElement.dataset.view = view;
// scale: 2880×1800 panel ÷ UI scale = logical canvas (150% → 1920×1200)
const scale = [1.5, 1.75, 2].includes(+q.get('scale')) ? +q.get('scale') : 1.5;
const W = Math.round(2880 / scale), H = Math.round(1800 / scale);
document.documentElement.style.setProperty('--W', W + 'px');
document.documentElement.style.setProperty('--H', H + 'px');
document.querySelector('.scale-name').textContent = scale;
document.querySelector('.theme-name').textContent = theme === 'dark' ? 'Dark' : 'Light';
document.querySelectorAll('[data-for]').forEach(el => el.classList.toggle('on', el.dataset.for === view));

// overview: live copy of the current desktop's windows, scaled into the frame
if (view === 'overview') {
  const stage = document.querySelector('[data-stage]');
  stage.innerHTML = document.querySelector('.wall').outerHTML;
  stage.appendChild(document.querySelector('.tiles').cloneNode(true));
}

// fit the logical canvas to any window; headless render at W×H with device scale = exact 2880×1800
const s = document.getElementById('screen');
const fit = () => s.style.transform = `scale(${Math.min(innerWidth / W, innerHeight / H)})`;
addEventListener('resize', fit); fit();
