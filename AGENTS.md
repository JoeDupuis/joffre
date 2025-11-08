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
