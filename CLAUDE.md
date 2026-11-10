# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Open tasks live in [TODO.md](TODO.md) — check it at the start of a session and update it when you finish or add work.**

## Project

HypeBusted.com: a Rails 8.1 / Ruby 4.0.9 app where a single admin publishes tool reviews, multi-tool comparisons, and daily "journal" posts. Hotwire + importmap + Propshaft + Tailwind (`tailwindcss-rails`). Deployed with Kamal (`config/deploy.yml`, `.kamal/`).

## Commands

```sh
bin/setup                      # install deps, prepare DB, start server (--skip-server to not start)
bin/dev                        # runs Procfile.dev: rails server + tailwindcss:watch (needed for CSS changes)
bin/rails test                 # full suite
bin/rails test test/models/post_test.rb          # one file
bin/rails test test/models/post_test.rb:12       # one test by line
bin/rubocop                    # rubocop-rails-omakase style
bin/brakeman                   # security scan
bin/ci                         # full CI pipeline locally (config/ci.rb): setup, rubocop, bundler-audit, importmap audit, brakeman, tests, seeds replant
```

System tests (`bin/rails test:system`) are disabled in `bin/ci` and commented out in `.github/workflows/ci.yml`; `test/system` does not exist.

## Architecture

- **Database is PostgreSQL** (`config/database.yml`, `pg` gem; dbs `hypebusted_development`/`hypebusted_test`). Production points primary, cache, queue, and cable all at `DATABASE_URL`, so every table lives in one database. Solid Queue and Solid Cache tables come from `db/migrate`. The `db/*_schema.rb` files were removed; the `solid_cable_messages` table is created by a migration in `db/migrate`.
- **Content model**: `Post` (`post_type` enum: review/comparison/journal, with `_post_type` suffix e.g. `review_post_type?`; optional `youtube_video_id`, `published_at`) ↔ `Tag` via `Tagging` join. `Post` and `Tag` auto-generate `slug` via `parameterize` in `before_validation` when blank.
- **Admin UI is Avo** mounted at `/milo` (`root_path` in `config/initializers/avo.rb`; `mount_avo` in `config/routes.rb`). Resources live in `app/avo/resources/` (Post, Tag, Tagging); matching stub controllers in `app/controllers/avo/`. Access requires login plus `super_admin`: `Avo::ApplicationController` includes `Authentication` and redirects non-super-admins to `/`. `/milo/avo_private/status` is also protected. `/avo` no longer exists. Public pages: `HomeController#index` at root, `PostsController#show` at `/posts/:slug` (slug via `Post#to_param`), and `/sitemap.xml`. Styling lives in `app/assets/tailwind/utilities.css` (self-hosted fonts in `app/assets/fonts`).
- **Auth** is the Rails 8 generated authentication, separate from Avo: `Authentication` concern (`app/controllers/concerns/authentication.rb`) requires login by default via a signed `session_id` cookie → `Session` record; `Current.session`/`Current.user` hold the request state. Controllers opt out with `allow_unauthenticated_access`. `User` uses `has_secure_password`; `PasswordsController` + `PasswordsMailer` handle resets. Test helper: `test/test_helpers/session_test_helper.rb`.
- Rails 8 "Solid" stack replaces Redis: Solid Queue (jobs, `bin/jobs`), Solid Cache, Solid Cable.
- `ApplicationController` uses `allow_browser versions: :modern`, so tests/clients with old user agents get 406.

## Notes

- `config/credentials.yml.enc`, `.kamal/secrets`, and `.env.production` hold deployment secrets; recent commits repeatedly regenerate keys — don't modify or print them.
