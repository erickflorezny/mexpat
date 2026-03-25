-- Mexpat Supabase schema
-- Focus: profiles, listings, tags, legal_milestones

create extension if not exists postgis;
create extension if not exists citext;
create extension if not exists pgcrypto;

-- enums
DO $$ BEGIN
  CREATE TYPE residency_status_enum AS ENUM ('Temporal', 'Permanente');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE listing_kind_enum AS ENUM ('Business', 'Coworking', 'Class');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE milestone_state_enum AS ENUM ('locked', 'available', 'in_progress', 'completed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  residency_status residency_status_enum not null default 'Temporal',
  xp_points integer not null default 0 check (xp_points >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- normalized tags
create table if not exists public.tags (
  id bigserial primary key,
  slug citext not null unique,
  label text not null
);

-- directory listings
create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text,
  kind listing_kind_enum not null,
  address text,
  location geography(Point, 4326) not null,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_listings_updated_at on public.listings;
create trigger trg_listings_updated_at
before update on public.listings
for each row execute function public.set_updated_at();

create index if not exists idx_listings_location_gist on public.listings using gist(location);
create index if not exists idx_listings_kind on public.listings(kind);
create index if not exists idx_listings_active on public.listings(is_active);

-- join table: listings <-> tags
create table if not exists public.listing_tags (
  listing_id uuid not null references public.listings(id) on delete cascade,
  tag_id bigint not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (listing_id, tag_id)
);

create index if not exists idx_listing_tags_tag_id on public.listing_tags(tag_id);

-- legal quest progress per user
create table if not exists public.legal_milestones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  code text not null,
  title text not null,
  description text,
  state milestone_state_enum not null default 'locked',
  progress_percent numeric(5,2) not null default 0
    check (progress_percent >= 0 and progress_percent <= 100),
  xp_reward integer not null default 0 check (xp_reward >= 0),
  due_date date,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, code)
);

drop trigger if exists trg_legal_milestones_updated_at on public.legal_milestones;
create trigger trg_legal_milestones_updated_at
before update on public.legal_milestones
for each row execute function public.set_updated_at();

create index if not exists idx_legal_milestones_user_id on public.legal_milestones(user_id);
create index if not exists idx_legal_milestones_state on public.legal_milestones(state);

-- RPC: fetch listings by tag for app directory filtering
create or replace function public.get_listings_by_tag(
  p_tag text,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  id uuid,
  title text,
  description text,
  kind listing_kind_enum,
  address text,
  latitude double precision,
  longitude double precision,
  tags text[]
)
language sql
stable
as $$
  select
    l.id,
    l.title,
    l.description,
    l.kind,
    l.address,
    st_y(l.location::geometry) as latitude,
    st_x(l.location::geometry) as longitude,
    array_agg(distinct t.label order by t.label) as tags
  from public.listings l
  join public.listing_tags lt on lt.listing_id = l.id
  join public.tags t on t.id = lt.tag_id
  where l.is_active = true
    and lower(t.slug::text) = lower(trim(both '#' from p_tag))
  group by l.id, l.title, l.description, l.kind, l.address, latitude, longitude
  order by l.created_at desc
  limit p_limit offset p_offset;
$$;

-- RLS
alter table public.profiles enable row level security;
alter table public.tags enable row level security;
alter table public.listings enable row level security;
alter table public.listing_tags enable row level security;
alter table public.legal_milestones enable row level security;

-- profiles
create policy "profiles_select_own" on public.profiles
for select using (auth.uid() = id);

create policy "profiles_insert_own" on public.profiles
for insert with check (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
for update using (auth.uid() = id);

-- tags/listings readable for authenticated users
create policy "tags_read_all" on public.tags
for select to authenticated using (true);

create policy "listings_read_active" on public.listings
for select to authenticated using (is_active = true);

create policy "listing_tags_read_all" on public.listing_tags
for select to authenticated using (true);

-- listing write ownership
create policy "listings_insert_owner" on public.listings
for insert to authenticated with check (auth.uid() = owner_id);

create policy "listings_update_owner" on public.listings
for update to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- legal milestones user-isolated
create policy "legal_milestones_all_own" on public.legal_milestones
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- RPC: complete milestone and atomically award XP on profiles
create or replace function public.complete_legal_milestone(
  p_milestone_id uuid
)
returns public.legal_milestones
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_milestone public.legal_milestones%rowtype;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  update public.legal_milestones lm
  set
    state = 'completed',
    progress_percent = 100,
    completed_at = coalesce(lm.completed_at, now()),
    updated_at = now()
  where lm.id = p_milestone_id
    and lm.user_id = v_uid
    and lm.state <> 'completed'
  returning * into v_milestone;

  if not found then
    select * into v_milestone
    from public.legal_milestones lm
    where lm.id = p_milestone_id
      and lm.user_id = v_uid;

    if not found then
      raise exception 'Milestone not found';
    end if;

    return v_milestone;
  end if;

  update public.profiles p
  set
    xp_points = p.xp_points + v_milestone.xp_reward,
    updated_at = now()
  where p.id = v_uid;

  return v_milestone;
end;
$$;

grant execute on function public.complete_legal_milestone(uuid) to authenticated;

-- RPC: admin-only revert of a completed milestone and XP rollback
create or replace function public.revert_legal_milestone_admin(
  p_milestone_id uuid
)
returns public.legal_milestones
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_actor_role text := coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '');
  v_milestone public.legal_milestones%rowtype;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if lower(v_actor_role) <> 'admin' then
    raise exception 'Admin privileges required';
  end if;

  select * into v_milestone
  from public.legal_milestones
  where id = p_milestone_id;

  if not found then
    raise exception 'Milestone not found';
  end if;

  if v_milestone.state = 'completed' then
    update public.profiles p
    set
      xp_points = greatest(0, p.xp_points - v_milestone.xp_reward),
      updated_at = now()
    where p.id = v_milestone.user_id;
  end if;

  update public.legal_milestones lm
  set
    state = 'in_progress',
    progress_percent = 0,
    completed_at = null,
    updated_at = now()
  where lm.id = v_milestone.id
  returning * into v_milestone;

  return v_milestone;
end;
$$;

grant execute on function public.revert_legal_milestone_admin(uuid) to authenticated;

-- RPC: admin-only listing of all milestones across users for moderation
create or replace function public.admin_list_legal_milestones(
  p_limit int default 200,
  p_offset int default 0
)
returns table (
  id uuid,
  user_id uuid,
  code text,
  title text,
  description text,
  state milestone_state_enum,
  progress_percent numeric,
  xp_reward integer,
  due_date date,
  completed_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    lm.id,
    lm.user_id,
    lm.code,
    lm.title,
    lm.description,
    lm.state,
    lm.progress_percent,
    lm.xp_reward,
    lm.due_date,
    lm.completed_at,
    lm.created_at,
    lm.updated_at
  from public.legal_milestones lm
  where lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '')) = 'admin'
  order by lm.updated_at desc
  limit greatest(1, least(p_limit, 1000))
  offset greatest(0, p_offset);
$$;

grant execute on function public.admin_list_legal_milestones(int, int) to authenticated;
