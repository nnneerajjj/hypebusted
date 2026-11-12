# Channel strategy and YouTube packaging

Read when choosing a topic, writing a title or description, planning a Short, or answering "how do we get more reach".

## Goals and what they imply

| Goal | Target | What it means for each video |
|---|---|---|
| Monetization | 1,000 subscribers and 4,000 public watch hours in 12 months (owner's target; verify YouTube's current Partner Program terms) | Long-form videos with strong retention. Shorts bring subscribers but their watch time does not count toward the 4,000 hours. |
| Google traffic | Videos and articles on hypebusted.com ranking for what people search | Topic = a search phrase. Title and first description line contain it. Link the matching article. |
| Solve pain points | Viewer can act after watching | Start from one specific problem, end with steps. |
| Trust | Subscribers who believe us | Honest numbers, dated, limits stated, disclosures. |

Planning math: 240,000 watch minutes needed. At 5 minutes average view that is 48,000 views. Average view duration (retention) matters as much as views, so cut filler instead of padding length. Explainers of 6 to 10 minutes that hold attention earn more watch hours than 3-minute ones; the first Cloudflare video ran 3:04, which is short for this goal.

## Choosing a topic

Prefer topics with all three: (1) a painful, specific problem, (2) a phrase people search ("cheapest place to buy a .com domain", "GoDaddy renewal price", "Cloudflare vs Namecheap"), (3) a decision the viewer must make with money or time attached. Ask the user for the pain point if it is not obvious. Good families for this channel: where to buy / what to pick (comparisons), hidden-cost exposés (renewal traps, add-on upsells), setup guides (DNS, email, self-hosting), "X vs Y" for tools founders actually choose.

## Monetization risk: inauthentic or mass-produced content

YouTube has tightened rules on repetitive, template-looking, mass-produced videos, including slideshow-style videos with synthetic narration. Our current look (animated cards plus text-to-speech) is exactly what such a policy could target if every video is the same template with swapped words. Mitigations to build in:
- Include original material in each video: real screen recordings of the product in use, our own measured numbers, our own test results.
- Vary structure and visuals between videos; do not clone scenes.
- Express a point of view (what we would do and why) rather than reading features.
- Over time add a human voice or face for at least the intro and verdict.
- Check the YouTube altered/synthetic content disclosure setting when the video contains realistic AI-generated people or voices, and answer it honestly.
Verify current policy text before publishing; this is a risk list, not a legal reading.

## Titles

- 50 to 65 characters so nothing is cut in search; the specific words first.
- A concrete number or contrast beats a generic claim: "Stop Overpaying for Domains: The $0.99 Trap (and the $11.17 Fix)".
- Do not promise what the video does not show. No "best" without a basis.
- Thumbnail text and title should add up to one idea, not repeat each other word for word.

## Description template

```
<One sentence with the search phrase, the problem, and the payoff. This is all that shows before "more".>

<2 to 3 sentences: who this is for and what they will be able to do.>

Read the full guide: https://hypebusted.com/posts/<slug>

CHAPTERS
0:00 Intro
<m:ss> <scene title>   (one per scene, timestamps from make_video.DURS, first at 0:00)

WHAT YOU GET / KEY POINTS
- ...

GOOD TO KNOW
- limits, caveats, illustrative-price notes

NOT SPONSORED: <affiliation statement, only if true>
More honest reviews: https://hypebusted.com
#tag #tag #tag
```

Chapters only work if the first is at 0:00 and each is at least 10 seconds.

## Thumbnails

1280x720, under 2 MB, readable at phone size. Four words or fewer, huge, high contrast. One face with a strong emotion, the key number as a badge (struck-out old price to new price works). Use a real or user-supplied photo; cut out with rembg, trim the fringe, add a white outline and soft shadow. Verify digits at zoom, and match the video's numbers exactly. Use YouTube Studio's Test and compare to A/B test two thumbnails once there are enough views.

## Shorts (20 to 45 seconds, 1080x1920)

Purpose: discovery and subscribers (Shorts watch time does not count toward the 4,000 hours). One idea per Short, hook in the first 2 seconds (the claim or the number), payoff by the midpoint, call to action last. Pace like the audience scrolls: scene length equals narration length plus 0.5 s, no dead air (`make_short.py`).

**Scroll test (the first Short failed it).** A clean, silent-gap-free render is the minimum, not the goal. Before rendering, answer in one line each: (1) what is on screen in the first second that makes a stranger stop (a shocking number, a face, a before/after, a question they personally care about)? (2) what open question keeps them until the end? (3) what changes on screen at least every 2 to 3 seconds (new element, cut, zoom, real footage)? (4) what is the one payoff they could repeat to a friend? Static slides with a voiceover will not pass. Prefer real screen recordings, a human on camera, or a single striking visual that moves, over text cards. If the honest answer to (1) is "nothing", change the idea, not the colors. Text large, centered, away from the bottom 280 px. Put the full-video link in the description and say "link in the description". Cut several Shorts from one long video, one point each. Verify with `check_audio_gaps.py`.

## Subtitles and languages

- Always upload an English `.srt` (replaces the auto-captions): Studio, Subtitles, language, Upload file, **With timing**. Generate with `make_srt.py en out/en.srt`.
- Translated subtitles are cheap reach (`make_srt.py TEXTS.json out.srt`, one line per scene). Have a native speaker check machine translations before publishing.
- Dubbed audio tracks: the Studio option is not available to every channel, and local text-to-speech in Hindi was rejected (pauses and robotic delivery). Hindi support is parked. Revisit only with a human voice or a much better voice engine.

## Reach tactics beyond the video

- Matching article on hypebusted.com with the video embedded (the site renders `youtube_video_id` at the top of a post). Text brings Google traffic; the embed adds watch time.
- Pinned comment with the article link; end screen pointing to the next video; playlists by topic.
- Check Studio analytics after 48 hours: click-through rate (thumbnail and title) and retention graph (where people leave). Fix the opening if the first 30 seconds lose people.
- Consistency beats bursts: choose a schedule the owner can keep.
