# HomeSchool Hub Static PWA

Versi ini **tanpa npm, tanpa install dependency, tanpa build command**.

Anda cukup upload semua file ke GitHub, lalu deploy ke Vercel sebagai static site.

## Isi file

```txt
homeschool-hub-static-pwa/
├─ index.html
├─ style.css
├─ app.js
├─ manifest.webmanifest
├─ sw.js
├─ vercel.json
├─ icons/
│  ├─ icon-192.png
│  └─ icon-512.png
└─ README.md
```

## Cara upload ke GitHub

1. Buat repository baru di GitHub.
2. Upload semua file dan folder dari project ini.
3. Commit ke branch `main`.

Atau lewat terminal:

```bash
git init
git add .
git commit -m "Initial static PWA"
git branch -M main
git remote add origin https://github.com/USERNAME/homeschool-hub-static-pwa.git
git push -u origin main
```

## Cara deploy ke Vercel tanpa install apapun

1. Masuk ke Vercel.
2. Klik **Add New Project**.
3. Import repository GitHub.
4. Pada bagian **Framework Preset**, pilih **Other**.
5. Kosongkan **Build Command**.
6. Kosongkan **Install Command**.
7. Output Directory isi: `.` atau biarkan kosong jika Vercel membaca root project.
8. Klik **Deploy**.

File `vercel.json` sudah disiapkan agar Vercel menyajikan file statis langsung dari root.

## Test offline

Setelah deploy:

1. Buka website hasil Vercel.
2. Buka DevTools browser.
3. Masuk tab **Application**.
4. Cek **Manifest**, **Service Worker**, dan **Cache Storage**.
5. Masuk tab **Network**, pilih **Offline**.
6. Refresh halaman.
7. Aplikasi tetap bisa terbuka.

## Catatan

- Data checklist tersimpan di `localStorage` perangkat pengguna.
- Service worker berjalan di `https` atau `localhost`.
- Karena ini static PWA murni, tidak perlu React, Vite, Tailwind, atau package manager.
