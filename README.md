# HomeSchool Hub Family Edition

Versi siap upload ke GitHub dan deploy Vercel tanpa build command.

## Konsep

Aplikasi ini memakai model Household, sehingga akun ayah, ibu, dan anak dapat melihat data keluarga yang sama melalui invite code.

## Setup

1. Buat project baru di Supabase.
2. Buka SQL Editor.
3. Jalankan isi file `supabase/schema-family.sql`.
4. Buka Project Settings > API.
5. Isi `config.js` dengan Project URL dan anon/public key.
6. Upload semua file ke GitHub.
7. Deploy ke Vercel dengan:
   - Framework Preset: Other
   - Install Command: kosong
   - Build Command: kosong
   - Output Directory: .

## Flow Pakai

1. Akun pertama daftar dan login.
2. Buat Household, contoh: Keluarga FII.
3. Buka menu Member, salin Invite Code.
4. Akun kedua daftar/login.
5. Pilih Gabung Household dan masukkan Invite Code.
6. Data anak, skill set, target, dan progress akan tampil bersama.

## Catatan

- Jangan pakai service_role key di browser.
- Public anon key aman dipakai karena database dilindungi RLS.
- Disarankan memakai Supabase project baru agar tidak bentrok dengan schema versi lama.


## Multi-device Sync dan Notifikasi

Versi ini sudah menambahkan Supabase Realtime untuk tabel:

- children
- life_skill_sets
- targets
- progress_logs
- household_members

Jika ayah menambah target dari HP dan ibu sedang membuka aplikasi, aplikasi ibu akan auto-refresh dan menampilkan notifikasi perangkat jika izin notifikasi sudah diberikan.

Catatan: notifikasi dalam versi static ini adalah notifikasi realtime saat aplikasi aktif/terpasang dan service worker siap. Untuk push notification penuh saat browser benar-benar tertutup lama, dibutuhkan backend/Edge Function + Web Push/VAPID.


## Bugfix 2026-07-22

Memperbaiki error browser:

```txt
Uncaught SyntaxError: Identifier 'top' has already been declared
```

Penyebabnya adalah nama fungsi internal `top()` bentrok dengan global `window.top` di browser. Fungsi sudah diganti menjadi `renderTopbar()`.


## Fitur Visi Misi

Versi ini menambahkan menu **Visi** yang tersimpan di Supabase per Household.

Data yang disimpan:

- Visi homeschooling keluarga
- Misi pendidikan
- Nilai utama keluarga
- Alasan memilih homeschooling
- Prinsip keluarga

Jika ayah atau ibu mengubah visi misi dari satu perangkat, perangkat lain dalam household yang sama akan tersinkron lewat Supabase Realtime.


## Bugfix 2026-07-24: Anggota household (istri/suami) tidak muncul di menu Member

Penyebab:

1. Query member memakai auto-join PostgREST ke tabel `profiles`. Karena `household_members.user_id` tidak punya foreign key langsung ke `profiles`, join ini sering gagal diam-diam sehingga daftar member kosong.
2. Kebijakan RLS `profiles_select_own` hanya mengizinkan seseorang melihat baris profilnya sendiri, sehingga pasangan tidak bisa saling melihat nama/email walau join berhasil.
3. Jika opsi "Confirm email" aktif di Supabase Auth, saat sign up belum ada session aktif, sehingga pembuatan baris `profiles` dari sisi browser bisa gagal.

Perbaikan:

- `app.js`: mengambil `household_members` dan `profiles` lewat dua query terpisah lalu digabung manual, tidak lagi bergantung pada auto-join.
- `supabase/schema-family.sql`: menambahkan trigger `on_auth_user_created` agar baris `profiles` otomatis dibuat di server setiap ada akun baru, ditambah query backfill untuk akun yang sudah lebih dulu daftar, dan kebijakan RLS baru `profiles_select_household` agar sesama anggota household bisa saling melihat nama.
- `sw.js`: versi cache dinaikkan supaya pengguna PWA yang sudah install mendapat kode terbaru.

**Wajib jalankan ulang** isi `supabase/schema-family.sql` di SQL Editor Supabase (aman dijalankan berkali-kali) agar perbaikan ini aktif, lalu upload ulang file `app.js` dan `sw.js` ke deployment Anda.


## Fitur Baru: Menu Panduan

Menambahkan tab **Panduan** (antara Home dan Visi) sebagai titik awal bagi orang tua yang baru mulai homeschooling:

- **Edukasi Dasar** (accordion, ketuk untuk buka): apa itu homeschooling, dasar hukum di Indonesia (UU No. 20/2003), jalur ijazah resmi lewat PKBM & Paket A/B/C, serta gambaran alur dan dokumen pendaftaran ke PKBM.
- **Langkah di Aplikasi Ini**: checklist berurutan (Visi Misi → Data Anak → Skill Set → Target → Progress) dengan status Selesai/Belum dan tombol langsung ke tab terkait.
- **Kartu "Langkah Selanjutnya"** otomatis muncul di Dashboard, menunjukkan langkah pertama yang belum diselesaikan household, supaya keluarga tahu harus mulai dari mana tanpa perlu menebak-nebak.

Catatan: konten edukasi di menu Panduan bersifat gambaran umum. Persyaratan, biaya, dan mekanisme ujian kesetaraan (sekarang disebut TKA) bisa berbeda tiap daerah dan berubah dari waktu ke waktu — selalu konfirmasi ke PKBM/dinas pendidikan setempat sebelum mendaftar.
