-- HomeSchool Hub Family Edition Schema
-- Jalankan di Supabase SQL Editor.
-- Jika sebelumnya memakai versi parent_id personal, sebaiknya buat project Supabase baru agar bersih.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  created_at timestamptz default now()
);

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  invite_code text unique not null default upper(substr(encode(gen_random_bytes(8), 'hex'), 1, 8)),
  created_at timestamptz default now()
);

create table if not exists public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'parent' check (role in ('owner','parent','child','observer')),
  status text not null default 'active' check (status in ('active','invited','disabled')),
  created_at timestamptz default now(),
  unique (household_id, user_id)
);

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  name text not null,
  birth_date date,
  notes text,
  created_at timestamptz default now()
);

create table if not exists public.life_skill_sets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  title text not null,
  category text,
  description text,
  is_template boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.targets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  child_id uuid not null references public.children(id) on delete cascade,
  skill_set_id uuid references public.life_skill_sets(id) on delete set null,
  title text not null,
  description text,
  frequency text default 'Harian',
  target_count integer not null default 1,
  unit text default 'poin',
  due_date date,
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists public.progress_logs (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  child_id uuid not null references public.children(id) on delete cascade,
  target_id uuid not null references public.targets(id) on delete cascade,
  points integer not null default 1,
  note text,
  logged_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.children enable row level security;
alter table public.life_skill_sets enable row level security;
alter table public.targets enable row level security;
alter table public.progress_logs enable row level security;

create or replace function public.is_household_member(hid uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.household_members hm
    where hm.household_id = hid
      and hm.user_id = auth.uid()
      and hm.status = 'active'
  );
$$;

create or replace function public.is_household_owner(hid uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.household_members hm
    where hm.household_id = hid
      and hm.user_id = auth.uid()
      and hm.role in ('owner','parent')
      and hm.status = 'active'
  );
$$;

create or replace function public.create_household(household_name text)
returns public.households
language plpgsql security definer set search_path = public as $$
declare h public.households;
begin
  insert into public.households(name, owner_id)
  values (household_name, auth.uid())
  returning * into h;

  insert into public.household_members(household_id, user_id, role, status)
  values (h.id, auth.uid(), 'owner', 'active');

  return h;
end;
$$;

create or replace function public.join_household_by_code(code text)
returns public.households
language plpgsql security definer set search_path = public as $$
declare h public.households;
begin
  select * into h from public.households where invite_code = upper(code) limit 1;
  if h.id is null then
    raise exception 'Invite code tidak ditemukan';
  end if;

  insert into public.household_members(household_id, user_id, role, status)
  values (h.id, auth.uid(), 'parent', 'active')
  on conflict (household_id, user_id) do update set status = 'active';

  return h;
end;
$$;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "households_select_member" on public.households for select using (public.is_household_member(id));
create policy "households_insert_auth" on public.households for insert with check (auth.uid() = owner_id);
create policy "households_update_owner" on public.households for update using (public.is_household_owner(id)) with check (public.is_household_owner(id));

create policy "members_select_member" on public.household_members for select using (public.is_household_member(household_id));
create policy "members_insert_self" on public.household_members for insert with check (auth.uid() = user_id or public.is_household_owner(household_id));
create policy "members_update_owner" on public.household_members for update using (public.is_household_owner(household_id)) with check (public.is_household_owner(household_id));
create policy "members_delete_owner" on public.household_members for delete using (public.is_household_owner(household_id));

create policy "children_select_household" on public.children for select using (public.is_household_member(household_id));
create policy "children_insert_household" on public.children for insert with check (public.is_household_owner(household_id));
create policy "children_update_household" on public.children for update using (public.is_household_owner(household_id)) with check (public.is_household_owner(household_id));
create policy "children_delete_household" on public.children for delete using (public.is_household_owner(household_id));

create policy "sets_select_household" on public.life_skill_sets for select using (public.is_household_member(household_id));
create policy "sets_insert_household" on public.life_skill_sets for insert with check (public.is_household_owner(household_id));
create policy "sets_update_household" on public.life_skill_sets for update using (public.is_household_owner(household_id)) with check (public.is_household_owner(household_id));
create policy "sets_delete_household" on public.life_skill_sets for delete using (public.is_household_owner(household_id));

create policy "targets_select_household" on public.targets for select using (public.is_household_member(household_id));
create policy "targets_insert_household" on public.targets for insert with check (public.is_household_owner(household_id));
create policy "targets_update_household" on public.targets for update using (public.is_household_owner(household_id)) with check (public.is_household_owner(household_id));
create policy "targets_delete_household" on public.targets for delete using (public.is_household_owner(household_id));

create policy "logs_select_household" on public.progress_logs for select using (public.is_household_member(household_id));
create policy "logs_insert_household" on public.progress_logs for insert with check (public.is_household_member(household_id));
create policy "logs_update_household" on public.progress_logs for update using (public.is_household_owner(household_id)) with check (public.is_household_owner(household_id));
create policy "logs_delete_household" on public.progress_logs for delete using (public.is_household_owner(household_id));

create index if not exists idx_members_user on public.household_members(user_id);
create index if not exists idx_members_household on public.household_members(household_id);
create index if not exists idx_children_household on public.children(household_id);
create index if not exists idx_sets_household on public.life_skill_sets(household_id);
create index if not exists idx_targets_household_child on public.targets(household_id, child_id);
create index if not exists idx_logs_household_target on public.progress_logs(household_id, target_id);


-- Enable Supabase Realtime for multi-device sync.
-- If a table is already in the publication, duplicate_object is ignored.
do $$ begin alter publication supabase_realtime add table public.children; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.life_skill_sets; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.targets; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.progress_logs; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.household_members; exception when duplicate_object then null; end $$;


-- Household profile: visi, misi, nilai utama, alasan, dan prinsip keluarga.
create table if not exists public.household_profiles (
  household_id uuid primary key references public.households(id) on delete cascade,
  vision text,
  mission jsonb default '[]'::jsonb,
  values jsonb default '[]'::jsonb,
  reasons jsonb default '[]'::jsonb,
  principles text,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz default now()
);

alter table public.household_profiles enable row level security;

drop policy if exists "profiles_household_select" on public.household_profiles;
drop policy if exists "profiles_household_insert" on public.household_profiles;
drop policy if exists "profiles_household_update" on public.household_profiles;
drop policy if exists "profiles_household_delete" on public.household_profiles;

create policy "profiles_household_select" on public.household_profiles for select using (public.is_household_member(household_id));
create policy "profiles_household_insert" on public.household_profiles for insert with check (public.is_household_owner(household_id));
create policy "profiles_household_update" on public.household_profiles for update using (public.is_household_owner(household_id)) with check (public.is_household_owner(household_id));
create policy "profiles_household_delete" on public.household_profiles for delete using (public.is_household_owner(household_id));

do $$ begin alter publication supabase_realtime add table public.household_profiles; exception when duplicate_object then null; end $$;


-- =========================================================
-- Fix 2026-07-24: Member Household tidak tampil
-- =========================================================
-- Masalah 1: Jika email confirmation aktif di Supabase Auth,
-- sb.auth.signUp() tidak langsung memberi session, sehingga upsert
-- ke public.profiles dari sisi browser gagal (RLS butuh auth.uid()).
-- Solusi: buat profil otomatis lewat trigger di server, bukan dari browser.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', new.email))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Backfill: buat profil untuk akun yang sudah terlanjur daftar
-- sebelum trigger di atas ada (misalnya akun istri Anda sekarang).
insert into public.profiles (id, email, full_name)
select u.id, u.email, coalesce(u.raw_user_meta_data->>'full_name', u.email)
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;

-- Masalah 2: RLS profiles_select_own hanya mengizinkan orang melihat
-- profilnya sendiri, jadi ayah tidak bisa melihat nama/email ibu, dst.
-- Tambahkan izin: boleh lihat profil orang lain jika satu household.
drop policy if exists "profiles_select_household" on public.profiles;
create policy "profiles_select_household" on public.profiles for select using (
  exists (
    select 1
    from public.household_members hm_target
    join public.household_members hm_me
      on hm_me.household_id = hm_target.household_id
    where hm_target.user_id = profiles.id
      and hm_me.user_id = auth.uid()
      and hm_target.status = 'active'
      and hm_me.status = 'active'
  )
);


-- =========================================================
-- Fitur 2026-07-25: Milestone belajar anak
-- =========================================================
-- Tabel baru untuk menandai pencapaian anak per fase (Fondasi, A-F,
-- mengacu longgar ke Capaian Pembelajaran Kurikulum Merdeka).
-- Aman dijalankan ulang: pakai "if not exists" dan "drop policy if exists".
create table if not exists public.milestones (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  child_id uuid not null references public.children(id) on delete cascade,
  fase text not null default 'A',
  title text not null,
  description text,
  achieved boolean not null default false,
  achieved_at timestamptz,
  created_at timestamptz default now()
);

alter table public.milestones enable row level security;

drop policy if exists "milestones_select_household" on public.milestones;
create policy "milestones_select_household" on public.milestones for select using (public.is_household_member(household_id));

drop policy if exists "milestones_insert_household" on public.milestones;
create policy "milestones_insert_household" on public.milestones for insert with check (public.is_household_member(household_id));

drop policy if exists "milestones_update_household" on public.milestones;
create policy "milestones_update_household" on public.milestones for update using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

drop policy if exists "milestones_delete_household" on public.milestones;
create policy "milestones_delete_household" on public.milestones for delete using (public.is_household_owner(household_id));

do $$ begin alter publication supabase_realtime add table public.milestones; exception when duplicate_object then null; end $$;


-- =========================================================
-- Fitur 2026-07-26: Kompetisi Pekerjaan Rumah (poin keluarga)
-- =========================================================
-- "chores" = daftar pekerjaan rumah, "chore_logs" = tiap kali ada yang
-- menyelesaikannya (poin diakumulasi dari sini, mirip pola progress_logs).
create table if not exists public.chores (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  title text not null,
  pic uuid references auth.users(id) on delete set null,
  points int not null default 10,
  created_at timestamptz default now()
);

alter table public.chores enable row level security;

drop policy if exists "chores_select_household" on public.chores;
create policy "chores_select_household" on public.chores for select using (public.is_household_member(household_id));

drop policy if exists "chores_insert_household" on public.chores;
create policy "chores_insert_household" on public.chores for insert with check (public.is_household_member(household_id));

drop policy if exists "chores_update_household" on public.chores;
create policy "chores_update_household" on public.chores for update using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

drop policy if exists "chores_delete_household" on public.chores;
create policy "chores_delete_household" on public.chores for delete using (public.is_household_owner(household_id));

create table if not exists public.chore_logs (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  chore_id uuid not null references public.chores(id) on delete cascade,
  done_by uuid references auth.users(id) on delete set null,
  points int not null default 0,
  done_at timestamptz default now()
);

alter table public.chore_logs enable row level security;

drop policy if exists "chore_logs_select_household" on public.chore_logs;
create policy "chore_logs_select_household" on public.chore_logs for select using (public.is_household_member(household_id));

drop policy if exists "chore_logs_insert_household" on public.chore_logs;
create policy "chore_logs_insert_household" on public.chore_logs for insert with check (public.is_household_member(household_id));

drop policy if exists "chore_logs_delete_household" on public.chore_logs;
create policy "chore_logs_delete_household" on public.chore_logs for delete using (public.is_household_owner(household_id));

do $$ begin alter publication supabase_realtime add table public.chores; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.chore_logs; exception when duplicate_object then null; end $$;
