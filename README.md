# HomeSchool Hub Pro

PWA homeschooling keluarga yang siap deploy ke Vercel tanpa build step.

## Fitur

- Login/daftar orang tua dengan Supabase Auth
- Database anak
- Life Skill Sets
- Target per anak
- Progress log
- Offline cache dengan service worker
- Data terakhir tersimpan lokal dengan localStorage
- Mobile-first PWA

## Setup Supabase

1. Buat project Supabase.
2. Buka SQL Editor.
3. Copy isi `supabase/schema.sql` lalu klik Run.
4. Buka Project Settings > API.
5. Copy Project URL dan anon/public key.
6. Isi file `config.js`.

## Deploy Vercel

1. Upload semua file ke GitHub.
2. Import repository ke Vercel.
3. Framework Preset: Other.
4. Build Command: kosongkan.
5. Output Directory: .
6. Deploy.

## Catatan keamanan

Anon/public key boleh berada di browser. Keamanan data diatur oleh Row Level Security di database. Jangan pernah menaruh service role key di browser.
