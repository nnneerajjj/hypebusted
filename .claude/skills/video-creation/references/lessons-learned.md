# Lessons learned (first video: "Stop Overpaying for Domains", Nov 2026)

What was built, what the owner and viewers said, what failed and what was done about it. Read before repeating any step so the same mistake is not made twice.

## What was built

- A 3-minute animated explainer (1920x1080, 30 fps): the renewal trap, six registrar tricks, eight Cloudflare advantages ranked most to least valuable, S3/AWS savings, DNS setup, recap, subscribe call, not-affiliated disclosure. Scripted in code (Pillow frames piped to ffmpeg), English voiceover from Kokoro `af_heart`.
- Thumbnail, title, description with chapters, an English-first subtitle plan, a Hindi subtitle file, a Short, an article-body infographic, and a post on hypebusted.com with the video embedded.
- YouTube title chosen by the owner: "Stop Overpaying for Domains: The $0.99 Trap (and the $11.17 Fix)". Confirmed price: **$11.17** for a .com at Cloudflare, same on renewal (November 2026).

## Feedback and outcomes

| Feedback | Cause | Fix now in the skill |
|---|---|---|
| Text too small on mobile | Labels and footnotes were 24 to 30 px on a 1080p frame | Rule 1: 44 / 36 / 80 px minimums, saved as a memory too |
| Hindi audio had pauses, dropped | Clips of 6 to 15 s placed in 9 to 19 s scene slots; 12 gaps of 2 to 7 s (measured) | Narration-first timing; gap checker; no local-TTS dubbing |
| Short was not good, not used | Fixed 6/11/18/10 s scenes holding 2.6 to 10 s clips: three gaps of 3.5 to 7.7 s, 47% speech | `make_short.py` rebuilt narration-first: 33 s, 88% speech, longest gap 0.6 s |
| Short "technically fine, not engaging enough to survive scrolling" (owner feedback, after the pacing fix) | Content design: three static slides, no pattern interrupt, no human or real footage, no open loop | New hard rule 9 and the scroll test in `channel-strategy.md` |
| Voice judged robotic (owner) | Local TTS (Kokoro) is clearly synthetic on short, fast content | Voice is swappable; owner will source a better one |
| English video felt paused in places | Fixed lead (0.5 s) and tail (0.9 s) plus clip edge silence gave 1.5 s gaps between scenes | Lead 0.2 s, tail 0.3 s, clip edges trimmed: longest gap 0.6 s |
| AI portrait looked cartoonish | Local CPU model (DreamShaper 8) is stylised; each image took about 7 minutes | Use a user-supplied real or high-quality photo; cut out with rembg |
| Thumbnail woman was holding a gift | Source photo had a gift box at the bottom | Cropped above it (no inpainting needed) |
| Article image duplicated the thumbnail above it | The YouTube embed already shows the thumbnail | Article infographic must add information (5-year cost comparison) |
| Struck-out price looked like $24.99 | The strike line crossed the digit; verify by cropping at zoom | Move the strike line; verify digits at zoom |

## Facts and honesty decisions

- Competitor figures (GoDaddy about $22 renewal, Namecheap about $14 to $16) came from third-party 2026 comparison sites that disagreed with each other. They are written as ranges with "check at checkout", and the $0.99 / $21.99 teaser pair is labelled illustrative. Only the $11.17 is confirmed by the owner.
- The "not affiliated, no affiliate program" statement is the owner's claim, worded "to our knowledge" in the article. It appears on screen and in the narration of the video.
- The narration says "eye-can" for ICANN. That is the correct pronunciation. An earlier note in the session wrongly called it an error.
- "Best value" on the infographic is a judgment; the safer wording is "lowest renewal price we found".

## Process lessons

- Claude cannot listen. Quality of the voice is the one thing the user must check; give them the exact timestamps and terms to listen for, and use measurable checks for everything else.
- Python 3.14 starts worker processes fresh (not forked), so values computed in `main()` are `None` inside `multiprocessing.Pool` workers. Compute timings at module import time (see `plan()` in `make_short.py`).
- This machine has no GPU and no system ffmpeg. The ffmpeg binary comes from `imageio-ffmpeg`. CPU rendering is fine for this style of video.
- Anything under `/tmp` (including the Claude session scratchpad) disappears. Keep models, scripts, fonts and finished assets under `~/hypebusted-video` and `~/Videos`.
- Images uploaded to production are lost on every deploy until S3 (or a storage volume) exists, so keep a local copy of every image and plan to re-upload after deploys. The site's article body strips `<table>` and inline `style`; `class` survives.
- Hindi: parked. Subtitles in other languages are fine after native-speaker review; voice dubbing is not.

## Open items

- Real screen recordings for originality (not set up yet; see `toolchain.md`).
- A human voice or face for intros and verdicts.
- Article writing skill (next skill to write).
- S3 image storage for production.
