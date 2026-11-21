# ¿ÉXITO O FRACASO? — multiplayer classroom game

Pages: `/` (players, Spanish) · `/admin.html` (presenter, English, PIN protected) · `/test.html` (QA tool)
Files: index.html, admin.html, test.html, game.js, config.js, style.css, schema.sql, vercel.json

## A. Supabase (10 min)
1. supabase.com > Sign up (free) > New project. Name it, choose a database password, pick a nearby region. Wait ~2 min.
2. Open `schema.sql` in a text editor. Find `'CHANGE-ME-1234'` and replace it with your own presenter PIN. Save.
3. Supabase > SQL Editor > New query > paste the whole file > Run. It must say "Success". (If you run it twice, the last line may complain that tables are already in the publication; that is fine.)
4. This project’s `config.js` is already populated with the supplied Project URL and publishable key.
   The Project URL is `https://xwqosemrpuitevpxmeaj.supabase.co` (without `/rest/v1/`).
   Never put a `service_role` or secret key in browser code.
5. Since the database schema was already run for this project, do not run `schema.sql` again unless you intentionally reset/rebuild the database. Keep your presenter PIN private.

## B. Vercel (10 min)
Easiest way (GitHub): create a free GitHub account > New repository > "uploading an existing file" > drag ALL project files > Commit. In Vercel: Add New > Project > Import that repository > Framework Preset: Other > leave Build/Output empty > Deploy.
CLI: install Node.js, then in the project folder run `npx vercel` and follow the prompts; `npx vercel --prod` to publish.
You get a URL like https://your-game.vercel.app

## C. QR code
Open https://your-game.vercel.app/admin.html on the laptop, enter the PIN. The QR is generated automatically from that address and points to the player page. Project it. Do not open the dashboard from localhost: phones cannot reach it.

## D. Test BEFORE class (required)
1. Open /admin.html on the laptop and /test.html in another tab.
2. test.html > "Security check": all lines should say PASS.
3. On 2 real phones (mobile data, not only your wifi), scan the QR and join. Names must appear on the dashboard within ~1 second.
4. test.html > enter PIN > "Join N test players" (10) > "Toggle auto-answer" ON.
5. Dashboard: Start game > Open round > watch answers and bars rise > Close > Reveal > Next... through round 5 > Show final winner. Phones must change screen by themselves each step.
6. test.html "game events received" must increase every time you press a dashboard button. If not, Realtime is not enabled (re-run the last line of schema.sql).
7. Clean up: test.html > Remove test players, then dashboard > Reset game.

## E. In class (5 min plan)
Join 60 s · 5 rounds x (open 20 s, reveal 10 s) · final 20 s. Set the timer box to 15 s for speed.

## Scoring
R1 engagement (max 10) · R2-R5 fit with the chosen story (max 20 each) · +4 in R4 if channel matches audience · +10 consistency bonus (+5) in R5. Max 100. Matrix is in `scoring` table; edit freely.

## Limits
Supabase free plan: 200 simultaneous realtime connections. Presenter PIN is the only protection (fine for a class). A player who clears browser data rejoins as a new player.
