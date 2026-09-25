---
name: playtest
description: Run, screenshot and play-test the Joffre (Kaiser) Rails app. Use when you need to start the dev server, build a game in a specific state (lobby, bidding, mid-trick, trick done, round 2 with a round summary, near win, done), simulate many full games to check scoring and dealing invariants, drive a real 4-player game in headless Chromium with Playwright, take desktop or phone (iPhone 13) screenshots, or otherwise verify game behavior end to end rather than only through unit tests.
---

# Play-testing Joffre

Helpers live in `script/playtest/`. They use the four seeded dev users (alice, bob, carol, david; password `Xk9#mP7$qR2@`) and create them if missing.

## 1. Build a game state (models only, ~2s)

```bash
bin/rails runner script/playtest/state.rb STATE [--max-score N] [--minimum-bid 7] [--move-dealer] [--seed N] [--json]
bin/rails runner script/playtest/state.rb show --game ID
```

| STATE | Result |
| --- | --- |
| `lobby` | 4 players joined, not started (Alice owns it) |
| `bidding` | round 1 dealt, no bids yet |
| `mid_trick` | first trick has 2 cards on the table |
| `trick_done` | first trick just completed (the "took the trick" view) |
| `round2` | round 1 scored, round 2 bidding with the round summary |
| `near_win` | the next card ends the game (plays real rounds; use `--max-score 21` to make it faster) |
| `done` | finished game, end screen |

It prints the game URL, each player's `user_id`, team, hand size and who must act. States are reached by really starting the game, bidding and playing legal cards through the models (`Playtest.step!` in `script/playtest/playtest.rb`), so they are always consistent. `bin/rails db:seed` also creates hand-crafted dev games ("Alice's Game", "Bidding Game", "Almost Done Game", "Near Win Game").

To look at a state in a browser, start the server and sign in as a player with the dev-only `POST /dev/switch_user` (what `browser.cjs` does), or click a player's name on a game page to switch to them.

## 2. Simulate many games (invariants)

```bash
bin/rails runner script/playtest/simulate.rb --games 10 --seed 42 [--max-score N] [--move-dealer] [--bid-chance 0.3] [--keep]
```

Checks every round gets a fresh 8-card deal per player, every round's points taken add up to 10 (8 tricks + 5 − 3), set bidders score −bid, and every finished game has exactly one winner with the higher score at or above the target. Exits 1 on any failure and prints the seed to reproduce it. Each game runs in a transaction that is rolled back (no dev DB clutter, no broadcasts) unless `--keep`. Expect about 1s per round (~7s per 41-point game). Bots bid the minimum occasionally and otherwise pass; random overbidding makes games run for hundreds of rounds.

## 3. Drive a real game in browsers

```bash
script/playtest/server start          # PORT=3000 by default, PID file in tmp/pids, log in log/playtest-server-3000.log
node script/playtest/browser.cjs --max-score 11 --seed 7
script/playtest/server stop
```

Creates a full lobby (or `--game ID` to drive an existing one), signs in 4 separate Chromium contexts, has the owner click Start Game, then bids and plays random legal cards through the UI until the end screen. After every click it waits for the acting page to change and for every other page (plus an iPhone 13 observer) to live-update without reloads, and exits 1 listing any page that did not update within `--stale-ms` (default 5000), any browser errors, or a game that did not finish. Screenshots go to `tmp/playtest/<timestamp>/`: `01-lobby`, `02-bidding`, `03-mid-trick`, `04-trick-done`, `05-round-summary`, `06-done` (+ `06-done-loser`), each as `-desktop.png` (1280×900) and `-phone.png`. Read them with the Read tool. An 11-point game takes about 6 minutes, mostly because the dev server re-renders `games#show` for 5 pages after each action; use `--no-phone` or a lower `--max-score` for speed.

For one-off screenshots, reuse the pieces: a state from step 1, then a short Playwright script modelled on `browser.cjs` (`signIn`, `screenshot`).

## Pitfalls (all hit in real sessions)

- **Playwright:** use the global package at `$(npm root -g)/playwright` (`/opt/node22/lib/node_modules/playwright`, which `browser.cjs` requires by path) and the preinstalled Chromium in `/opt/pw-browsers`. Never run `playwright install`, and never add a package.json or node_modules to the repo.
- **Login rate limit:** `SessionsController` allows 10 sign-ins per 3 minutes, counted in development's memory cache, so repeated runs get bounced to the sign-in page. Sign in with the development-only `POST /dev/switch_user` (`user_id`, `game_id`, CSRF token from any page) and reuse the saved `storageState` in `tmp/playtest/auth/`. Don't weaken production security to work around it.
- **Hover jitter:** `.bid-option:hover` moves the button 2px, so a mouse parked on its edge makes Playwright wait forever for "element is not stable". Call `page.mouse.move(0, 0)` before each click.
- **Turbo submits with fetch:** `waitForLoadState("networkidle")` doesn't mean the page updated, and the page still says "Your turn" right after the click, which leads to double actions. Wait for the acting page's `.phase-area .message`, hand or bid history to change.
- **Live updates:** game pages refresh themselves through Turbo morph (`turbo_stream_from @game`). Never reload in a harness; flag pages that don't update within a few seconds. Changes made from `bin/rails runner` or a console are not broadcast (development uses the in-process async cable adapter), so reload pages after building a state from the command line.
- **Stale memoization:** `Game#ordered_players` is memoized and `reload` doesn't clear it, so reusing one Game instance across rounds breaks dealer rotation. Use a fresh `Game.find(id)` per action, like a request does. Don't retry `place_bid!` on the same instance after a failed bid (the invalid bid stays in the association).
- **Runner speed:** set `ActiveRecord::Base.logger = nil` in runner simulations (`playtest.rb` does); logging makes them ~10x slower.
- **Killing processes:** never `pkill -f <pattern>` when the pattern also matches your own shell's command line; it kills the agent's shell (exit 144). Use PID files (`script/playtest/server stop`, or `kill "$(cat tmp/pids/….pid)"`).
- **Comparing against an old commit:** each git worktree has its own development secret (`tmp/local_secret.txt`), so copy it into the worktree for session cookies to stay valid, and symlink `storage/` to share the dev DB:
  ```bash
  git worktree add worktrees/before <commit>
  mkdir -p worktrees/before/tmp && cp tmp/local_secret.txt worktrees/before/tmp/
  rm -rf worktrees/before/storage && ln -s "$PWD/storage" worktrees/before/storage
  (cd worktrees/before && nohup bin/rails server -p 3001 -P tmp/pids/before.pid > log/before.log 2>&1 &)
  node script/playtest/browser.cjs --base-url http://localhost:3001 --game ID
  ```
- **Dev overlays:** the branch indicator and Signout button are fixed at the bottom in development and cover the hand on phone screenshots. Hide them while screenshotting (`page.screenshot({ style: ".branch-indicator, .dev-signout-form { display: none !important; }" })`).
