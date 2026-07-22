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


## Config Sudah Diisi

File `config.js` pada ZIP ini sudah berisi Supabase URL dan publishable/anon key yang diberikan oleh pengguna.

Tetap pastikan di Supabase SQL Editor sudah menjalankan file:

```txt
supabase/schema-family.sql
```
