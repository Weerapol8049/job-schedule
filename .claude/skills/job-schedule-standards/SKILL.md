---
name: job-schedule-standards
description: Standards for changing the Job Schedule app (index.html, resume.html, portfolio.html, supabase/schema.sql, backup workflow). Use before adding or changing any feature, field, table, page or style in this repo, and before deploying, so the code, data model, UI, performance, security and docs stay consistent.
---

# Job Schedule — system standards

Single-page team app for logging and tracking IT jobs, plus a knowledge base.
Live: https://job-schedule-cyan.vercel.app · repo `Weerapol8049/job-schedule` (public) · Supabase project `raqwyoatasstnadwxkro`.
The UI and every reply to the user are in **Thai**; code and comments are in English.

## 1. Architecture: keep it buildless

- One HTML file per page: `index.html` (the app), `resume.html` (login required), `portfolio.html` (public), `manual.html` (user manual).
  No bundler, no npm, no framework. CSS and JS stay inline in the page.
- `config.js` holds `SUPABASE_URL` + the **anon** key only (safe in the browser because RLS guards the data).
  An empty config means local mode (`localStorage`), which must keep working: it is how the app is tested.
- External scripts come from cdnjs / jsdelivr with an **exact version**.
  Heavy libraries are never in `<head>`: load them through `loadLib('xlsx' | 'chart' | 'hljs' | 'md' | 'purify')` when the feature needs them.
  Only `supabase-js` loads up front.
- Push to `main` deploys to Vercel straight away. `.vercelignore` keeps `SETUP.md`, `supabase/`, `.github/` and `.claude/` off the site.

## 2. Code conventions (index.html)

- Helpers already exist, so use them instead of writing new ones: `$`, `$$`, `esc`, `icon(name, 'sm')`, `toast(msg, icon)`,
  `safe(async fn)` (catches errors, toasts them, re-renders), `clone`, `uniq`, `fmtDate`, `fmtDateTime`, `today()`, `iso()`,
  `getPrefs()/setPref()` for per-browser UI prefs, `displayTitle(j)`, `isDone(j)`, `statusColor()`.
- **Every value interpolated into HTML goes through `esc()`.** Notes and job text contain `<`, `</script>`, `$` and code.
- Views render through `render()` → `views[view](filteredJobs)`. Use `go(view)` to switch views. Prefer event delegation
  (the global click handler, `kbClick`) over per-element listeners for content that re-renders.
- Icons are `<symbol id="i-…">` in the sprite at the top of `<body>`. Add new icons there; don't inline SVG paths in templates.
- Match the surrounding style: short comments that explain *why*, compact template literals, no new global abstractions
  for a one-off.
- Keyboard shortcuts already exist: `N` new, `/` search, `1`–`6` views (dashboard, table, kanban, calendar, knowledge, api). Don't take those keys for anything else.

## 3. Data model

- Jobs: app field ↔ Postgres column via `DB_MAP` (+ `ARRAY_KEYS`, `BOOL_KEYS`, `NUM_KEYS`). Column metadata lives in `COLS`
  (label, Thai import aliases, type), which also drives the table, Excel import/export and the column picker.
- **Adding a job field** requires: a column in `supabase/schema.sql`, plus a `DB_MAP` entry, a `COLS` entry, the form field in `#jobDialog`,
  `emptyJob()`, and `DEFAULT_HIDDEN` if it shouldn't show by default.
- Knowledge notes: `title, category, tags[], body (markdown-ish: ``` fences, ###, -, ![cap](kb:path)), jobNos[], sourceUrl, pinned`.
  Fences may be longer than 3 backticks so a ```md block can contain ``` blocks: always build fences with `kbTicks(code)`,
  and parse with `KB_FENCE` (groups: 1 ticks, 2 lang, 3 code). Markdown blocks render via marked + DOMPurify (`kbHydrateMd`);
  after inserting a rendered body call `kbHydrate(root)` (images + Markdown).
  A note links to jobs **through `jobNos`**; there is no join table.
- API registry (`apis`, view `api`): field ↔ column via `API_MAP`; links through `jobNos` and `noteIds`. **`history`, `version` and the
  stamps on `tests` belong to the database trigger** (`apis_before_write`): the browser never sends `history`/`version`
  (see `apiToRow`), only appends to `tests`. Local mode imitates the trigger in `apiLocalAudit`; keep the two in step
  (field list = `API_FIELDS`, contract fields bump the version). Secrets in API fields go through `apiSecretCount` / `apiMaskSecrets`.
- Saving uses optimistic concurrency: `apiSaveJob/apiSaveNote/apiSaveApi(x, expectedUpdatedAt)` throws `err.conflict`, and the caller asks
  the user before overwriting. Keep this for any new write path.
- Dates are ISO `YYYY-MM-DD` in the Gregorian calendar. Thai sources often contain Buddhist years: convert on import with `ceYear()`, and never trust
  a year > 2400 (see `jobRange`, which ignores spans over 2 years). Existing bad rows are fixed with `supabase/fix-buddhist-years.sql`.

## 4. Database changes (Supabase)

There is **no CLI or service key here**: the user runs SQL themselves. So:
1. Append to `supabase/schema.sql` as a new numbered section (`-- ---------- vN: … ----------`). It must be **safe to re-run**:
   `create table if not exists`, `create or replace function`, `drop policy if exists` before `create policy`.
2. Every table: `enable row level security`, `revoke all … from anon`, and explicit policies.
   Team data uses `to authenticated using (true)`; personal data uses `user_id = (select auth.uid())`.
   Anything callable by `anon` must return **aggregates only**, never rows (pattern: `portfolio_stats()`, `security definer set search_path = public`).
3. Add a section `### อัปเดต schema (vN — <date>)` to `SETUP.md`: what it creates, and how to verify it after running.
4. Check that the change is live, read-only, with curl + the anon key (`PGRST205` = table missing, `PGRST202` = function missing).
   The app must degrade gracefully until the SQL is run: show a clear Thai message, or fall back to snapshot data.
5. If the table holds data worth keeping, add it to `.github/workflows/backup.yml`, using the same tolerant `if ! fetch …` pattern.

## 5. UI standards

- Use the design tokens on `:root` only (`--bg --surface --surface-2/3 --text --text-2 --muted --border --accent --ok --warn --danger --radius --shadow*`).
  Every colour must work in light **and** dark mode (`prefers-color-scheme` plus `[data-theme]`). Don't hard-code hex colours in new CSS.
- Font: IBM Plex Sans Thai, plus IBM Plex Mono for codes and Job No. Thai text never gets `letter-spacing` (it breaks vowel marks).
- Reuse components: `.card`, `.btn` (`primary/sm/ghost/danger`), `.icon-btn`, `.pill`, `.search-box`, `.list`, `.section h4`, `dialog.drawer/.modal`, `.kb-code`.
- Phones (≤640px): bottom `.tabbar` for the 5 main views, table rows render as cards, KPI tiles two per row.
  Any new view must be usable at 390px wide with no horizontal page scroll.
- Never lose the user's typing: don't overwrite a focused input on re-render (see `syncFilterUI`), and don't close a dialog with unsaved edits.
- Messages, labels, confirms and toasts are short Thai sentences. Destructive actions use `confirm()` and say what is kept.

## 6. Performance budgets (real data: ~900 jobs, ~300 notes)

- No view renders more than ~6k DOM nodes. Long lists page: the table shows `TABLE_PAGE` = 100 rows and loads more on scroll,
  Kanban shows `KANBAN_PAGE` = 30 cards per column.
- Text inputs that filter are debounced (~200 ms). Heavy rendering (note bodies, charts) is lazy: render on expand or on view.
- Measure before and after any change to rendering: `scripts/measure.js`. Reference numbers: table ~0.3 s, kanban ~0.06 s, dashboard < 0.1 s.

## 7. Security and privacy

- The repo is **public**. Never commit passwords, the service_role key, backups (`backup/` is git-ignored) or customer data.
  Don't open GitHub Issues containing job details.
- The knowledge base is readable by the whole team: keep the password scanner (`kbFindSecrets`) and the `<password>` replacement working.
- `portfolio.html` is public. It may only show aggregates from `portfolio_stats()`; never job titles, people, IPs or note content.
- Backups made by the workflow are GPG-encrypted. Keep it that way for any new table.

## 8. Test, then deploy

1. Syntax-check the inline scripts:
   `node -e "const h=require('fs').readFileSync('index.html','utf8');require('fs').writeFileSync(process.argv[1],[...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(x=>x[1]).join('\n;\n'))" <tmp>/app.js && node --check <tmp>/app.js`
2. Run the real app in local mode with real data: `node .claude/skills/job-schedule-standards/scripts/build-local.js index.html backup/<latest backup>.json <tmp dir>`
   writes `v-<view>.html` per view (config emptied, backup preloaded). Screenshot each view with headless Chrome at desktop (1440×900)
   and phone width. For phone width, load the page in a 390px `<iframe>`, because Windows headless won't shrink the window below ~500px.
   Use a separate `--user-data-dir` per run: views share `localStorage`.
3. For interactions, append a small probe `<script>` that drives the app (`openForm`, `go`, `.click()`) and writes results to
   `document.body.dataset.result`, then read them with `--dump-dom`. Use the real clock (no `--virtual-time-budget`) when timing.
4. Things only the user can test (Supabase login, realtime, Storage images): list them in the reply.
5. Commit with a message that says what changed and why, then push to `main`. Confirm the deploy by curling the live page for a marker from the change.
   Ask before pushing when the change is large or touches data. Tell the user to press **Ctrl+F5** once.

## 9. Documentation

- `SETUP.md`: the live configuration, schema versions and operations, for humans. Update it for every schema or ops change.
- `manual.html` + `manual/*.png`: the user manual. Update it when a visible workflow changes.
- Record any new public URL, Supabase setting or secret *location* (never the value) in SETUP.md.
