// การเชื่อมต่อ Supabase — ดูค่าได้ที่ Supabase Dashboard → Project Settings → API
//   SUPABASE_URL      = Project URL       เช่น https://abcdefgh.supabase.co
//   SUPABASE_ANON_KEY = anon public key   (ปลอดภัยที่จะอยู่ฝั่ง browser เพราะสิทธิ์ถูกคุมด้วย Row Level Security)
// ห้ามใส่ service_role key ในไฟล์นี้เด็ดขาด
// ปล่อยว่างทั้งคู่ = ใช้โหมดเก็บข้อมูลในเครื่อง (localStorage) เหมือน prototype
window.APP_CONFIG = {
  SUPABASE_URL: "https://raqwyoatasstnadwxkro.supabase.co",
  SUPABASE_ANON_KEY:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhcXd5b2F0YXNzdG5hZHd4a3JvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyNDAzMDAsImV4cCI6MjEwNzgxNjMwMH0.GnLFtCA4PRqz6Gv0RQSJUsnqBIxQ6x6GSpo-jF7Vu2w",
  // repo ที่รัน backup อัตโนมัติ — ใช้แสดงสถานะ backup ล่าสุดในแอป (ปล่อยว่าง = ไม่ตรวจ)
  GITHUB_REPO: "Weerapol8049/job-schedule",
  // ขนาดฐานข้อมูลสูงสุดของแผน Supabase ที่ใช้ (Free = 500 MB)
  DB_LIMIT_MB: 500,
  // พื้นที่ Storage (รูปในคลังความรู้) ของแผนที่ใช้ (Free = 1 GB)
  STORAGE_LIMIT_MB: 1024,
};
