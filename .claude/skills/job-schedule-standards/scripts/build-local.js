// Builds local-mode copies of index.html preloaded with a backup, one file per view, for screenshots and probes.
// usage: node build-local.js <index.html> <backup.json> <outDir> [view,view,...]
//   → <outDir>/v-<view>.html  (config.js replaced: no Supabase, data and prefs written to localStorage first)
// The backup may be the app's own "Backup JSON" or the GitHub Actions export (same jobs/settings/notes shape).
const fs = require('fs'), path = require('path');
const [src, backup, outDir, viewArg] = process.argv.slice(2);
if (!src || !backup || !outDir) { console.error('usage: node build-local.js <index.html> <backup.json> <outDir> [views]'); process.exit(1); }

const html = fs.readFileSync(src, 'utf8');
if (!html.includes('<script src="config.js"></script>')) { console.error('config.js script tag not found in ' + src); process.exit(1); }
const b = JSON.parse(fs.readFileSync(backup, 'utf8'));
const data = JSON.stringify({ jobs: b.jobs || [], settings: b.settings || {}, seq: b.seq || (b.jobs || []).length, notes: b.notes || [] });
// notes contain "</script>" and "$" — escape for an inline script and use a function replacement
const lit = JSON.stringify(data).replace(/<\//g, '<\\/');
const views = (viewArg || 'dashboard,table,kanban,calendar,knowledge,settings').split(',');

fs.mkdirSync(outDir, { recursive: true });
for (const v of views) {
  const prefs = JSON.stringify(JSON.stringify({ view: v, theme: 'light' }));
  const inject = `<script>window.APP_CONFIG={};try{localStorage.setItem("jobSchedule.v1",${lit});localStorage.setItem("jobSchedule.prefs",${prefs});}catch(e){}</script>`;
  fs.writeFileSync(path.join(outDir, `v-${v}.html`), html.replace('<script src="config.js"></script>', () => inject));
}
console.log(`built ${views.length} views → ${outDir} (${(b.jobs || []).length} jobs, ${(b.notes || []).length} notes)`);
