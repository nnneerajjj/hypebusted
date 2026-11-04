---
name: Project Guide
description: Comprehensive guide for the HypeBusted project
---

# Project Guide: HypeBusted

Welcome to the HypeBusted codebase. This guide serves as a comprehensive resource for understanding and working with this Rails 8.1 starter application.

## 1. Project Overview
**HypeBusted** is a modern Rails 8.1 starter application designed for building responsive web applications with minimal overhead. It leverages the latest Rails defaults to provide a robust foundation out of the box.

- **Purpose**: Admin will post reviews of individual tools like CRM, AI tools, VS Code extensions, Tech stack as individual posts. Comparisons of multiple tools as single post. And daily findings like setup of free AI, setup new rails project as blog posts.

- **Key Technologies**:
  - **Framework**: Ruby on Rails 8.1.4
  - **Language**: Ruby 4.0.9 (as specified in `.ruby-version`)
  - **Database**: SQLite (Development/Test)
  - **Frontend**: Hotwire (Turbo & Stimulus), Import Maps, Propshaft, Tailwind CSS
  - **Background Processing**: Solid Queue
  - **Caching**: Solid Cache
  - **Real-time**: Solid Cable
  - **Deployment**: Kamal

## 2. Getting Started

### Prerequisites
- **Ruby**: 4.0.9 (Check `.ruby-version`)
- **Bundler**: `gem install bundler`

### Installation
1. Clone the repository.
2. Run the setup script:
   ```sh
   bin/setup
   ```
   This will install dependencies, prepare the database, and run initial tests.

### Running the App
Start the development server with:
```sh
bin/dev
```
Access the application at `http://localhost:3000`.

### Running Tests
Execute the test suite using:
```sh
bin/rails test
```

## 3. Project Structure
The project follows standard Rails conventions:

- `app/`: Main application logic.
  - `controllers/`: Request handling (e.g., `HomeController`).
  - `models/`: Data logic and database interactions.
  - `views/`: HTML templates using ERB.
  - `javascript/controllers/`: Stimulus controllers for frontend interactivity.
  - `assets/stylesheets/`: CSS files (using Propshaft).
- `config/`: Application configuration.
  - `routes.rb`: URL-to-controller mappings.
  - `database.yml`: Database configuration.
  - `deploy.yml`: Kamal deployment configuration.
- `db/`: Database schema, migrations, and seeds.
- `lib/`: Library modules and custom tasks.
- `test/`: Unit, functional, and system tests.

## 4. Development Workflow

### Coding Standards
- Follow the **Omakase Ruby styling** via RuboCop.
- Run linting: `bin/rubocop`.
- Ensure security: `bin/brakeman`.

### Testing Approach
- Write tests for models and controllers in the `test/` directory.
- Use System Tests for end-to-end functionality (located in `test/system`).

### Deployment
The project is configured for deployment using **Kamal**. See `config/deploy.yml` for configuration details.

## 5. Key Concepts
- **Rails 8 Defaults**: This project uses the new "Solid" suite (Solid Queue, Solid Cache, Solid Cable) which utilizes the database instead of Redis for background jobs, caching, and WebSockets.
- **Hotwire**: Enhances frontend performance by sending HTML over the wire.
  - **Turbo**: Handles navigation and form submissions without full page reloads.
  - **Stimulus**: Handles small bits of JavaScript interactivity.
- **Import Maps**: Manages JavaScript dependencies without a complex build step like Webpack or Esbuild.

## 6. Common Tasks

### Generating a New Feature
1. **Model**: `bin/rails generate model Article title:string body:text`
2. **Controller**: `bin/rails generate controller Articles index show`
3. **Migration**: `bin/rails db:migrate`

### Adding a Route
Edit `config/routes.rb`:
```ruby
resources :articles
```

### Creating a Stimulus Controller
1. Create `app/javascript/controllers/hello_controller.js`.
2. Reference it in your HTML: `<div data-controller="hello"></div>`.

## 7. Troubleshooting

- **Database Issues**: If the database is out of sync, run `bin/rails db:prepare`.
- **Asset Issues**: If CSS/JS changes aren't reflecting, ensure `bin/dev` is running to watch for changes.
- **Ruby Version**: Ensure you are using the exact Ruby version specified in `.ruby-version` to avoid compatibility issues.

## 8. References
- [Official Rails Guides](https://guides.rubyonrails.org/)
- [Hotwire Documentation](https://hotwired.dev/)
- [Kamal Deployment Guide](https://kamal-deploy.org/)
- [SQLite Rails Guide](https://guides.rubyonrails.org/configuring.html#configuring-a-sqlite3-database)

---
*Note: This file is automatically loaded by Continue to provide context for AI-assisted development.*

