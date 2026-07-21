const STORAGE_KEY = "homeschool-hub-static-v1";

const DEFAULT_STATE = {
  childName: "Ananda",
  dark: false,
  tasks: [
    { id: 1, area: "Aqidah & Adab", task: "Murojaah doa harian dan diskusi adab meminta izin", done: true, icon: "moon" },
    { id: 2, area: "Literasi", task: "Membaca 20 menit lalu cerita ulang", done: true, icon: "book" },
    { id: 3, area: "Numerasi", task: "Latihan menghitung uang belanja", done: false, icon: "wallet" },
    { id: 4, area: "Life Skills", task: "Membantu menyapu, merapikan tempat tidur, atau mencuci piring", done: false, icon: "home" },
    { id: 5, area: "Sosial", task: "Menyapa tetangga dan latihan percakapan sopan", done: false, icon: "users" }
  ],
  skills: [
    { id: 1, name: "Merapikan tempat tidur", level: 80, category: "Mandiri" },
    { id: 2, name: "Membaca mandiri", level: 65, category: "Literasi" },
    { id: 3, name: "Bernegosiasi sederhana", level: 45, category: "Sosial" },
    { id: 4, name: "Mengelola uang jajan", level: 35, category: "Numerasi" },
    { id: 5, name: "Membantu memasak", level: 55, category: "Life Skills" }
  ],
  portfolio: [
    { id: 1, title: "Video presentasi: Kenapa harus jujur?", type: "Adab", date: "Hari ini" },
    { id: 2, title: "Foto proyek: Menanam kacang hijau", type: "Sains", date: "Kemarin" },
    { id: 3, title: "Catatan membaca: Kisah Nabi", type: "Literasi", date: "2 hari lalu" }
  ]
};

const MISSIONS = [
  "Menanamkan aqidah yang lurus berdasarkan Al-Qur'an dan Sunnah sejak usia dini.",
  "Membiasakan ibadah, adab, dan akhlak mulia dalam kehidupan sehari-hari.",
  "Menumbuhkan kecintaan terhadap ilmu serta semangat belajar sepanjang hayat.",
  "Mengembangkan kemampuan berpikir kritis, kreatif, dan mampu menyelesaikan masalah.",
  "Membekali anak dengan berbagai keterampilan hidup sesuai usia.",
  "Memberikan pendidikan fleksibel sesuai minat, bakat, dan perkembangan anak.",
  "Menciptakan lingkungan belajar yang aman, menyenangkan, dan penuh kasih sayang.",
  "Mempersiapkan anak menjadi pribadi mandiri, bertanggung jawab, adaptif, tanpa meninggalkan nilai Islam."
];

const VALUES = [
  ["Iman dan Islam", "Al-Qur'an dan Sunnah sebagai pedoman hidup."],
  ["Kebermanfaatan", "Bermanfaat bagi agama, keluarga, masyarakat, dan lingkungan."],
  ["Tanggung Jawab", "Menyelesaikan amanah dengan sungguh-sungguh."],
  ["Jujur dan Amanah", "Berkata benar, dapat dipercaya, dan menjaga komitmen."],
  ["Rasa Ingin Tahu", "Senang belajar, bertanya, mencoba, dan berkembang."]
];

const WEEK_PLAN = [
  { day: "Senin", focus: "Aqidah, literasi, numerasi", vibe: "Fondasi" },
  { day: "Selasa", focus: "Eksperimen sains dan life skills", vibe: "Eksplorasi" },
  { day: "Rabu", focus: "Kunjungan lingkungan/pasar", vibe: "Dunia nyata" },
  { day: "Kamis", focus: "Seni, kreativitas, proyek minat", vibe: "Kreasi" },
  { day: "Jumat", focus: "Ibadah, adab, berbagi", vibe: "Karakter" },
  { day: "Sabtu", focus: "Olahraga dan sosial keluarga", vibe: "Komunitas" },
  { day: "Ahad", focus: "Refleksi dan quality time", vibe: "Tenang" }
];

let state = loadState();
let currentTab = "home";
let deferredPrompt = null;

function icon(name) {
  const map = {
    home: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m3 11 9-8 9 8"/><path d="M5 10v10h14V10"/></svg>',
    book: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M4 4v15.5"/><path d="M20 22V6a2 2 0 0 0-2-2H6.5A2.5 2.5 0 0 0 4 6.5"/></svg>',
    users: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
    moon: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9"/></svg>',
    sun: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/></svg>',
    wifi: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 13a10 10 0 0 1 14 0"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M12 20h.01"/></svg>',
    wifioff: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m2 2 20 20"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M5 13a10 10 0 0 1 5.24-2.76"/><path d="M19 13a10 10 0 0 0-2.97-2.11"/><path d="M12 20h.01"/></svg>',
    check: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 6 9 17l-5-5"/></svg>',
    plus: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>',
    trash: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
    wallet: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 12V8H6a2 2 0 0 1 0-4h12v4"/><path d="M4 6v14h16v-4"/><path d="M18 12h4v4h-4a2 2 0 0 1 0-4Z"/></svg>',
    trophy: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M8 21h8"/><path d="M12 17v4"/><path d="M7 4h10v7a5 5 0 0 1-10 0Z"/><path d="M5 9a2 2 0 0 1-2-2V5h4"/><path d="M19 9a2 2 0 0 0 2-2V5h-4"/></svg>',
    target: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>',
    settings: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>',
    download: '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="M7 10l5 5 5-5"/><path d="M12 15V3"/></svg>'
  };
  return map[name] || map.target;
}

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : structuredClone(DEFAULT_STATE);
  } catch {
    return JSON.parse(JSON.stringify(DEFAULT_STATE));
  }
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function averageSkill() {
  return Math.round(state.skills.reduce((sum, skill) => sum + skill.level, 0) / state.skills.length);
}

function completedCount() {
  return state.tasks.filter((task) => task.done).length;
}

function progressToday() {
  return Math.round((completedCount() / Math.max(state.tasks.length, 1)) * 100);
}

function render() {
  document.body.classList.toggle("dark", !!state.dark);
  const app = document.getElementById("app");
  app.innerHTML = `
    <div class="app-shell">
      ${renderHeader()}
      <main class="container">
        ${renderHome()}
        ${renderVision()}
        ${renderRoutine()}
        ${renderSkills()}
        ${renderPortfolio()}
        ${renderSettings()}
      </main>
      ${renderBottomNav()}
      ${renderAddModal()}
    </div>
  `;
  bindEvents();
  updateOnlineBadge();
}

function renderHeader() {
  return `
    <header class="topbar">
      <div class="topbar-inner">
        <div class="brand">
          <div class="logo">⌂</div>
          <div>
            <p class="kicker">Offline First PWA</p>
            <h1>HomeSchool Hub</h1>
          </div>
        </div>
        <div class="actions">
          <div id="onlineBadge" class="badge">${icon("wifi")} Online</div>
          <button id="installBtn" class="btn small" style="display:none">${icon("download")} <span>Install</span></button>
          <button id="themeBtn" class="icon-btn" aria-label="Toggle mode">${state.dark ? icon("sun") : icon("moon")}</button>
        </div>
      </div>
    </header>
  `;
}

function renderHome() {
  const done = completedCount();
  const progress = progressToday();
  return `
    <section id="home" class="section ${currentTab === "home" ? "active" : ""}">
      <div class="stack">
        <div class="hero">
          <div class="hero-content">
            <div class="greeting-row">
              <div>
                <p>Assalamu'alaikum, keluarga pembelajar</p>
                <h2>Hari ini ${escapeHtml(state.childName)} sudah menyelesaikan ${done} aktivitas.</h2>
              </div>
              <div id="mobileOnlineBadge" class="badge" style="display:flex"></div>
            </div>
            <div class="progress-card">
              <div class="progress-head"><span>Progress hari ini</span><span class="progress-number">${progress}%</span></div>
              <div class="progress-track"><div class="progress-fill" style="width:${progress}%"></div></div>
              <p class="progress-note">Data checklist tersimpan otomatis di perangkat ini dan tetap bisa dibuka saat offline.</p>
            </div>
          </div>
        </div>

        <div class="grid-stats">
          ${statCard("check", "Tugas selesai", `${done}/${state.tasks.length}`, "green")}
          ${statCard("book", "Literasi", "20m", "blue")}
          ${statCard("users", "Sosial pekanan", "3x", "purple")}
          ${statCard("trophy", "Rata skill", `${averageSkill()}%`, "amber")}
        </div>

        <div class="card">
          <div class="card-content">
            <div class="card-title-row">
              <div><h3>Aktivitas Hari Ini</h3><p>Checklist bisa dipakai tanpa internet.</p></div>
              <button id="openAddModal" class="btn small">${icon("plus")}</button>
            </div>
            <div class="task-list">
              ${state.tasks.map(renderTask).join("")}
            </div>
          </div>
        </div>
      </div>
    </section>
  `;
}

function statCard(ic, label, value, tone) {
  return `
    <div class="card">
      <div class="card-content">
        <div class="stat-icon ${tone}">${icon(ic)}</div>
        <p class="stat-label">${label}</p>
        <p class="stat-value">${value}</p>
      </div>
    </div>
  `;
}

function renderTask(task) {
  return `
    <div class="task-item ${task.done ? "done" : ""}">
      <button class="check-btn ${task.done ? "done" : ""}" data-toggle-task="${task.id}">${task.done ? icon("check") : icon(task.icon)}</button>
      <div class="task-main">
        <strong>${escapeHtml(task.area)}</strong>
        <p>${escapeHtml(task.task)}</p>
      </div>
      <button class="delete-btn" data-delete-task="${task.id}" aria-label="Hapus aktivitas">${icon("trash")}</button>
    </div>
  `;
}

function renderVision() {
  return `
    <section id="vision" class="section ${currentTab === "vision" ? "active" : ""}">
      <div class="stack">
        <div class="card"><div class="card-content">
          <p class="kicker">Visi Homeschooling Keluarga</p>
          <h2 class="vision-title">Mencetak generasi yang taat beragama, beraqidah lurus, berakhlak mulia, memiliki berbagai keterampilan hidup, serta mampu beradaptasi dan memberikan manfaat di mana pun berada.</h2>
          <div class="note-box">Prinsip: bukan menjauhkan anak dari dunia, tetapi mempersiapkan anak menghadapi dunia dengan iman, ilmu, adab, keterampilan, dan ketahanan diri.</div>
        </div></div>
        <div class="card"><div class="card-content">
          <h3>Misi Pendidikan</h3>
          <div class="mission-list" style="margin-top:14px">
            ${MISSIONS.map((m, i) => `<div class="mission-item"><span class="number">${i + 1}</span><p>${escapeHtml(m)}</p></div>`).join("")}
          </div>
        </div></div>
        <div class="card"><div class="card-content">
          <h3>Nilai Utama Keluarga</h3>
          <div class="value-grid" style="margin-top:14px">
            ${VALUES.map(([title, desc]) => `<div class="value-item"><strong>${escapeHtml(title)}</strong><p style="color:var(--muted); margin:6px 0 0; font-size:14px; line-height:1.45">${escapeHtml(desc)}</p></div>`).join("")}
          </div>
        </div></div>
      </div>
    </section>
  `;
}

function renderRoutine() {
  return `
    <section id="routine" class="section ${currentTab === "routine" ? "active" : ""}">
      <div class="card"><div class="card-content">
        <h3>Ritme Pekanan</h3>
        <p style="color:var(--muted); margin:8px 0 18px; font-size:14px">Mobile first, ringan, fleksibel, dan realistis untuk keluarga.</p>
        <div class="week-grid">
          ${WEEK_PLAN.map((d) => `<div class="week-item"><div class="week-item-head"><h4>${d.day}</h4><span class="pill">${d.vibe}</span></div><p>${d.focus}</p></div>`).join("")}
        </div>
      </div></div>
    </section>
  `;
}

function renderSkills() {
  return `
    <section id="skills" class="section ${currentTab === "skills" ? "active" : ""}">
      <div class="stack">
        <div class="card"><div class="card-content">
          <h3>Perkembangan Life Skills</h3>
          <div class="skill-list" style="margin-top:16px">
            ${state.skills.map((s) => `<div class="skill-item"><div class="skill-head"><div><strong>${escapeHtml(s.name)}</strong><small>${escapeHtml(s.category)}</small></div><span class="skill-percent">${s.level}%</span></div><div class="progress-track" style="background:rgba(148,163,184,.2)"><div class="progress-fill" style="background:linear-gradient(90deg,#10b981,#14b8a6); width:${s.level}%"></div></div></div>`).join("")}
          </div>
        </div></div>
        <div class="card"><div class="card-content">
          <h3>Latihan Negosiasi</h3>
          <div class="mission-list" style="margin-top:14px">
            ${["Membedakan kebutuhan dan keinginan", "Menyampaikan alasan dengan sopan", "Mendengar pendapat orang lain", "Mencari solusi yang adil", "Menerima batasan keluarga"].map((x) => `<div class="mission-item"><span style="color:var(--emerald)">${icon("check")}</span><p>${x}</p></div>`).join("")}
          </div>
        </div></div>
      </div>
    </section>
  `;
}

function renderPortfolio() {
  return `
    <section id="portfolio" class="section ${currentTab === "portfolio" ? "active" : ""}">
      <div class="card"><div class="card-content">
        <div class="card-title-row"><div><h3>Portofolio Belajar</h3><p>Bukti perkembangan anak: foto, video, tulisan, proyek, dan refleksi.</p></div><button class="btn small">${icon("plus")}</button></div>
        <div class="portfolio-grid">
          ${state.portfolio.map((p) => `<div class="portfolio-item"><span class="pill">${escapeHtml(p.type)}</span><h4 style="margin:16px 0 0; font-size:16px">${escapeHtml(p.title)}</h4><p style="color:var(--muted); margin:8px 0 0; font-size:14px">${escapeHtml(p.date)}</p></div>`).join("")}
        </div>
      </div></div>
    </section>
  `;
}

function renderSettings() {
  return `
    <section id="settings" class="section ${currentTab === "settings" ? "active" : ""}">
      <div class="card"><div class="card-content setting-card">
        <h3>Pengaturan Offline</h3>
        <div class="task-item" style="display:block">
          <p class="setting-label">Nama anak</p>
          <input id="childNameInput" class="form-control" value="${escapeAttr(state.childName)}" />
        </div>
        <div class="info-grid">
          <div class="info-box"><strong>${icon("wifioff")} Offline Data</strong><p>Checklist dan pengaturan disimpan di localStorage perangkat.</p></div>
          <div class="info-box blue"><strong>${icon("download")} Installable</strong><p>Manifest dan service worker sudah disiapkan. Bisa deploy langsung ke Vercel tanpa build.</p></div>
        </div>
        <button id="resetBtn" class="btn danger">${icon("trash")} Reset Data Demo</button>
      </div></div>
    </section>
  `;
}

function renderBottomNav() {
  const tabs = [
    ["home", "home", "Home"],
    ["vision", "target", "Visi"],
    ["routine", "book", "Ritme"],
    ["skills", "check", "Skill"],
    ["portfolio", "users", "Porto"],
    ["settings", "settings", "Set"]
  ];
  return `<nav class="bottom-nav"><div class="bottom-nav-inner">${tabs.map(([key, ic, label]) => `<button class="tab-btn ${currentTab === key ? "active" : ""}" data-tab="${key}"><span class="tab-icon">${icon(ic)}</span>${label}</button>`).join("")}</div></nav>`;
}

function renderAddModal() {
  return `
    <div id="addModal" class="modal">
      <div class="modal-panel">
        <div class="modal-head"><h3>Tambah Aktivitas</h3><button id="closeAddModal" class="close-btn">×</button></div>
        <div class="form-grid">
          <input id="newArea" class="form-control" placeholder="Area, contoh: Adab" value="Life Skills" />
          <textarea id="newTask" class="form-control" rows="4" placeholder="Aktivitas yang ingin dilakukan"></textarea>
          <button id="saveTaskBtn" class="btn">${icon("plus")} Simpan Aktivitas</button>
        </div>
      </div>
    </div>
  `;
}

function bindEvents() {
  document.querySelectorAll("[data-tab]").forEach((btn) => {
    btn.addEventListener("click", () => {
      currentTab = btn.dataset.tab;
      render();
    });
  });

  document.getElementById("themeBtn")?.addEventListener("click", () => {
    state.dark = !state.dark;
    saveState();
    render();
  });

  document.getElementById("installBtn")?.addEventListener("click", async () => {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    await deferredPrompt.userChoice;
    deferredPrompt = null;
    render();
  });

  document.querySelectorAll("[data-toggle-task]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = Number(btn.dataset.toggleTask);
      state.tasks = state.tasks.map((task) => task.id === id ? { ...task, done: !task.done } : task);
      saveState();
      render();
    });
  });

  document.querySelectorAll("[data-delete-task]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = Number(btn.dataset.deleteTask);
      state.tasks = state.tasks.filter((task) => task.id !== id);
      saveState();
      render();
    });
  });

  document.getElementById("openAddModal")?.addEventListener("click", () => document.getElementById("addModal").classList.add("open"));
  document.getElementById("closeAddModal")?.addEventListener("click", () => document.getElementById("addModal").classList.remove("open"));
  document.getElementById("addModal")?.addEventListener("click", (e) => {
    if (e.target.id === "addModal") e.currentTarget.classList.remove("open");
  });

  document.getElementById("saveTaskBtn")?.addEventListener("click", () => {
    const area = document.getElementById("newArea").value.trim() || "Aktivitas";
    const task = document.getElementById("newTask").value.trim();
    if (!task) return;
    state.tasks.push({ id: Date.now(), area, task, done: false, icon: "target" });
    saveState();
    document.getElementById("addModal").classList.remove("open");
    render();
  });

  document.getElementById("childNameInput")?.addEventListener("input", (e) => {
    state.childName = e.target.value;
    saveState();
  });

  document.getElementById("resetBtn")?.addEventListener("click", () => {
    if (!confirm("Reset semua data demo?")) return;
    localStorage.removeItem(STORAGE_KEY);
    state = loadState();
    render();
  });
}

function updateOnlineBadge() {
  const online = navigator.onLine;
  [document.getElementById("onlineBadge"), document.getElementById("mobileOnlineBadge")].filter(Boolean).forEach((el) => {
    el.className = `badge ${online ? "online" : "offline"}`;
    el.innerHTML = `${online ? icon("wifi") : icon("wifioff")} ${online ? "Online" : "Offline"}`;
  });
  const installBtn = document.getElementById("installBtn");
  if (installBtn) installBtn.style.display = deferredPrompt ? "inline-flex" : "none";
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[ch]));
}

function escapeAttr(value) {
  return escapeHtml(value).replace(/'/g, "&#039;");
}

window.addEventListener("online", updateOnlineBadge);
window.addEventListener("offline", updateOnlineBadge);
window.addEventListener("beforeinstallprompt", (event) => {
  event.preventDefault();
  deferredPrompt = event;
  updateOnlineBadge();
});

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("./sw.js").catch(console.error);
  });
}

render();
