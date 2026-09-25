# Cloud sessions

Claude Code cloud sessions clone `main` into a fresh container and run the repo's SessionStart hook (`.claude/settings.json` → `.claude/scripts/setup-dependencies.sh`, only when `CLAUDE_CODE_REMOTE=true`). Changes to the hook take effect for new sessions once they are merged to `main`.

## What the hook does

Each step is timed; the timings are printed to the session and written to `tmp/session-start.log`.

1. Puts RubyGems' executable directory (`/opt/rbenv/versions/3.3.6/bin`) on `PATH` through `$CLAUDE_ENV_FILE`, which Claude Code sources before every Bash command.
2. Installs the Bundler version from `Gemfile.lock` (`BUNDLED WITH`) if it's missing, and exports `BUNDLER_VERSION` so Bundler never has to install itself and restart.
3. `bundle check || bundle install --jobs "$(nproc)" --retry 3`.
4. `bin/rails db:prepare db:test:prepare` in one boot, so the dev database (with seeds) and the test database are ready.

It is idempotent and runs on `startup` and `resume`.

### Why `bundle exec rubocop` used to fail

The container's `ruby`, `gem` and `bundle` are symlinks in `/usr/local/bin` to a Ruby whose `Gem.bindir` is `/opt/rbenv/versions/3.3.6/bin`, and that directory isn't on `PATH`. Gems install their executables there, so `bundle exec rubocop` (which looks the command up on `PATH`) said "command not found" while `bin/rubocop` (which loads the gem directly) worked. It had nothing to do with Bundler 4 vs 2.6.6. The "Bundler 4.0.9 is running … restarting" message and the "Clearing out unresolved specs" warning (several installed versions of a gem such as brakeman) were harmless noise.

## Timings (4 vCPU container)

| Step | Before | After |
| --- | --- | --- |
| Bundler 4 → 2.6.6 switch | ~1.4s install + restart on every cold start | 0.4s check (1.7s once when missing) |
| `bundle install`, cold (130 gems, native extensions) | ~55s | ~55s (already parallel; `--jobs 1` would be ~126s) |
| `bundle install`, gems already in the container | ~0.6s | 0.3s (`bundle check`) |
| Dev + test DB | not prepared; first `bin/rails t` or server paid ~7–10s | 1.9s warm, ~7–10s on a brand-new DB |
| `bundle exec rubocop` | broken | works |
| Whole hook, gems cached | 0.6–1.4s, then a broken `bundle exec` and unprepared DBs | ~2.7s, everything ready |

The cold gem install dominates a brand-new environment. Cloud environments snapshot the container after setup, so later sessions normally find the gems already installed and only pay the ~2.7s warm path. The hook stays synchronous so tests and linters are guaranteed to work on the first command; an async hook would save about 2s per session but can race the first `bin/rails t`.

## Recommended environment Setup script

Paste this in claude.ai → the cloud environment menu in a session's title bar → **Edit** → **Setup script**:

```bash
#!/bin/bash
set -euo pipefail

GEM_BINDIR="$(ruby -e 'print Gem.bindir')"
grep -qs "$GEM_BINDIR" /root/.bashrc || echo "export PATH=\"$GEM_BINDIR:\$PATH\"" >> /root/.bashrc
gem list --installed bundler --version 2.6.6 > /dev/null || gem install bundler --version 2.6.6 --no-document
```

Tradeoffs versus the repo hook:

- The Setup script runs once per environment, before Claude Code starts, and its result is snapshotted for later sessions, so this costs nothing per session. It also fixes `PATH` for every shell, including ones that don't source `$CLAUDE_ENV_FILE`.
- It lives outside the repo: changing it means editing the environment by hand, it doesn't follow `Gemfile.lock` (update `2.6.6` when `BUNDLED WITH` changes), and it only helps the environments that have it.
- The repo hook already does both steps, so the Setup script is optional hardening. Gems stay in the hook because they must follow whichever branch's `Gemfile.lock` is checked out.
