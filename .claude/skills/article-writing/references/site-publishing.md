# Publishing to hypebusted.com

How the site treats an article, and the exact steps used to publish the first one. Admin is at `/milo` (Avo), reached through the Claude in Chrome extension signed in as the super admin.

## What the site does with a post

- **Visibility:** a post is public only when `published_at` is in the past. Blank `published_at` is a draft (404 publicly).
- **`<title>`:** `"#{title.truncate(47)} | HypeBusted"`. **Meta description:** first 155 characters of the body's plain text. **Canonical** and **BlogPosting JSON-LD** are generated.
- **Social image:** the first image embedded in the body (`og:image`, large Twitter card). Make that the infographic.
- **Video:** if `youtube_video_id` is set, a privacy-friendly (`youtube-nocookie`) embed is rendered above the article.
- **Images:** rendered with lazy loading, async decoding, width and height; `alt` is the caption (fallback: humanised filename).
- **Caching:** public pages are cached for 5 minutes (ETag from the posts); tag changes can take that long to show. This is an accepted trade-off, not a bug.
- **Sanitizer:** Action Text keeps `a abbr acronym action-text-attachment address b big blockquote br cite code dd del dfn div dl dt em figcaption figure h1-h6 hr i img ins kbd li mark ol p pre samp small span strong sub sup time tt ul var` and attributes including `class`, `href`, `src`, `alt`, `title`, `width`, `height`, `loading`, `decoding`. It removes `table`, `details`, `style`, `script`, `iframe`, `rel`. Run `scripts/check_article.rb` to see exactly what a draft loses.
- **Styles available in post bodies** (`.prose-post` in `app/assets/tailwind/utilities.css`): `h2`, `h3`, `p`, `ul` (bullets with the accent colour), `ol`, `li`, `a` (underlined accent), `blockquote` (accent left border, italic), `pre`, `code`, `img`, `figure`/`figcaption`, and the benefit block `.compare` with `.compare-col`, `.compare-yes`, `.compare-no`, `.compare-title`. Any new styled block needs a CSS change (tests first, branch, pull request, merge, Kamal deploy) before the post that uses it is updated.

## Admin form fields

Title, Content, **Edit as HTML** checkbox, Post type, Tags (multi-select of existing tags), Youtube video id, Published at, Slug. **Edit as HTML is ticked by default**: the body is edited in a raw HTML textarea, and that is how articles must be saved. Unticking it swaps in the Trix rich-text editor as a fallback; Trix shows a warning because saving from it **strips `h2`/`h3`, CSS classes (the `.compare` block) and other markup**. Above the HTML textarea is the **Insert image** control: a file input, a caption box and an **Insert image** button. It uploads the image and writes an `<action-text-attachment ... presentation="gallery">` tag at the caret. Switching editors does not carry unsaved changes: save first, then switch.

## Publishing steps (Chrome extension)

1. `tabs_context_mcp` with `createIfEmpty`, open `https://hypebusted.com/milo/resources/posts/new` in the new tab. Close tabs you opened when done.
2. Type the **Title**. Choose **Post type** (`comparison` for X vs Y, `review`, `journal`). Fill **Youtube video id** and **Slug**. Leave **Published at** blank for now.
3. **Image** (the infographic). Copy the file into an allowed folder first (the Claude session scratchpad works; `~/Videos` is rejected by `file_upload`). Use `find` to get the ref of the Insert image file input above the HTML textarea and `file_upload` the file. Type the caption in the caption box. Put the caret where the image goes, then click **Insert image**. The tag appears at the caret on its own line (with `sgid`, content type, filename, file size, width, height, `url`, `href` and caption filled in; `url`/`href` keep the hidden Trix preview working). It must not be inside a `<p>`. Any error shows inline next to the button; nothing is inserted.
4. Save the draft: focus the Title field and press `ctrl+Return`.
5. Open `.../milo/resources/posts/<id>/edit`. **Edit as HTML** is already ticked. Read the textarea: it contains one `<action-text-attachment sgid=... caption=...>` tag. Build the full article HTML with `[[IMAGE]]` replaced by that exact tag. Set the textarea with the native value setter and dispatch `input` and `change` events.
6. Set **Published at** with JS on the flatpickr input: `input._flatpickr.setDate('YYYY-MM-DD HH:mm:ss', true, 'Y-m-d H:i:S')`. The value is stored as UTC; pick a time that is already in the past in both your timezone and UTC.
7. Save with `ctrl+Return`; look for the green "Post was successfully updated" toast.
8. **Verify the live page** (JS on `https://hypebusted.com/posts/<slug>`): one `h1`; the expected `h2` count; `iframe` present; the figure image `complete` with natural width; `figcaption` text; `meta[property="og:image"]` is the infographic; meta description starts as intended; the home page lists the post. Screenshot at desktop and, with headless Chrome (`--window-size=390,N`), at phone width.

Replacing an image later: on the edit page (HTML textarea), `file_upload` the new file on the Insert image file input, type the caption, put the caret where the image goes and click **Insert image**. The new tag appears at the caret on its own line; it must not be inside a `<p>`. Delete the old tag, then save.

## Pitfalls seen so far

- **Production loses uploaded images on every deploy** (uploads live on the container disk; no storage volume; S3 is planned). After any deploy, check that images still load and re-upload from the local copy. Keep local copies of every image (`~/Videos/article-image/`).
- Output of the JS tool is blocked when it contains URL tokens or cookie-like strings (such as `sgid`); return counts and booleans, not attribute values.
- Mouse-wheel scrolling over the Trix editor scrolls the editor, not the page; scroll with JS (`window.scrollTo`).
- Avoid anything that raises a browser dialog (`alert`, `confirm`).
- The environment blocks direct SSH to production and merging a pull request without review; hand those to the owner rather than working around them.
- If the browser tools are missing, ask the owner to run `/chrome` and keep the computer awake with Chrome open and signed in.
- A temporary local preview post must be removed (`preview_article.sh` does it automatically); never create preview posts on production.

## Code changes that support an article

Follow the repo conventions: tests first (the project rule), `bin/rails test`, `bin/rubocop`, `bin/brakeman`; a feature branch and pull request (the Docker image builds only on `main`); after the merge `kamal deploy --skip-push --version=<full commit sha>` (pass the version explicitly if the working tree has untracked files); then verify production (`/up`, the new CSS rule in the served stylesheet, an existing post still renders). The `.compare` block shipped this way (PR #14).
