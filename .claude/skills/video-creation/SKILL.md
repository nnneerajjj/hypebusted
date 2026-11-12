---
name: video-creation
description: How to plan, script, render and package HypeBusted YouTube videos (explainers, comparisons, Shorts) with the local toolchain, so they grow the channel toward monetization (1,000 subscribers + 4,000 watch hours), bring Google traffic to hypebusted.com, and solve a viewer's real pain point. Use this skill whenever the user asks for a video, a YouTube Short, a thumbnail, a video title or description, subtitles or voiceover for a video, an infographic for a post, or says things like "make a video about X", "turn this article into a video", "make a short from this", "what should the next video be", even if they never say "skill". Also use it before touching make_video.py, make_short.py or the ~/hypebusted-video workspace.
---

# HypeBusted video creation

HypeBusted publishes honest, no-hype tool reviews and comparisons. Videos are one of two traffic engines (the other is Google search to hypebusted.com). A video is only "done" when it has a render, a thumbnail, a title and description, subtitles, and a plan for the matching article and Short.

## Why we make videos (read this before choosing a topic)

1. **Monetization.** YouTube Partner Program: the owner's target is **1,000 subscribers and 4,000 public watch hours in the last 12 months**. Policies change, so check YouTube's current rules before promising anything. Planning math: 4,000 hours = 240,000 minutes, so 60,000 views at 4 minutes average watched, or 30,000 at 8. Only long-form watch time counts toward the 4,000 hours. Shorts do not, but they bring subscribers.
2. **Google traffic.** Videos rank in Google results and every video should send people to a matching article on hypebusted.com. Pick topics people actually search.
3. **Solve a pain point.** Every video starts from one specific problem a real person has ("I don't know where to buy a domain without getting trapped by renewal prices") and ends with them able to act. Entertainment without a solved problem does not earn trust or watch time.
4. **Trust.** The brand is honesty. Show real prices with a date, mark illustrative numbers as illustrative, disclose affiliation, state the limits of whatever we recommend. Trust is the reason a viewer subscribes.

Monetization risk to design around: YouTube can treat mass-produced, template-looking videos with synthetic voice as "inauthentic content" and refuse monetization. Do not ship a pile of near-identical slideshows. Add original value in each video: real screen recordings of the tool being used, our own comparison data, a specific viewpoint, and ideally a human voice or face over time. See `references/channel-strategy.md`.

## Workflow

1. **Brief.** One sentence each: the viewer, their pain point, the one-line answer, the search phrase they would type, the matching article. If any is missing, ask the user.
2. **Facts.** Collect every number and claim with a source and date. Keep them in one place (constants at the top of the script) so the video, thumbnail, description and article cannot disagree (a struck-out price once read "$24.99" in the thumbnail against "$21.99" in the video). Anything unverified is shown as illustrative or hedged ("roughly", "commonly"), and secondary-source competitor prices are never presented as exact. The user's confirmed numbers win.
3. **Script.** Write the narration first, one line per scene. Order points from most to least valuable to the viewer. Structure: hook the problem in 10 seconds, show what goes wrong, the solution ranked, how to do it, honest limits, recap, call to action, disclosure. About 2.7 to 3.3 spoken words per second with the default voice.
4. **Narration audio.** Synthesize all lines first (Kokoro, `af_heart`). Scene length = lead-in + clip + tail, never a fixed number (see rule 2 below).
5. **Scenes.** Build visuals to the readability and layout rules below. Preview contact sheets before the full render.
6. **Render, then QA** (checklist below). Fix, re-render.
7. **Package.** Thumbnail, title, description with chapters, subtitles, a Short, and the article hook. The matching article is written with the `article-writing` skill (same facts list, same date; the video description links to it and the post embeds the video). See `references/channel-strategy.md` for formats and templates.
8. **Hand over** with a short list of what to check by ear, because Claude cannot listen to audio.

## Hard rules (each exists because a real video went wrong)

1. **Everything readable on a phone.** On a 1920x1080 frame: body text and captions at least **44 px**, labels at least **36 px**, headlines and key numbers at least **80 px**, at most about 10 words of body text per screen, nothing important in the top or bottom 60 px (Shorts: keep the bottom 280 px clear of text). A viewer reported small text unreadable on mobile.
2. **No dead air.** The first Short was 47% silence (gaps of 3.5, 6.9 and 7.7 s) and the Hindi audio had twelve 2 to 7 s gaps, because narration clips were dropped into fixed-length scenes. The same fixed-slot design left 1.5 s gaps between scenes in the English video. Rule: synthesize narration first, trim each clip's edge silence, and make every scene exactly lead-in (0.2 s) + clip + tail (0.3 s). Stretch or squeeze the animation clock to fit the scene. `make_short.py` and `make_video.py` already do this.
3. **Verify the soundtrack by measurement, not hope.** Run `check_audio_gaps.py` on every render; it must PASS (no mid-video silence over 1.0 s). After the fix: English track longest gap 0.6 s, Short 88% speech coverage.
4. **Voice.** Kokoro `af_heart` was acceptable for the long explainer, but the owner judged it robotic on the Short and will source a better voice. Treat the voice as swappable: `narration.py` is the only place that touches the TTS engine, and scene lengths must come from whatever clip lengths the chosen audio has (recorded or synthetic). Piper voices are robotic. Do not dub other languages with local TTS: the Hindi audio was rejected. For another language use translated subtitles, and a human voice if it is ever needed.
5. **Pronunciation.** Test-spell acronyms for the voice: "S S L", "D N S", "A W S", "S three", "who-is" for WHOIS, "dee-doss" for DDoS, "Hype Busted dot com", prices in words ("eleven dollars and seventeen cents"). ICANN as "eye-can" is correct.
6. **Honesty on screen.** Date-stamp prices, label illustrative figures on screen, include "not affiliated / no affiliate links" when that is true, state limits ("forwarding only, not a mailbox"). "Best" claims need a stated basis; prefer "lowest renewal price we found".
7. **Thumbnail.** 1280x720, 4 words or fewer in huge type, high contrast, one face with a clear emotion, the key number. Check every digit at zoom. A real photo supplied by the user beats an AI portrait: local AI portraits (CPU, about 7 minutes each) looked cartoonish and were rejected. Do not put the same image in the video, the article and the thumbnail.
8. **Do not reuse a frame as the article image.** The infographic should add information (a comparison, a number), not repeat the thumbnail.
9. **A Short must earn the scroll.** Technically clean is not enough: the first Short was three static slides (a bar chart and a checklist) and the owner judged it not engaging enough to survive scrolling. Before building one, write the first-second hook and the reason a stranger would stay; see the Shorts section of `references/channel-strategy.md`.

## QA checklist before handing over

- [ ] `check_audio_gaps.py` PASS; duration is sensible (explainer 3 to 10 min, Short 20 to 45 s).
- [ ] Contact sheet of every scene viewed; no overlapping or clipped text; text sizes meet rule 1.
- [ ] Every number and name matches the facts list; disclaimers present.
- [ ] Chapter timestamps in the description come from the actual scene lengths (`make_video.DURS`), first chapter at 0:00.
- [ ] Thumbnail digits and spelling verified at zoom; file under 2 MB.
- [ ] Tell the user what to listen for: the first 30 seconds, every acronym, every price.

## Toolchain (all local, CPU only, no paid services)

Permanent workspace: `~/hypebusted-video/` (built by `scripts/setup.sh`, about 30 s; re-runnable). It has `venv/` (Pillow, numpy, imageio-ffmpeg, Kokoro, rembg), `fonts/` (the site's Space Grotesk, DM Sans, DM Mono), `kokoro/` (voice model), the scripts, and `out/`.

```bash
cd ~/hypebusted-video
./venv/bin/python narration.py                      # voiceover clips + audio/durations.json
./venv/bin/python make_video.py preview             # one PNG per scene -> ./preview
./venv/bin/python make_video.py render out/x.mp4    # about 2 minutes for 3 minutes of video
./venv/bin/python make_short.py render out/s.mp4    # 1080x1920 Short, narration-first pacing
./venv/bin/python make_srt.py en out/en.srt         # captions (or a JSON list of translated lines)
./venv/bin/python make_infographic.py out/info.png  # 1600x900 article infographic
./venv/bin/python check_audio_gaps.py out/x.mp4     # must PASS
```

The scripts are worked examples from the Cloudflare domain video. For a new video copy `make_video.py`, replace the constants, scenes and the `SCENES` list, and rewrite `LINES` in `narration.py`. Full inventory (what is installed where, model sizes, what is not installed, how the site and Chrome extension are used) is in `references/toolchain.md`.

## References

- `references/channel-strategy.md`: goals math, topic selection, titles, descriptions, chapters, Shorts, subtitles and languages, reach tactics, policy risks.
- `references/lessons-learned.md`: what worked and what failed on the first video, Shorts and Hindi attempt, with the numbers.
- `references/toolchain.md`: installed tools and locations, commands, render settings, posting to the site.
