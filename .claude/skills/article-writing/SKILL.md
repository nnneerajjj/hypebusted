---
name: article-writing
description: How to research, write, check, preview and publish articles on hypebusted.com (reviews, comparisons, journal posts) so they rank on Google, solve a reader's real problem, and build trust, and how they pair with the YouTube video. Use this skill whenever the user asks to write, draft, rewrite, improve or publish an article, post, blog, review or comparison for the site, asks for an article image, infographic, caption, title, slug, meta description or tags, wants a video's matching article, or wants anything posted through the /milo admin, even if they only say "write about X" or "post this". Also use it before editing a post body, because the site strips some HTML and the editor can silently remove markup.
---

# HypeBusted article writing

Articles are the Google-traffic half of the HypeBusted plan; videos (see the `video-creation` skill) are the YouTube half. An article earns its place by solving one reader's problem better than the pages already ranking, in plain language, honestly.

## What an article is for

1. **Solve a pain point.** One specific person with one specific problem ("where do I buy a domain without paying a surprise renewal price?"). After reading they can act.
2. **Earn trust.** The brand is honesty: dated numbers, hedged claims, a section on the recommendation's limits, a clear disclosure. Trust is why readers come back and subscribe.
3. **Bring Google traffic** to hypebusted.com and send readers to the video and channel. The title, slug, first paragraph and headings carry the search phrase.
4. **Stand on its own.** An article is not a transcript of the video. It goes deeper (math, steps, limits, FAQ), and can be read without watching.

The site may later run ads, so keep every article original, helpful and honest, and keep claims about companies fair and sourced.

## Workflow

1. **Brief.** Reader, pain point, one-line answer, the search phrase, the matching video (if any). Ask the user for whatever is missing.
2. **Facts.** List every number and claim with source and date. Use the user's confirmed numbers; treat anything from comparison sites as approximate and hedge it ("commonly", "roughly", a range) or label it illustrative. The same list feeds the video, thumbnail and description.
3. **Outline** using the anatomy below.
4. **Draft the HTML** (not Markdown) with only tags the site keeps. Start from `assets/article-skeleton.html`; `assets/example-cloudflare-domain-article.html` is a finished example; `assets/compare-block.html` is the tick/cross block.
5. **Image.** One infographic that adds information (see rules). Keep the file locally.
6. **Check and preview.** `scripts/check_article.rb` (what the site strips, title/description, structure) then `scripts/preview_article.sh` (desktop and phone screenshots). Fix, repeat.
7. **Publish** through the admin (`references/site-publishing.md`), then verify the live page.
8. **Hand over** what to confirm (unverified claims, tags, anything hedged).

## Anatomy of a strong article

Order matters: the reader gets the answer first, then proof, then how-to, then limits.

1. **Opening paragraph.** A self-contained summary: the problem, what the reader will learn, the payoff with the key number. Its first 155 characters become the Google snippet, so write it as the snippet.
2. **Benefit comparison block** right after paragraph one (`.compare`): "With X" with green ticks beside "Many others" with red crosses, side by side on desktop and stacked on mobile. Plain language, most valuable point first, jargon in brackets at the end (see glossary).
3. **Who this is for** (one or two lines) and a **short-answer** blockquote with the date.
4. **Infographic** with a caption that states the takeaway. The first image becomes the social-sharing image.
5. **The basics**: what it should cost or how it works, in plain terms.
6. **The problem**: a numbered list of the patterns that hurt the reader, stated neutrally ("None of this is illegal; it is disclosed in small print").
7. **The math**: a worked example the reader can repeat (the five-year test).
8. **Comparison** of the named options, hedged, with a "snapshot from <month year>" line.
9. **Ranked advantages** of the recommendation, most to least valuable, each an `h3` with a short paragraph.
10. **Steps** (ordered list) including how to move from where they are now.
11. **Limits**: "What X is not". This section is the biggest trust builder; do not skip it.
12. **Checklist** the reader can use for any similar decision.
13. **FAQ** as `h3` question plus `p` answer (the questions people type into Google).
14. **Disclosure** in `<small>`: affiliation, affiliate links, date prices were checked.

## Hard rules

- **HTML limits.** Kept: `a abbr address b blockquote br cite code dd del dfn div dl dt em figcaption figure h1-h6 hr i img ins kbd li mark ol p pre samp small span strong sub sup time ul` and the `class` attribute. Stripped: `table`, `details`, `style` attributes, scripts, iframes. Do not use `h1` (the page prints the title as the only h1). Definition lists have no spacing styles on the site; use bullets or `h3` + `p`.
- **Title.** The `<title>` tag cuts the post title to 47 characters plus " | HypeBusted": put the search words first. The title itself can be longer for humans. Slug: short and keyword-led (`stop-overpaying-for-domains-cloudflare-registrar`). Post type: `review`, `comparison` or `journal`.
- **Plain language first.** Say what it does for the reader, then the technical name in brackets: "Your name, address and phone stay hidden from spammers" not "WHOIS redaction". The glossary in `references/writing-patterns.md` has the translations used so far.
- **Fair about companies.** Describe pricing patterns, not motives. Avoid "deceive/scam" unless proven. Attach numbers to a source and a date, use "often/sometimes" when it is not universal, and say that figures are illustrative when they are. Do not call anything "best" or "cheapest" without stating the basis ("lowest renewal price we found").
- **Date-stamp** prices and facts ("checked November 2026") and put the same date in the video description.
- **Link out** to primary sources (vendor docs and pricing pages) and to related posts. The checker warns when there are no links; the first Cloudflare article had none.
- **Images.** First image is an infographic that adds information; never the video thumbnail (the video embed already shows it). 1600x900, text at least 32 px at that width. Descriptive kebab-case filename (`cloudflare-best-and-cheapest-domain-provider.png`). Caption = one informative sentence (the page uses it as the image alt text). **Keep a local copy of every uploaded image**: production currently loses uploads on every deploy until S3 storage exists.
- **Disclosure** always. If there is no affiliate relationship say so; the owner's statement is quoted "to our knowledge".
- **Code changes** (new CSS blocks, etc.) go through tests first, a branch and pull request, a merge and a Kamal deploy; update the post only after the deploy, or it shows unstyled.

## QA checklist

- [ ] `check_article.rb` has no FAIL lines; WARN lines are fixed or consciously accepted.
- [ ] `preview_article.sh` screenshots reviewed at desktop and phone width.
- [ ] Every number matches the facts list and the video; hedges and dates present.
- [ ] First 155 characters read well as a Google snippet.
- [ ] Infographic text readable on a phone; filename and caption written.
- [ ] Live page verified after publishing: one h1, the right number of h2, video iframe, image loaded, caption, `og:image`, meta description.
- [ ] Tags chosen from existing tags (check the admin first; creating new tags is the owner's call).

## References and assets

- `references/writing-patterns.md`: plain-language glossary, headline and snippet patterns, fair-language guide, FAQ and disclosure wording, section examples.
- `references/site-publishing.md`: what the site does with an article, the exact admin and Chrome-extension steps, live verification, pitfalls.
- `assets/`: `article-skeleton.html`, `compare-block.html`, `example-cloudflare-domain-article.html`.
- `scripts/`: `check_article.rb`, `preview_article.sh` (with `preview_post.rb`).
