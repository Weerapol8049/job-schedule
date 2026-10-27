// Measures render time (median of 3, ms) and DOM size per view on a page built by build-local.js.
// usage: node measure.js <outDir>/v-dashboard.html
// Needs Google Chrome; set CHROME to its path if it isn't in the default Windows location.
const fs = require('fs'), path = require('path'), os = require('os');
const { spawnSync } = require('child_process');
const file = process.argv[2];
if (!file) { console.error('usage: node measure.js <built page>'); process.exit(1); }

const chrome = process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const probe = `<script>addEventListener('load',()=>setTimeout(()=>{const r={};
for(const v of ['dashboard','table','kanban','calendar','knowledge']){const ts=[];
for(let i=0;i<3;i++){const t=performance.now();go(v);document.body.offsetHeight;ts.push(Math.round(performance.now()-t));}
r[v+'Ms']=ts.sort((a,b)=>a-b)[1];r[v+'Nodes']=document.getElementsByTagName('*').length;}
document.body.dataset.result=JSON.stringify(r);},0));</script>`;
const out = path.join(path.dirname(file), 'measure-probe.html');
fs.writeFileSync(out, fs.readFileSync(file, 'utf8').replace('</body>', () => probe + '</body>'));

// real clock on purpose: --virtual-time-budget freezes performance.now()
const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'js-measure-'));
const res = spawnSync(chrome, ['--headless=new', '--disable-gpu', `--user-data-dir=${profile}`, '--window-size=1440,900',
  '--dump-dom', 'file:///' + path.resolve(out).replace(/\\/g, '/')], { encoding: 'utf8', maxBuffer: 1 << 28 });
const m = (res.stdout || '').match(/data-result="([^"]*)"/);
if (!m) { console.error('no result — did the page load? ' + (res.stderr || '').slice(0, 300)); process.exit(1); }
console.table(JSON.parse(m[1].replace(/&quot;/g, '"')));
