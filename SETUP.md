# Job Schedule — ติดตั้ง Supabase + Vercel

## ค่าที่ใช้งานจริง (อัปเดต 17 ต.ค. 2026)

> ไฟล์นี้ไม่มีรหัสผ่าน/secret — **ห้าม** จดรหัสผ่านผู้ใช้, database password หรือ `service_role` key ลงใน repo

### เว็บที่ใช้งาน
- **Production:** https://job-schedule-cyan.vercel.app

### Supabase
| รายการ | ค่า |
|---|---|
| Organization / Project | Weerapol_JD (แผน Free) |
| Project ref | `raqwyoatasstnadwxkro` |
| Project URL | https://raqwyoatasstnadwxkro.supabase.co |
| Dashboard | https://supabase.com/dashboard/project/raqwyoatasstnadwxkro |
| Region / Compute | Northeast Asia (Tokyo) `ap-northeast-1` · Nano |
| anon key | อยู่ใน `config.js` (Legacy API Keys → anon/public — เปิดเผยได้) |
| Schema | รัน `supabase/schema.sql` แล้ว — ตาราง `jobs`, `app_settings`, RLS เฉพาะผู้ใช้ที่ login, realtime เปิดแล้ว |
| Auth | Email + Password · ปิดการสมัครเอง (`disable_signup = true`) |
| เพิ่มผู้ใช้ | Authentication → Users → Add user → Create new user → ติ๊ก **Auto Confirm User** |

ข้อจำกัดแผน Free:
- project ถูก **pause หลังไม่มีการใช้งาน 7 วัน** → GitHub Actions backup รายวัน (ด้านล่าง) เรียกฐานข้อมูลทุกวันจึงช่วยกันไว้ ถ้ายัง pause ให้เข้า dashboard กด Restore
- Supabase ไม่มี backup ให้ในแผน Free → ใช้ **backup อัตโนมัติผ่าน GitHub Actions** + ปุ่ม *Backup JSON* ในแอปเป็นครั้งคราว

### Backup อัตโนมัติรายวัน (GitHub Actions)
ไฟล์ `.github/workflows/backup.yml` — ทุกวัน 01:00 น. ดึงตาราง `jobs` + `app_settings` → **เข้ารหัส AES-256** → เก็บใน Actions artifacts 90 วัน
(repo เป็น public จึงต้องเข้ารหัส — artifact ของ repo public ผู้ใช้ GitHub ทุกคนดาวน์โหลดได้)

ตั้งค่าครั้งเดียว: GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**
| Name | ค่า |
|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Project Settings → API Keys → Legacy API Keys → `service_role` (กด Reveal) |
| `BACKUP_PASSPHRASE` | รหัสผ่านยาว ๆ ที่ตั้งเอง — **จดเก็บไว้ในที่ปลอดภัย** ถ้าลืมจะเปิดไฟล์ backup ไม่ได้ |

ทดสอบ: แท็บ **Actions → Daily Supabase backup → Run workflow** → รอเขียว → ดาวน์โหลด artifact ด้านล่างของหน้า run

กู้คืนจาก backup:
1. ดาวน์โหลด artifact (.zip) → แตกไฟล์ได้ `job-schedule-backup-YYYY-MM-DD.json.gpg`
2. เปิด Git Bash แล้วถอดรหัส: `gpg -d job-schedule-backup-YYYY-MM-DD.json.gpg > backup.json` (ใส่ BACKUP_PASSPHRASE)
3. ในแอป: ข้อมูล & ตั้งค่า → **Restore JSON** → เลือก `backup.json` (แทนที่ข้อมูลทั้งหมด)

หมายเหตุ: GitHub จะปิด scheduled workflow อัตโนมัติถ้า repo public ไม่มีความเคลื่อนไหว 60 วัน — ถ้าได้อีเมลแจ้ง ให้เข้าแท็บ Actions กด Enable

### อัปเดต schema (v2 — 17 ต.ค. 2026)
รัน `supabase/schema.sql` ซ้ำใน SQL Editor 1 ครั้ง (ไม่ทำข้อมูลหาย) — เพิ่มคอลัมน์ `updated_by_email` เพื่อให้คำเตือน "มีคนแก้งานนี้ไปก่อน" บอกได้ว่าใครแก้

### GitHub
- Repo: https://github.com/Weerapol8049/job-schedule · branch `main`

### Vercel
| รายการ | ค่า |
|---|---|
| Team | weerapol8049's projects (แผน Hobby) |
| Project | `job-schedule` · Preset **Other** · Root `./` · ไม่มี build · ไม่มี Environment Variables |
| Production domain | https://job-schedule-cyan.vercel.app |
| Branch domain | https://job-schedule-git-main-weerapol8049-projects.vercel.app |
| Deploy | อัตโนมัติเมื่อ push ขึ้น `main` |
| ไม่เผยแพร่ | `SETUP.md`, `supabase/` (กำหนดใน `.vercelignore` — ตรวจแล้วได้ 404) |

> Vercel Hobby ใช้ได้เฉพาะงานที่ไม่ใช่เชิงพาณิชย์ — ถ้าใช้เป็นเครื่องมือของบริษัทระยะยาว พิจารณาแผน Pro

### งานที่ทำบ่อย
| ต้องการ | ทำที่ |
|---|---|
| เพิ่ม/ลบสมาชิก, รีเซ็ตรหัสผ่าน | Supabase → Authentication → Users |
| แก้โค้ดหน้าเว็บ | แก้ไฟล์ → `git push` → Vercel deploy เอง (~1 นาที) |
| แก้โครงสร้างตาราง | แก้ `supabase/schema.sql` → รันใน SQL Editor |
| ดูข้อมูลดิบ | Supabase → Table Editor → `jobs` |
| สำรองข้อมูล | อัตโนมัติทุกวัน (GitHub Actions) · หรือในแอป: ข้อมูล & ตั้งค่า → Backup JSON / Export Excel |
| แจ้ง deploy | ตาราง → เลือกงาน → **Release note** → Copy ไปวางในกลุ่ม → **ติ๊ก LIVE ให้ N งาน** |

---

## 1. สร้างฐานข้อมูล (Supabase)
1. สมัคร/เข้า https://supabase.com → **New project** (Region แนะนำ Singapore)
2. ไปที่ **SQL Editor** → วางเนื้อหาไฟล์ `supabase/schema.sql` → **Run**
3. **Authentication → Sign In / Providers**: ปิด *Allow new users to sign up* (ให้เฉพาะคนที่ admin เพิ่มเข้าใช้ได้)
4. **Authentication → Users → Add user → Create new user**: ใส่อีเมล + รหัสผ่านของสมาชิกแต่ละคน และติ๊ก *Auto Confirm User*

## 2. เชื่อมหน้าเว็บกับ Supabase
1. **Project Settings → API** คัดลอก *Project URL* และ *anon public key*
2. ใส่ใน `config.js`
   ```js
   window.APP_CONFIG = {
     SUPABASE_URL: 'https://xxxx.supabase.co',
     SUPABASE_ANON_KEY: 'eyJ...',
   };
   ```
   > anon key เปิดเผยได้ (สิทธิ์ถูกคุมด้วย Row Level Security) — **ห้าม** ใส่ `service_role` key
3. เปิด `index.html` → จะขึ้นหน้า Login → เข้าสู่ระบบ
4. ถ้ามีข้อมูลเดิมจากโหมดเก็บในเครื่อง: เมนู **ข้อมูล & ตั้งค่า → ย้ายข้อมูลในเครื่องขึ้น Supabase**

## 3. Deploy ขึ้น Vercel
ไม่ต้อง build — เป็นไฟล์ static (`index.html` + `config.js`)

**แบบ CLI**
```bash
npm i -g vercel
cd job-schedule
vercel          # ครั้งแรก: login + สร้าง project (preview)
vercel --prod   # deploy จริง
```

**แบบ GitHub**: push โฟลเดอร์นี้ขึ้น GitHub → Vercel → *Add New Project* → Import repo → Framework: **Other** → Deploy

> Vercel Hobby (ฟรี) จำกัดการใช้งานที่ไม่ใช่เชิงพาณิชย์ — ถ้าใช้ในบริษัทควรใช้แผน Pro หรือ host static ที่อื่น (เช่น Cloudflare Pages) ได้เหมือนกัน

## หมายเหตุ
- Supabase free tier: DB 500 MB, project จะถูก pause ถ้าไม่มีการใช้งาน 7 วัน (กด Restore ใน dashboard ได้)
- แก้ไขพร้อมกันหลายคน: ใช้หลัก "บันทึกล่าสุดชนะ" และทุกคนเห็นการเปลี่ยนแปลงแบบ realtime
- ไม่ได้กรอก `config.js` = แอปทำงานแบบเก็บข้อมูลในเครื่อง (localStorage) เหมือน prototype
