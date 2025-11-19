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
