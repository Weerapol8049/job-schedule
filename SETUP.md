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
| Schema | รัน `supabase/schema.sql` แล้ว — ตาราง `jobs`, `app_settings`, RLS เฉพาะผู้ใช้ที่ login, realtime เปิดแล้ว · **v4 (คลังความรู้) ต้องรันเพิ่ม** ดูหัวข้อ "อัปเดต schema (v4)" |
| Auth | Email + Password · ปิดการสมัครเอง (`disable_signup = true`) |
| เพิ่มผู้ใช้ | Authentication → Users → Add user → Create new user → ติ๊ก **Auto Confirm User** |

ข้อจำกัดแผน Free:
- project ถูก **pause หลังไม่มีการใช้งาน 7 วัน** → GitHub Actions backup รายวัน (ด้านล่าง) เรียกฐานข้อมูลทุกวันจึงช่วยกันไว้ ถ้ายัง pause ให้เข้า dashboard กด Restore
- Supabase ไม่มี backup ให้ในแผน Free → ใช้ **backup อัตโนมัติผ่าน GitHub Actions** + ปุ่ม *Backup JSON* ในแอปเป็นครั้งคราว

### Backup อัตโนมัติรายวัน (GitHub Actions)
ไฟล์ `.github/workflows/backup.yml` — ทุกวัน 01:00 น. ดึงตาราง `jobs` + `app_settings` + `knowledge` และรูปในคลังความรู้ → **เข้ารหัส AES-256** → เก็บใน Actions artifacts 90 วัน
(artifact มี 2 ไฟล์: `job-schedule-backup-*.json.gpg` = ข้อมูล, `job-schedule-images-*.tar.gpg` = รูป — มีเฉพาะเมื่อมีรูป)
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
3. ในแอป: ข้อมูล & ตั้งค่า → **Restore JSON** → เลือก `backup.json` (แทนที่งานและคลังความรู้ทั้งหมด)
4. ถ้ารูปใน Storage หายด้วย: `gpg -d job-schedule-images-YYYY-MM-DD.tar.gpg > images.tar` → `tar -xf images.tar -C images` → Supabase → Storage → bucket `knowledge` → อัปโหลดโฟลเดอร์ปี (เช่น `2026/`) ให้ path ตรงเดิม

หมายเหตุ: GitHub จะปิด scheduled workflow อัตโนมัติถ้า repo public ไม่มีความเคลื่อนไหว 60 วัน — ถ้าได้อีเมลแจ้ง ให้เข้าแท็บ Actions กด Enable

### แจ้งเตือนข้อจำกัดแผน Free
| เหตุการณ์ | แจ้งทาง |
|---|---|
| ฐานข้อมูลเกิน 80% ของ 500 MB | GitHub Issue ป้าย `db-alert` (อีเมลถึงเจ้าของ repo) + แถบเตือนในแอป (แดงเมื่อเกิน 90%) — ปิด issue เองเมื่อต่ำกว่า 80% |
| Backup รายวันล้มเหลว | GitHub Issue ป้าย `backup-failed` + อีเมล workflow failed ของ GitHub + แถบเตือนในแอป — ปิด issue เองเมื่อรันสำเร็จ |
| ไม่มี backup สำเร็จเกิน 36 ชม. (เช่น GitHub ปิด schedule) | แถบเตือนในแอป |
| เชื่อมต่อฐานข้อมูลไม่ได้ (project ถูก pause) | แถบเตือนในแอป + backup รายวันล้มเหลว → issue |
| Storage (รูปในคลังความรู้) เกิน 80% ของ 1 GB | GitHub Issue ป้าย `storage-alert` + แถบเตือนในแอป — ปิด issue เองเมื่อต่ำกว่า 80% |

ต้องรัน `supabase/schema.sql` (v3 — เพิ่มฟังก์ชัน `db_usage()`) ก่อน จึงจะวัดขนาดฐานข้อมูลได้ ·
ตั้งค่าใน `config.js`: `GITHUB_REPO` (repo ที่รัน backup), `DB_LIMIT_MB` และ `STORAGE_LIMIT_MB` (เปลี่ยนเมื่ออัปเกรดแผน — แก้ใน `backup.yml` ด้วย)
ให้แน่ใจว่าได้รับอีเมล: GitHub → Settings → Notifications → Actions = "Only notify for failed workflows" และ Watch repo นี้ (ค่าเริ่มต้นของเจ้าของ repo)

### อัปเดต schema (v7 — 28 ต.ค. 2026): ทะเบียน API
รัน `supabase/schema.sql` ซ้ำใน SQL Editor 1 ครั้ง (ไม่ทำข้อมูลหาย) — สร้างตาราง `apis` + RLS (ทีมที่ login อ่าน/เขียนได้, anon ไม่ได้) + realtime + trigger `apis_before_write`
- trigger เป็นผู้บันทึก **history** (ใคร/เมื่อไหร่/แก้ช่องไหน + ค่าเดิมของช่องที่เป็นสัญญา API), เพิ่ม **version** เมื่อ Method / Path / URL / Auth / Headers / Request / Response เปลี่ยน และทำให้ **tests** (ผลทดสอบ) เพิ่มได้อย่างเดียว พร้อมประทับชื่อผู้ทดสอบและเวลาจริง — แก้จากแอปไม่ได้ จึงใช้ตรวจสอบย้อนหลังได้
- backup รายวันรวมตาราง `apis` แล้ว (ฟิลด์ `apis` ในไฟล์ JSON)
- ก่อนรัน SQL หน้า "ทะเบียน API" จะขึ้นแถบเตือน ส่วนอื่นของแอปใช้งานได้ปกติ

ตรวจหลังรัน: Table Editor → ต้องเห็นตาราง `apis` · เปิดแอป → ทะเบียน API → เพิ่ม API ทดสอบ → แก้ Request แล้วบันทึก → ต้องขึ้น v2 และมีรายการในประวัติ → กด ✓ ผ่าน ที่แถว STD66 → ประวัติต้องมีผลทดสอบพร้อมอีเมลผู้ทดสอบ

### อัปเดต schema (v6 — 23 ต.ค. 2026): สถิติสาธารณะให้ Portfolio
รัน `supabase/schema.sql` ซ้ำใน SQL Editor 1 ครั้ง — สร้างฟังก์ชัน `portfolio_stats()` ที่ `portfolio.html` เรียกด้วย anon key
- คืนค่าเฉพาะตัวเลขรวม: จำนวนงาน, งานรายงาน/ฟอร์ม, จำนวนงานต่อปี (แยก Odoo), โมดูลที่ทำบ่อย 8 อันดับ, จำนวนบทความตามหมวด 8 อันดับ — **ไม่มี** ชื่องาน รายละเอียด หรือเนื้อหาบทความ
- ก่อนรัน (หรือถ้าเรียกไม่สำเร็จ) หน้า Portfolio แสดงตัวเลข snapshot ที่เขียนไว้ในไฟล์แทน
- ถ้าไม่อยากเปิดตัวเลขเหล่านี้สู่สาธารณะ: `revoke execute on function public.portfolio_stats() from anon;`

ตรวจหลังรัน: เปิด `/portfolio.html` → ใต้หัวข้อ "จากบันทึกงานจริง" ต้องขึ้น "อัปเดตอัตโนมัติจาก Job Schedule · ข้อมูล ณ <วันนี้>"

### อัปเดต schema (v5 — 23 ต.ค. 2026): Resume ต้อง login
รัน `supabase/schema.sql` ซ้ำใน SQL Editor 1 ครั้ง (ไม่ทำข้อมูลหาย) — สร้างตาราง `resumes` (1 แถวต่อผู้ใช้, เก็บข้อมูล Resume เป็น JSON) + RLS ให้แต่ละคนอ่าน/แก้ได้เฉพาะของตัวเอง

- `resume.html` ใช้บัญชีเดียวกับแอปหลัก (login ที่หน้าไหนก็เข้าได้ทั้งคู่) และบันทึกขึ้น Supabase อัตโนมัติ
- ครั้งแรกที่ login ถ้าเบราว์เซอร์นั้นมี Resume เวอร์ชันเก่า (ก่อนมี login) จะย้ายขึ้น Supabase ให้แล้วลบออกจากเบราว์เซอร์
- backup รายวันรวมตาราง `resumes` ด้วย (ฟิลด์ `resumes` ในไฟล์ JSON)
- `portfolio.html` ยังเปิดสาธารณะ ไม่ต้อง login

ตรวจหลังรัน: Table Editor → ต้องเห็นตาราง `resumes` · เปิด `/resume.html` → login → แก้ข้อมูล → มุมขวาบนต้องขึ้น "บันทึกแล้ว"

### อัปเดต schema (v4 — 20 ต.ค. 2026): คลังความรู้
รัน `supabase/schema.sql` ซ้ำใน SQL Editor 1 ครั้ง (ไม่ทำข้อมูลหาย) — สร้าง:
- ตาราง `knowledge` (หัวข้อ, หมวด, tags, เนื้อหา, Job No ที่เกี่ยวข้อง, ปักหมุด) + RLS + realtime
- Storage bucket `knowledge` แบบ **private** (ต้อง login ถึงจะเปิดรูปได้) จำกัด 5 MB/ไฟล์ ชนิด webp/png/jpeg/gif + policy ให้ผู้ใช้ที่ login อ่าน/อัปโหลด/ลบได้
- `db_usage()` คืนค่า `storage_bytes`, `files`, `notes` เพิ่ม (ใช้แสดง/เตือนพื้นที่รูป)

ตรวจหลังรัน: Storage → ต้องเห็น bucket `knowledge` · เปิดแอป → คลังความรู้ → เพิ่มเรื่องที่มีรูป → ข้อมูล & ตั้งค่า → สถานะระบบ ต้องเห็นแถว "พื้นที่รูป (Storage)"
รูปถูกย่อในเบราว์เซอร์ก่อนอัปโหลด (กว้างไม่เกิน 1600px, WebP ราว 80–150 KB) → 1 GB เก็บได้ประมาณ 7,000–10,000 รูป

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
