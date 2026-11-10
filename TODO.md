# TODO

Shared task list for all Claude chat windows and the developer. Check it before starting work; tick items off (`[x]`) or delete them when done.

- [ ] Raise public page caching to 1 day: change `expires_in 5.minutes` in `app/controllers/home_controller.rb` and `app/controllers/posts_controller.rb` to `1.day`, and review `expires_in 1.hour` in `app/controllers/sitemaps_controller.rb`. Content is articles, not real time. Update any tests asserting `max-age`. (Deferred: do later, only when the developer asks.)
- [x] Edit post HTML in plain-text mode: in the Avo admin (`/milo`), the post form has an "Edit as HTML" checkbox that swaps the Trix editor for a raw HTML textarea (`Post#html_editor` / `Post#content_html`, virtual). Changes saved in either editor round-trip.
- [ ] Show and edit tags on the post form: in the Avo admin (`/milo`), let the admin see and edit a post's tags from the post edit/new form.
