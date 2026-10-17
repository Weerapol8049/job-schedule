# Job Schedule — ติดตั้ง Supabase + Vercel

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
