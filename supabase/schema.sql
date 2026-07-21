-- HomeSchool Hub Pro Supabase Schema
-- Jalankan file ini di Supabase Dashboard > SQL Editor > Run.
-- Setelah itu isi config.js dengan Project URL dan anon/public key.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  created_at timestamptz default now()
);

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  birth_date date,
  notes text,
  created_at timestamptz default now()
);

create table if not exists public.life_skill_sets (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  category text,
  description text,
  is_template boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.targets (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
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
  parent_id uuid not null references auth.users(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  target_id uuid not null references public.targets(id) on delete cascade,
  points integer not null default 1,
  note text,
  logged_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.children enable row level security;
alter table public.life_skill_sets enable row level security;
alter table public.targets enable row level security;
alter table public.progress_logs enable row level security;

-- Profiles
create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- Children
create policy "children_select_own" on public.children for select using (auth.uid() = parent_id);
create policy "children_insert_own" on public.children for insert with check (auth.uid() = parent_id);
create policy "children_update_own" on public.children for update using (auth.uid() = parent_id) with check (auth.uid() = parent_id);
create policy "children_delete_own" on public.children for delete using (auth.uid() = parent_id);

-- Life skill sets
create policy "sets_select_own" on public.life_skill_sets for select using (auth.uid() = parent_id);
create policy "sets_insert_own" on public.life_skill_sets for insert with check (auth.uid() = parent_id);
create policy "sets_update_own" on public.life_skill_sets for update using (auth.uid() = parent_id) with check (auth.uid() = parent_id);
create policy "sets_delete_own" on public.life_skill_sets for delete using (auth.uid() = parent_id);

-- Targets
create policy "targets_select_own" on public.targets for select using (auth.uid() = parent_id);
create policy "targets_insert_own" on public.targets for insert with check (auth.uid() = parent_id);
create policy "targets_update_own" on public.targets for update using (auth.uid() = parent_id) with check (auth.uid() = parent_id);
create policy "targets_delete_own" on public.targets for delete using (auth.uid() = parent_id);

-- Progress logs
create policy "logs_select_own" on public.progress_logs for select using (auth.uid() = parent_id);
create policy "logs_insert_own" on public.progress_logs for insert with check (auth.uid() = parent_id);
create policy "logs_update_own" on public.progress_logs for update using (auth.uid() = parent_id) with check (auth.uid() = parent_id);
create policy "logs_delete_own" on public.progress_logs for delete using (auth.uid() = parent_id);

create index if not exists idx_children_parent on public.children(parent_id);
create index if not exists idx_sets_parent on public.life_skill_sets(parent_id);
create index if not exists idx_targets_parent_child on public.targets(parent_id, child_id);
create index if not exists idx_logs_parent_target on public.progress_logs(parent_id, target_id);
