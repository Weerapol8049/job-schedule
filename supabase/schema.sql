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

-- ---------- v4: คลังความรู้ (knowledge) + รูปใน Storage bucket "knowledge" ----------
create table if not exists public.knowledge (
  id               uuid primary key default gen_random_uuid(),
  title            text not null default '',
  category         text not null default '',
  tags             text[] not null default '{}',
  body             text not null default '',      -- ข้อความ + โค้ด (```x++ … ```) + รูป ![คำบรรยาย](kb:<path ใน bucket>)
  source_url       text not null default '',
  job_nos          text[] not null default '{}',  -- Job No ที่เกี่ยวข้อง
  pinned           boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  created_by       uuid default auth.uid() references auth.users(id) on delete set null,
  updated_by       uuid default auth.uid() references auth.users(id) on delete set null,
  updated_by_email text not null default ''
);
create index if not exists knowledge_job_nos_idx on public.knowledge using gin (job_nos);

create or replace function public.knowledge_before_write() returns trigger
language plpgsql set search_path = public as $$
begin
  new.updated_by_email := coalesce(auth.jwt() ->> 'email', '');
  if tg_op = 'UPDATE' then
    new.updated_at := now();
    new.updated_by := auth.uid();
    new.created_at := old.created_at;
    new.created_by := old.created_by;
  end if;
  return new;
end $$;

drop trigger if exists knowledge_before_write on public.knowledge;
create trigger knowledge_before_write before insert or update on public.knowledge
  for each row execute function public.knowledge_before_write();

grant select, insert, update, delete on public.knowledge to authenticated;
revoke all on public.knowledge from anon;
alter table public.knowledge enable row level security;

drop policy if exists "team can read knowledge"   on public.knowledge;
drop policy if exists "team can insert knowledge" on public.knowledge;
drop policy if exists "team can update knowledge" on public.knowledge;
drop policy if exists "team can delete knowledge" on public.knowledge;
create policy "team can read knowledge"   on public.knowledge for select to authenticated using (true);
create policy "team can insert knowledge" on public.knowledge for insert to authenticated with check (true);
create policy "team can update knowledge" on public.knowledge for update to authenticated using (true) with check (true);
create policy "team can delete knowledge" on public.knowledge for delete to authenticated using (true);

-- รูปเก็บแบบ private (ต้อง login ถึงจะเปิดได้) · จำกัด 5 MB ต่อไฟล์ (แอปย่อรูปเหลือราว 100 KB ก่อนอัปโหลด)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('knowledge', 'knowledge', false, 5242880, array['image/webp','image/png','image/jpeg','image/gif'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "team can read knowledge files"   on storage.objects;
drop policy if exists "team can upload knowledge files" on storage.objects;
drop policy if exists "team can update knowledge files" on storage.objects;
drop policy if exists "team can delete knowledge files" on storage.objects;
create policy "team can read knowledge files"   on storage.objects for select to authenticated using (bucket_id = 'knowledge');
create policy "team can upload knowledge files" on storage.objects for insert to authenticated with check (bucket_id = 'knowledge');
create policy "team can update knowledge files" on storage.objects for update to authenticated using (bucket_id = 'knowledge') with check (bucket_id = 'knowledge');
create policy "team can delete knowledge files" on storage.objects for delete to authenticated using (bucket_id = 'knowledge');

-- ---------- v3 (+v4): ขนาดฐานข้อมูล 500 MB และพื้นที่ Storage 1 GB ของแผน Free ----------
create or replace function public.db_usage() returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'db_bytes',      pg_database_size(current_database()),
    'jobs',          (select count(*) from public.jobs),
    'notes',         (select count(*) from public.knowledge),
    'storage_bytes', (select coalesce(sum((metadata ->> 'size')::bigint), 0) from storage.objects),
    'files',         (select count(*) from storage.objects),
    'checked_at',    now())
$$;
revoke all on function public.db_usage() from public, anon;
grant execute on function public.db_usage() to authenticated, service_role;

-- ---------- v5: Resume ส่วนตัว (resume.html) — แต่ละคนเห็นและแก้ได้เฉพาะของตัวเอง ----------
create table if not exists public.resumes (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data       jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

create or replace function public.resumes_before_write() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists resumes_before_write on public.resumes;
create trigger resumes_before_write before insert or update on public.resumes
  for each row execute function public.resumes_before_write();

grant select, insert, update, delete on public.resumes to authenticated;
revoke all on public.resumes from anon;
alter table public.resumes enable row level security;

drop policy if exists "owner can read resume"   on public.resumes;
drop policy if exists "owner can insert resume" on public.resumes;
drop policy if exists "owner can update resume" on public.resumes;
drop policy if exists "owner can delete resume" on public.resumes;
create policy "owner can read resume"   on public.resumes for select to authenticated using (user_id = (select auth.uid()));
create policy "owner can insert resume" on public.resumes for insert to authenticated with check (user_id = (select auth.uid()));
create policy "owner can update resume" on public.resumes for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "owner can delete resume" on public.resumes for delete to authenticated using (user_id = (select auth.uid()));

-- ---------- v6: สถิติสาธารณะสำหรับ portfolio.html ----------
-- คืนเฉพาะ "ตัวเลขรวม" (ไม่มีชื่องาน รายละเอียด หรือเนื้อหาบทความ) จึงเปิดให้ anon เรียกได้
create or replace function public.portfolio_stats() returns json
language sql stable security definer set search_path = public as $$
  with j as (
    select status, modules, system_name, project_name,
           case when received_date >= '2400-01-01' then (received_date - interval '543 years')::date else received_date end as d
    from public.jobs
  ), y as (
    select extract(year from d)::int as yr, count(*) as total,
           count(*) filter (where system_name ilike '%odoo%' or project_name ~* '^(buz|biz)_') as odoo
    from j where d is not null group by 1
  ), m as (
    select trim(x) as name, count(*) as n from j, unnest(modules) as x
    where trim(x) <> '' group by 1 order by n desc limit 8
  ), k as (
    select category as name, count(*) as n from public.knowledge
    where category <> '' group by 1 order by n desc limit 8
  )
  select json_build_object(
    'jobs',            (select count(*) from j),
    'done',            (select count(*) from j where status = 'เสร็จ'),
    'reports',         (select count(*) from j where system_name ~* '(report|รายงาน|form|ฟอร์ม)'),
    'first_date',      (select min(d) from j),
    'per_year',        (select coalesce(json_agg(json_build_object('year', yr, 'total', total, 'odoo', odoo) order by yr), '[]') from y),
    'modules',         (select coalesce(json_agg(json_build_object('name', name, 'n', n) order by n desc), '[]') from m),
    'notes',           (select count(*) from public.knowledge),
    'note_categories', (select coalesce(json_agg(json_build_object('name', name, 'n', n) order by n desc), '[]') from k),
    'updated_at',      now())
$$;
revoke all on function public.portfolio_stats() from public;
grant execute on function public.portfolio_stats() to anon, authenticated;

-- ---------- v7: ทะเบียน API (index.html → ทะเบียน API) ----------
-- history / version / tests are maintained here, not by the browser, so the audit trail can't be rewritten from the app:
--   history: one entry per edit (who, when, which fields, old values of the contract fields)
--   version: +1 whenever the contract changes (method, path, URLs, auth, headers, request, response)
--   tests:   append-only log of test results per environment
create table if not exists public.apis (
  id               uuid primary key default gen_random_uuid(),
  name             text not null default '',
  method           text not null default 'GET',
  path             text not null default '',
  url_std66        text not null default '',
  url_live         text not null default '',
  source_system    text not null default '',
  target_system    text not null default '',
  auth             text not null default '',      -- how to authenticate — never the secret itself (<password>)
  headers          text not null default '',
  request_sample   text not null default '',
  response_sample  text not null default '',
  errors           text not null default '',
  description      text not null default '',
  status           text not null default 'ร่าง',  -- ร่าง / ทดสอบ / ใช้งานจริง / เลิกใช้
  owner            text not null default '',
  tags             text[] not null default '{}',
  job_nos          text[] not null default '{}',
  note_ids         text[] not null default '{}',  -- knowledge.id of related notes
  tests            jsonb not null default '[]',
  history          jsonb not null default '[]',
  version          int not null default 1,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  created_by       uuid default auth.uid() references auth.users(id) on delete set null,
  updated_by       uuid default auth.uid() references auth.users(id) on delete set null,
  updated_by_email text not null default ''
);

create or replace function public.apis_before_write() returns trigger
language plpgsql as $$
declare
  who text := coalesce(auth.jwt() ->> 'email', '');
  changed text[];
  prev jsonb;
begin
  new.updated_by_email := who;
  if tg_op = 'INSERT' then
    new.version := 1;
    new.tests := coalesce(new.tests, '[]'::jsonb);
    new.history := jsonb_build_array(jsonb_build_object('at', now(), 'by', who, 'what', 'สร้าง', 'version', 1));
    return new;
  end if;
  new.created_at := old.created_at;
  new.created_by := old.created_by;
  new.updated_at := now();
  new.updated_by := auth.uid();
  -- tests: keep every old entry, accept only entries appended after them, stamped with the real user and time
  new.tests := old.tests || coalesce((select jsonb_agg(e || jsonb_build_object('by', who, 'at', now()) order by i)
                                      from jsonb_array_elements(coalesce(new.tests, '[]'::jsonb)) with ordinality t(e, i)
                                      where i > jsonb_array_length(old.tests)), '[]'::jsonb);
  prev := jsonb_strip_nulls(jsonb_build_object(
    'method',          case when new.method          is distinct from old.method          then old.method end,
    'path',            case when new.path            is distinct from old.path            then old.path end,
    'url_std66',       case when new.url_std66       is distinct from old.url_std66       then old.url_std66 end,
    'url_live',        case when new.url_live        is distinct from old.url_live        then old.url_live end,
    'auth',            case when new.auth            is distinct from old.auth            then old.auth end,
    'headers',         case when new.headers         is distinct from old.headers         then old.headers end,
    'request_sample',  case when new.request_sample  is distinct from old.request_sample  then old.request_sample end,
    'response_sample', case when new.response_sample is distinct from old.response_sample then old.response_sample end));
  new.version := old.version + case when prev <> '{}'::jsonb then 1 else 0 end;
  changed := array_remove(array[
    case when new.name          is distinct from old.name          then 'ชื่อ' end,
    case when new.method        is distinct from old.method        then 'Method' end,
    case when new.path          is distinct from old.path          then 'Path' end,
    case when new.url_std66     is distinct from old.url_std66     then 'URL STD66' end,
    case when new.url_live      is distinct from old.url_live      then 'URL LIVE' end,
    case when new.source_system is distinct from old.source_system
           or new.target_system is distinct from old.target_system then 'ระบบ' end,
    case when new.auth          is distinct from old.auth          then 'Auth' end,
    case when new.headers       is distinct from old.headers       then 'Headers' end,
    case when new.request_sample  is distinct from old.request_sample  then 'Request' end,
    case when new.response_sample is distinct from old.response_sample then 'Response' end,
    case when new.errors        is distinct from old.errors        then 'Errors' end,
    case when new.description   is distinct from old.description   then 'รายละเอียด' end,
    case when new.status        is distinct from old.status        then 'สถานะ → ' || new.status end,
    case when new.owner         is distinct from old.owner         then 'ผู้ดูแล' end,
    case when new.tags          is distinct from old.tags          then 'Tags' end,
    case when new.job_nos       is distinct from old.job_nos       then 'Job' end,
    case when new.note_ids      is distinct from old.note_ids      then 'ความรู้' end], null);
  new.history := old.history || case when cardinality(changed) > 0
    then jsonb_build_array(jsonb_build_object('at', now(), 'by', who, 'what', array_to_string(changed, ', '), 'version', new.version, 'prev', prev))
    else '[]'::jsonb end;
  return new;
end $$;

drop trigger if exists apis_before_write on public.apis;
create trigger apis_before_write before insert or update on public.apis
  for each row execute function public.apis_before_write();

grant select, insert, update, delete on public.apis to authenticated;
revoke all on public.apis from anon;
alter table public.apis enable row level security;

drop policy if exists "team can read apis"   on public.apis;
drop policy if exists "team can insert apis" on public.apis;
drop policy if exists "team can update apis" on public.apis;
drop policy if exists "team can delete apis" on public.apis;
create policy "team can read apis"   on public.apis for select to authenticated using (true);
create policy "team can insert apis" on public.apis for insert to authenticated with check (true);
create policy "team can update apis" on public.apis for update to authenticated using (true) with check (true);
create policy "team can delete apis" on public.apis for delete to authenticated using (true);

-- ---------- realtime: เห็นการแก้ไขของเพื่อนร่วมทีมทันที ----------
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'jobs') then
    alter publication supabase_realtime add table public.jobs;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'app_settings') then
    alter publication supabase_realtime add table public.app_settings;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'knowledge') then
    alter publication supabase_realtime add table public.knowledge;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'apis') then
    alter publication supabase_realtime add table public.apis;
  end if;
end $$;
