-- แก้ข้อมูลที่ import จาก Excel แล้ววันที่เป็นปี พ.ศ. (เช่น 2567) → ค.ศ.
-- รันครั้งเดียวใน Supabase → SQL Editor (แนะนำให้ Backup ก่อน — GitHub Actions หรือปุ่ม Backup JSON)
-- รันซ้ำได้: แตะเฉพาะค่าที่ปี >= 2400

-- 1) ดูก่อนว่าจะกระทบกี่งาน
select count(*) as jobs_to_fix
from public.jobs
where received_date >= '2400-01-01' or start_date >= '2400-01-01' or due_date >= '2400-01-01'
   or finish_date >= '2400-01-01' or deploy_std66_date >= '2400-01-01' or deploy_live_date >= '2400-01-01'
   or job_no ~ '^JOB-2[4-9]\d\d-';

-- 2) แปลงวันที่ทุกช่อง
update public.jobs set
  received_date     = case when received_date     >= '2400-01-01' then (received_date     - interval '543 years')::date else received_date     end,
  start_date        = case when start_date        >= '2400-01-01' then (start_date        - interval '543 years')::date else start_date        end,
  due_date          = case when due_date          >= '2400-01-01' then (due_date          - interval '543 years')::date else due_date          end,
  finish_date       = case when finish_date       >= '2400-01-01' then (finish_date       - interval '543 years')::date else finish_date       end,
  deploy_std66_date = case when deploy_std66_date >= '2400-01-01' then (deploy_std66_date - interval '543 years')::date else deploy_std66_date end,
  deploy_live_date  = case when deploy_live_date  >= '2400-01-01' then (deploy_live_date  - interval '543 years')::date else deploy_live_date  end
where received_date >= '2400-01-01' or start_date >= '2400-01-01' or due_date >= '2400-01-01'
   or finish_date >= '2400-01-01' or deploy_std66_date >= '2400-01-01' or deploy_live_date >= '2400-01-01';

-- 3) แก้ปีใน Job No (JOB-2569-0024 → JOB-2026-0024) — เลขลำดับไม่ซ้ำกันอยู่แล้วจึงไม่ชนกัน
update public.jobs
set job_no = 'JOB-' || (substring(job_no from 5 for 4)::int - 543) || substring(job_no from 9)
where job_no ~ '^JOB-2[4-9]\d\d-';

-- 4) ตรวจหาวันที่ที่ยังผิดปกติ (น่าจะพิมพ์ผิดใน Excel) — แก้ทีละงานในแอป
select job_no, received_date, due_date, left(project_name, 40) as project
from public.jobs
where due_date > current_date + interval '5 years' or received_date > current_date + interval '1 year'
order by due_date desc;
