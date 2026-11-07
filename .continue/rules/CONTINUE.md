---
name: Project Guide
description: Guide for the HypeBusted project
---

# Project Guide: HypeBusted

HypeBusted.com is a Rails 8.1 app where a single admin publishes tool reviews, multi-tool comparisons, and daily journal posts.

## 1. Stack
- **Ruby** 4.0.9 (see `.ruby-version`), **Rails** 8.1
- **Database**: PostgreSQL. Production uses `DATABASE_URL` for all Solid databases too.
- **Frontend**: Hotwire (Turbo and Stimulus), importmap, Propshaft, Tailwind CSS (`tailwindcss-rails`)
- **Background jobs, cache, Action Cable**: Solid Queue, Solid Cache, Solid Cable
- **Admin**: Avo, mounted at `/milo`
- **Deployment**: Kamal, behind Cloudflare, SSL only

## 2. Getting started
```sh
bin/setup   # install gems, prepare the database, start the server
bin/dev     # Rails server plus Tailwind watcher (needed for CSS changes)
```
The app runs at `http://localhost:3000`.

## 3. Project structure
- `app/models/`: `Post` (`post_type` enum: review, comparison, journal), `Tag`, `Tagging`, `User`, `Session`, `Current`
- `app/controllers/`: `HomeController`, `SessionsController`, `PasswordsController`, and `Authentication` (login concern)
- `app/controllers/avo/`: Avo controllers. `Avo::ApplicationController` requires login and `super_admin`.
- `app/avo/resources/`: Avo resources for Post, Tag, and Tagging
- `app/assets/tailwind/application.css`: Tailwind entry point
- `app/javascript/controllers/`: Stimulus controllers
- `config/initializers/avo.rb`: Avo configuration (`root_path = "/milo"`)
- `config/deploy.yml`: Kamal configuration. Secrets come from `.kamal/secrets`.
- `db/`: migrations and `schema.rb`. The Solid tables are created by migrations in `db/migrate`.
- `test/`: model, controller, integration, and mailer tests. There is no `test/system` directory.

## 4. Development workflow
- **Style**: Omakase Ruby via RuboCop (`bin/rubocop`)
- **Security**: `bin/brakeman` and `bin/bundler-audit`
- **Tests**: `bin/rails test`. Write tests for models and controllers in `test/`.
- **CI**: `bin/ci` runs the same checks locally. `.github/workflows/ci.yml` runs them on GitHub.

## 5. Authentication and admin access
- Login is the Rails 8 generated authentication. Controllers require login by default. Use `allow_unauthenticated_access` to opt out.
- Avo is gated by login plus `User#super_admin?`. Logged-out visitors are sent to `/session/new`. Logged-in non-admins are sent to `/`.
- The Avo admin is at `/milo`. The old `/avo` path returns 404.

## 6. Troubleshooting
- **Database out of sync**: run `bin/rails db:prepare`.
- **CSS changes not showing**: make sure `bin/dev` is running so Tailwind rebuilds.
- **Ruby version**: use the version in `.ruby-version`.

## 7. References
- [Rails Guides](https://guides.rubyonrails.org/)
- [Hotwire](https://hotwired.dev/)
- [Kamal](https://kamal-deploy.org/)
- [Avo](https://docs.avohq.io/)

---
*This file is loaded by Continue to provide context for AI-assisted development.*
