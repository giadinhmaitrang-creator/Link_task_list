-- =====================================================================
-- Kho Link Dự Án — Supabase schema (multi-user, Google sign-in)
-- Paste the whole file into Supabase → SQL Editor → Run. Safe to re-run.
-- Security model: every table has Row Level Security. A person sees
--   * their own profile settings and calendar,
--   * boards / projects they are a member of (owner or member),
--   * profiles of people they share a board or project with.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- profiles (one per Google account) ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text not null default '',
  avatar_url text not null default '',
  created_at timestamptz not null default now()
);
create unique index if not exists profiles_email_idx on public.profiles (lower(email));

-- personal settings: link types, calendar data (never shared)
create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  link_types jsonb,
  calendar jsonb,
  updated_at timestamptz not null default now()
);

-- ---------- task boards ----------
create table if not exists public.boards (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  color text not null default '#1d6b5f',
  columns jsonb not null default '[{"id":"todo","name":"Cần làm"},{"id":"doing","name":"Đang làm"},{"id":"review","name":"Chờ duyệt"},{"id":"done","name":"Hoàn thành","done":true}]',
  labels jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.board_members (
  board_id uuid not null references public.boards(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member')),
  added_at timestamptz not null default now(),
  primary key (board_id, user_id)
);
create table if not exists public.board_invites (
  board_id uuid not null references public.boards(id) on delete cascade,
  email text not null,
  invited_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (board_id, email)
);
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references public.boards(id) on delete cascade,
  column_id text not null default 'todo',
  title text not null check (char_length(title) between 1 and 300),
  description text not null default '',
  priority text not null default '' check (priority in ('','urgent','high','med','low')),
  start_date date,
  due_date date,
  labels jsonb not null default '[]',
  checklist jsonb not null default '[]',
  link_ids jsonb not null default '[]',
  assignees uuid[] not null default '{}',
  position double precision not null default 0,
  archived boolean not null default false,
  done_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists tasks_board_idx on public.tasks (board_id);
create index if not exists tasks_assignees_idx on public.tasks using gin (assignees);
create table if not exists public.task_comments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);
create index if not exists task_comments_task_idx on public.task_comments (task_id);

-- ---------- document projects ----------
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  description text not null default '',
  color text not null default '#1d6b5f',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.project_members (
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member')),
  added_at timestamptz not null default now(),
  primary key (project_id, user_id)
);
create table if not exists public.project_invites (
  project_id uuid not null references public.projects(id) on delete cascade,
  email text not null,
  invited_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (project_id, email)
);
create table if not exists public.doc_groups (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.links (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  group_id uuid references public.doc_groups(id) on delete set null,
  title text not null check (char_length(title) between 1 and 300),
  url text not null,
  type text not null default 'web',
  tags jsonb not null default '[]',
  note text not null default '',
  pinned boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists links_project_idx on public.links (project_id);

-- ---------- helpers (SECURITY DEFINER so policies don't recurse) ----------
create or replace function public.is_board_member(b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from board_members where board_id = b and user_id = auth.uid());
$$;
create or replace function public.is_board_owner(b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from board_members where board_id = b and user_id = auth.uid() and role = 'owner');
$$;
create or replace function public.is_project_member(p uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from project_members where project_id = p and user_id = auth.uid());
$$;
create or replace function public.is_project_owner(p uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from project_members where project_id = p and user_id = auth.uid() and role = 'owner');
$$;
create or replace function public.shares_space_with(other uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select other = auth.uid()
    or exists (select 1 from board_members a join board_members b using (board_id) where a.user_id = auth.uid() and b.user_id = other)
    or exists (select 1 from project_members a join project_members b using (project_id) where a.user_id = auth.uid() and b.user_id = other);
$$;

-- ---------- triggers ----------
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end $$;
do $$ declare t text; begin
  foreach t in array array['boards','tasks','projects','doc_groups','links','user_settings'] loop
    execute format('drop trigger if exists touch_%1$s on public.%1$s', t);
    execute format('create trigger touch_%1$s before update on public.%1$s for each row execute function public.touch_updated_at()', t);
  end loop;
end $$;

-- new Google account → profile, then turn pending invites for that email into memberships
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, email, name, avatar_url)
  values (new.id, coalesce(new.email, ''),
          coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(coalesce(new.email,''), '@', 1)),
          coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture', ''))
  on conflict (id) do update set email = excluded.email, name = excluded.name, avatar_url = excluded.avatar_url;
  insert into board_members (board_id, user_id) select board_id, new.id from board_invites where lower(email) = lower(new.email) on conflict do nothing;
  delete from board_invites where lower(email) = lower(new.email);
  insert into project_members (project_id, user_id) select project_id, new.id from project_invites where lower(email) = lower(new.email) on conflict do nothing;
  delete from project_invites where lower(email) = lower(new.email);
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- creator of a board / project becomes its owner
create or replace function public.add_board_owner() returns trigger
language plpgsql security definer set search_path = public as $$
begin insert into board_members (board_id, user_id, role) values (new.id, new.owner_id, 'owner') on conflict do nothing; return new; end $$;
drop trigger if exists board_owner on public.boards;
create trigger board_owner after insert on public.boards for each row execute function public.add_board_owner();
create or replace function public.add_project_owner() returns trigger
language plpgsql security definer set search_path = public as $$
begin insert into project_members (project_id, user_id, role) values (new.id, new.owner_id, 'owner') on conflict do nothing; return new; end $$;
drop trigger if exists project_owner on public.projects;
create trigger project_owner after insert on public.projects for each row execute function public.add_project_owner();

-- keep authorship honest on tasks
create or replace function public.stamp_task_author() returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then new.created_by := auth.uid(); end if;
  new.updated_by := auth.uid();
  return new;
end $$;
drop trigger if exists task_author on public.tasks;
create trigger task_author before insert or update on public.tasks for each row execute function public.stamp_task_author();
create or replace function public.stamp_link_author() returns trigger language plpgsql as $$
begin new.created_by := auth.uid(); return new; end $$;
drop trigger if exists link_author on public.links;
create trigger link_author before insert on public.links for each row execute function public.stamp_link_author();

-- ---------- invitations (owner only) ----------
create or replace function public.invite_to_board(b uuid, invitee text) returns text
language plpgsql security definer set search_path = public as $$
declare uid uuid; e text := lower(trim(invitee));
begin
  if not is_board_owner(b) then raise exception 'Chỉ chủ bảng mới mời được thành viên'; end if;
  if e !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'Email không hợp lệ'; end if;
  select id into uid from profiles where lower(email) = e;
  if uid is not null then
    insert into board_members (board_id, user_id) values (b, uid) on conflict do nothing;
    return 'added';
  end if;
  insert into board_invites (board_id, email, invited_by) values (b, e, auth.uid()) on conflict do nothing;
  return 'invited';
end $$;
create or replace function public.invite_to_project(p uuid, invitee text) returns text
language plpgsql security definer set search_path = public as $$
declare uid uuid; e text := lower(trim(invitee));
begin
  if not is_project_owner(p) then raise exception 'Chỉ chủ dự án mới chia sẻ được'; end if;
  if e !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'Email không hợp lệ'; end if;
  select id into uid from profiles where lower(email) = e;
  if uid is not null then
    insert into project_members (project_id, user_id) values (p, uid) on conflict do nothing;
    return 'added';
  end if;
  insert into project_invites (project_id, email, invited_by) values (p, e, auth.uid()) on conflict do nothing;
  return 'invited';
end $$;
revoke all on function public.invite_to_board(uuid, text) from public, anon;
revoke all on function public.invite_to_project(uuid, text) from public, anon;
grant execute on function public.invite_to_board(uuid, text) to authenticated;
grant execute on function public.invite_to_project(uuid, text) to authenticated;

-- ---------- row level security ----------
alter table public.profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.boards enable row level security;
alter table public.board_members enable row level security;
alter table public.board_invites enable row level security;
alter table public.tasks enable row level security;
alter table public.task_comments enable row level security;
alter table public.projects enable row level security;
alter table public.project_members enable row level security;
alter table public.project_invites enable row level security;
alter table public.doc_groups enable row level security;
alter table public.links enable row level security;

do $$ declare r record; begin
  for r in select policyname, tablename from pg_policies where schemaname = 'public' loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

create policy profiles_read on public.profiles for select to authenticated using (shares_space_with(id));
create policy profiles_update_self on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy settings_self on public.user_settings for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy boards_read on public.boards for select to authenticated using (is_board_member(id));
create policy boards_insert on public.boards for insert to authenticated with check (owner_id = auth.uid());
create policy boards_update on public.boards for update to authenticated using (is_board_member(id)) with check (is_board_member(id));
create policy boards_delete on public.boards for delete to authenticated using (is_board_owner(id));

create policy bm_read on public.board_members for select to authenticated using (is_board_member(board_id));
create policy bm_remove on public.board_members for delete to authenticated
  using ((is_board_owner(board_id) and role <> 'owner') or (user_id = auth.uid() and role <> 'owner'));
create policy bi_read on public.board_invites for select to authenticated using (is_board_member(board_id));
create policy bi_remove on public.board_invites for delete to authenticated using (is_board_owner(board_id));

create policy tasks_all on public.tasks for all to authenticated using (is_board_member(board_id)) with check (is_board_member(board_id));

create policy tc_read on public.task_comments for select to authenticated
  using (exists (select 1 from tasks t where t.id = task_id and is_board_member(t.board_id)));
create policy tc_insert on public.task_comments for insert to authenticated
  with check (user_id = auth.uid() and exists (select 1 from tasks t where t.id = task_id and is_board_member(t.board_id)));
create policy tc_delete on public.task_comments for delete to authenticated using (user_id = auth.uid());

create policy projects_read on public.projects for select to authenticated using (is_project_member(id));
create policy projects_insert on public.projects for insert to authenticated with check (owner_id = auth.uid());
create policy projects_update on public.projects for update to authenticated using (is_project_member(id)) with check (is_project_member(id));
create policy projects_delete on public.projects for delete to authenticated using (is_project_owner(id));

create policy pm_read on public.project_members for select to authenticated using (is_project_member(project_id));
create policy pm_remove on public.project_members for delete to authenticated
  using ((is_project_owner(project_id) and role <> 'owner') or (user_id = auth.uid() and role <> 'owner'));
create policy pi_read on public.project_invites for select to authenticated using (is_project_member(project_id));
create policy pi_remove on public.project_invites for delete to authenticated using (is_project_owner(project_id));

create policy groups_all on public.doc_groups for all to authenticated using (is_project_member(project_id)) with check (is_project_member(project_id));
create policy links_all on public.links for all to authenticated using (is_project_member(project_id)) with check (is_project_member(project_id));

-- table privileges (RLS still decides which rows)
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
revoke all on all tables in schema public from anon;

-- ---------- realtime (live updates between family members) ----------
do $$ declare t text; begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['boards','board_members','tasks','task_comments','projects','project_members','doc_groups','links'] loop
      if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end $$;
