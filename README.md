# HypeBusted.com

A Rails 8.1 starter application with a responsive landing page, Hotwire, and PostgreSQL. Use it as a clean foundation for your next project.

## Requirements

- Ruby 4.0.9 (see `.ruby-version`)
- Bundler

## Getting started

```sh
bin/setup
bin/dev
```

Visit [http://localhost:3000](http://localhost:3000). The setup script installs dependencies, prepares the database, and starts the app in development mode. For later runs, start the server with `bin/dev`.

## Useful commands

```sh
bin/rails test           # Run the test suite
bin/rails db:prepare     # Create and prepare the database
bin/rails console        # Open a Rails console
bin/rails generate       # Browse available generators
bin/rubocop              # Check Ruby style
bin/brakeman             # Scan for common Rails security issues
```

The app uses PostgreSQL for development and test, so a running PostgreSQL server is required before `bin/setup`. Its homepage is rendered by `HomeController`; the `/up` endpoint reports application health.

## Where to start building

- Add application routes in `config/routes.rb`.
- Create models and migrations with `bin/rails generate model`.
- Add controllers and views under `app/controllers` and `app/views`.
- Add JavaScript with Stimulus controllers in `app/javascript/controllers`.
- Update the starter landing page styles in `app/assets/tailwind/application.css` (Tailwind; run `bin/dev` to rebuild).

For framework documentation, see the [Rails Guides](https://guides.rubyonrails.org/).
