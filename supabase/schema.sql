-- Job Schedule — Supabase schema
-- รันใน Supabase Dashboard → SQL Editor (รันซ้ำได้ ไม่ทำข้อมูลหาย)

-- ---------- jobs ----------
create sequence if not exists public.job_no_seq;

create table if not exists public.jobs (
  id                uuid primary key default gen_random_uuid(),
  job_no            text unique,
  title             text not null default '',
  received_date     date,
  start_date        date,
  due_date          date,
  finish_date       date,
  assigner          text not null default '',
  department        text not null default '',
  assignee          text not null default '',
  status            text not null default '',
  priority          text not null default '',
  job_type          text not null default '',
  modules           text[] not null default '{}',
  system_name       text not null default '',
  server            text not null default '',
  project_name      text not null default '',
  form_path         text not null default '',
  button_work       text not null default '',
  note              text not null default '',
  deploy_std66      boolean not null default false,
  deploy_live       boolean not null default false,
  deploy_std66_date date,
  deploy_live_date  date,
  est_hours         numeric,
  actual_hours      numeric,
  ref_link          text not null default '',
  tags              text[] not null default '{}',
  history           jsonb not null default '[]',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  created_by        uuid default auth.uid() references auth.users(id) on delete set null,
  updated_by        uuid default auth.uid() references auth.users(id) on delete set null
);

-- v2: อีเมลผู้แก้ไขล่าสุด (ใช้แสดงตอนแจ้งเตือนว่ามีคนแก้งานเดียวกันพร้อมกัน)
alter table public.jobs add column if not exists updated_by_email text not null default '';

create index if not exists jobs_due_date_idx on public.jobs (due_date);
create index if not exists jobs_status_idx on public.jobs (status);
create index if not exists jobs_received_date_idx on public.jobs (received_date);

-- Job No อัตโนมัติ (JOB-YYYY-0001) + เก็บว่าใครแก้ล่าสุด
create or replace function public.jobs_before_write() returns trigger
language plpgsql set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if new.job_no is null or new.job_no = '' then
      loop
        new.job_no := 'JOB-' || to_char(coalesce(new.received_date, current_date), 'YYYY') || '-'
                      || lpad(nextval('public.job_no_seq')::text, 4, '0');
        exit when not exists (select 1 from public.jobs where job_no = new.job_no);
      end loop;
    end if;
    new.updated_by_email := coalesce(auth.jwt() ->> 'email', '');
  else
    new.updated_at := now();
    new.updated_by := auth.uid();
    new.updated_by_email := coalesce(auth.jwt() ->> 'email', '');
    new.created_at := old.created_at;
    new.created_by := old.created_by;
  end if;
  return new;
end $$;

drop trigger if exists jobs_before_write on public.jobs;
create trigger jobs_before_write before insert or update on public.jobs
  for each row execute function public.jobs_before_write();

-- ---------- shared settings (master lists) ----------
create table if not exists public.app_settings (
  id         int primary key default 1 check (id = 1),
  data       jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

-- ---------- permissions: เฉพาะผู้ใช้ที่ login แล้ว (คนในทีม) ----------
grant select, insert, update, delete on public.jobs, public.app_settings to authenticated;
grant usage, select on sequence public.job_no_seq to authenticated;
revoke all on public.jobs, public.app_settings from anon;

alter table public.jobs enable row level security;
alter table public.app_settings enable row level security;

drop policy if exists "team can read jobs"   on public.jobs;
drop policy if exists "team can insert jobs" on public.jobs;
drop policy if exists "team can update jobs" on public.jobs;
drop policy if exists "team can delete jobs" on public.jobs;
create policy "team can read jobs"   on public.jobs for select to authenticated using (true);
create policy "team can insert jobs" on public.jobs for insert to authenticated with check (true);
create policy "team can update jobs" on public.jobs for update to authenticated using (true) with check (true);
create policy "team can delete jobs" on public.jobs for delete to authenticated using (true);

drop policy if exists "team can read settings"   on public.app_settings;
drop policy if exists "team can write settings"  on public.app_settings;
drop policy if exists "team can update settings" on public.app_settings;
create policy "team can read settings"   on public.app_settings for select to authenticated using (true);
create policy "team can write settings"  on public.app_settings for insert to authenticated with check (true);
create policy "team can update settings" on public.app_settings for update to authenticated using (true) with check (true);

-- ---------- v3: ขนาดฐานข้อมูล (แจ้งเตือนเมื่อใกล้เต็ม 500 MB ของแผน Free) ----------
create or replace function public.db_usage() returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'db_bytes',   pg_database_size(current_database()),
    'jobs',       (select count(*) from public.jobs),
    'checked_at', now())
$$;
revoke all on function public.db_usage() from public, anon;
grant execute on function public.db_usage() to authenticated, service_role;

-- ---------- realtime: เห็นการแก้ไขของเพื่อนร่วมทีมทันที ----------
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'jobs') then
    alter publication supabase_realtime add table public.jobs;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'app_settings') then
    alter publication supabase_realtime add table public.app_settings;
  end if;
end $$;
