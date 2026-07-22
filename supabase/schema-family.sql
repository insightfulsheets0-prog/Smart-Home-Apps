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
