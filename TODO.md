# TODO

Shared task list for all Claude chat windows and the developer. Check it before starting work; tick items off (`[x]`) or delete them when done.

- [ ] Raise public page caching to 1 day: change `expires_in 5.minutes` in `app/controllers/home_controller.rb` and `app/controllers/posts_controller.rb` to `1.day`, and review `expires_in 1.hour` in `app/controllers/sitemaps_controller.rb`. Content is articles, not real time. Update any tests asserting `max-age`. (Deferred: do later, only when the developer asks.)
