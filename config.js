// การเชื่อมต่อ Supabase — ดูค่าได้ที่ Supabase Dashboard → Project Settings → API
//   SUPABASE_URL      = Project URL       เช่น https://abcdefgh.supabase.co
//   SUPABASE_ANON_KEY = anon public key   (ปลอดภัยที่จะอยู่ฝั่ง browser เพราะสิทธิ์ถูกคุมด้วย Row Level Security)
// ห้ามใส่ service_role key ในไฟล์นี้เด็ดขาด
// ปล่อยว่างทั้งคู่ = ใช้โหมดเก็บข้อมูลในเครื่อง (localStorage) เหมือน prototype
window.APP_CONFIG = {
  SUPABASE_URL: "https://raqwyoatasstnadwxkro.supabase.co",
  SUPABASE_ANON_KEY:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhcXd5b2F0YXNzdG5hZHd4a3JvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyNDAzMDAsImV4cCI6MjEwNzgxNjMwMH0.GnLFtCA4PRqz6Gv0RQSJUsnqBIxQ6x6GSpo-jF7Vu2w",
};
