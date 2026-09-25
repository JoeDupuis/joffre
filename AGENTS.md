# Project
This is a card game project in rails. The game is call Joffre, I believe this is the french name, the game is called Kaiser in english.


# Stack
This is a rails project using the default stack:
- sqlite,
- solid queue/cable/cache
- hotwired (stimulus, turbo)
- Vanilla css

# Commands
- Run linter with `bundle exec rubocop -A`
- Run test with `bin/rails t`
- Run security static analysis with `bin/brakeman --no-pager`


# Worktrees
- A `/worktrees` directory exists for agent-specific worktrees. Only the `.keep`
  file is tracked; everything else is ignored so agents can work in parallel.

# Github
- Always make sure it passes tests, linter and static analysis before considering the task done or submitting a PR. Run them in parallel.

# Comments
- Do not put comments unless asked.

# Flash Messages
- Use `notice: success_message(...)` for success messages
- Use `alert: failure_message(...)` for failure messages
- See `app/controllers/games_controller.rb` or `app/controllers/games/players_controller.rb` for usage examples

# Migrations
- Always consolidate migrations inside a PR unless they represent distinct steps
- Distinct steps are separate operations like creating two different tables
- If iterating on the same table (e.g., create table then rename columns), edit the original migration instead of creating additional migrations
- Example: Creating a table and then renaming a column should be a single migration with the final column names

# Cloud sessions & play-testing
- Startup: the SessionStart hook (`.claude/scripts/setup-dependencies.sh`) puts the gem bin dir on `PATH`, installs the lockfile's Bundler, runs `bundle check || bundle install`, and prepares the dev and test DBs. Step timings are in `tmp/session-start.log`. Details and the recommended environment Setup script: `docs/cloud-sessions.md`.
- Checks run right after startup: `bin/rails t`, `bundle exec rubocop -A`, `bin/brakeman --no-pager`. If `bundle exec` says "command not found", the gem bin dir isn't on `PATH`; use `bin/rubocop` or rerun the hook.
- Play-testing: use the `playtest` skill (`.claude/skills/playtest/SKILL.md`) and `script/playtest/`: `state.rb` builds game states, `simulate.rb` runs many games checking invariants, `server` starts/stops the dev server with a PID file, `browser.cjs` plays a full 4-player game in Chromium with desktop and phone screenshots.
- Pitfalls:
  - Playwright: use the global package and the Chromium in `/opt/pw-browsers`; never `playwright install` or add a package.json.
  - Sign in via the dev-only `POST /dev/switch_user` and reuse `storageState`; the sign-in form is rate limited (10 per 3 minutes).
  - Call `page.mouse.move(0, 0)` before clicks; `.bid-option` hover jitter makes clicks wait forever.
  - Turbo submits with fetch: wait for the page's message, hand or bid history to change, not `networkidle`.
  - Pages live-update through Turbo morph; never reload in a harness, and flag pages that don't update.
  - Use a fresh `Game.find(id)` per action in scripts (`ordered_players` is memoized and survives `reload`).
  - Set `ActiveRecord::Base.logger = nil` in runner simulations.
  - Stop background processes with PID files, never `pkill -f` a pattern that matches your own shell.
  - Another worktree needs a copy of `tmp/local_secret.txt` for cookies to work and a symlinked `storage/` to share the dev DB.
  - Hide `.branch-indicator` and `.dev-signout-form` when screenshotting.
