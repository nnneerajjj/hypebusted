# Writing patterns for HypeBusted articles

Read when drafting. These come from the first article ("Stop Overpaying for Domains", Nov 2026) and the owner's corrections to it.

## Plain language first, jargon in brackets

The reader is a founder or small-business owner who does not know the terms. Lead with what it does for them; put the technical name in brackets once, at the end of the item.

| Say this | Technical term (in brackets) |
|---|---|
| Your name, address and phone number stay hidden from spammers | WHOIS privacy |
| Free padlock for your website, so visitors see **https://yourdomain.com** | SSL certificate |
| Free email addresses like **info@yourdomain.com** and **contact@yourdomain.com**, delivered to your own inbox, such as Gmail | email forwarding (say it is forwarding, not a mailbox) |
| Free protection that keeps your site online during attacks | DDoS security |
| Your website loads faster for visitors around the world | free worldwide cache (CDN) |
| The address book that tells browsers where your website lives | DNS |
| The servers that hold that address book | nameservers |
| Stops fake address lookups | DNSSEC |
| The price you pay every year to keep the domain | renewal price |
| The shop you buy from / the company that runs .com | registrar / registry |
| The fee a cloud company charges when your files leave its servers | egress (data transfer out) |
| The password that lets you move a domain to a new shop | authorization (EPP) code |

Use concrete examples (`info@yourdomain.com`, `https://yourdomain.com`) so the benefit is visible, and put the most valuable point first (for the domain article: the price).

## The tick / cross block

Left column "With X" (green ticks), right column "Many other <providers>" (red crosses). Rules:
- Same points in the same order in both columns; the right side is the "not included, or you pay extra" version of the left.
- At most six items, each under about 15 words.
- Hedge the right column: "Often...", "Sometimes...", "Not included, or sold as an extra". It describes a pattern, not every company.
- Order by value to the reader: price, then the free things people would otherwise pay for (email, padlock, privacy), then protection and speed.
- Markup: `assets/compare-block.html`. Use only classes `compare`, `compare-col`, `compare-yes`, `compare-no`, `compare-title` (styles live in `app/assets/tailwind/utilities.css`).

## Headlines and the first paragraph

- Pattern: **"Stop <pain>: The $<bad> Trap (and the $<good> Fix)"**; **"<A> vs <B>: <deciding factor> (<year>)"**; **"How to <outcome> in <N> minutes without <pain>"**; **"Where to <action>: <honest differentiator>"**. Specific numbers beat adjectives.
- The `<title>` tag cuts at 47 characters, so the keyword the reader searches for belongs in the first 47. The Cloudflare article's title reads "Stop Overpaying for Domains: The $0.99 Trap ..." in Google, so "Cloudflare" never appears in the visible title tag; a title that starts with the search phrase would rank better.
- First paragraph = the Google snippet: problem, what the reader learns, payoff with the key number, in under 155 characters of the most important content. No throat-clearing.

## Fair language about companies

| Avoid | Prefer |
|---|---|
| "GoDaddy scams you" / "they deceive customers" | "A .com commonly renews at roughly $22 a year; the first-year promotion can be far lower" |
| "Hidden fees everywhere" | "Some registrars charge about $10 a year for privacy; many now include it, so check before you pay" |
| "Cloudflare is the best" | "Lowest renewal price we found for a .com, with privacy and email forwarding included" |
| exact competitor prices from affiliate review sites | ranges, "commonly", and "snapshot from <month year>" |

Say plainly when a figure is illustrative. Name a company only when the claim is sourced. State the limits of the recommendation (the "What X is not" section): it is why readers believe the rest.

## Worked-example pattern (the five-year test)

Give the reader arithmetic they can repeat: option A first-year price plus renewals times years, option B the same, the difference. Mark the competitor figures illustrative. Readers trust numbers they can check.

## Sections that carry trust

- **Short answer** blockquote with the date.
- **Limits** ("What X is not"): requirements, costs that can rise, what is not included, who should choose something else.
- **Checklist** that works for any similar decision (renewal price not first-year price, untick add-ons, confirm privacy is free, calendar reminder, two-factor authentication, keep registration separate from hosting).
- **FAQ** with the questions people actually type (check Google's "People also ask" and the WebSearch tool). Answer in one or two sentences, start with yes/no where possible.

## Disclosure wording (adapt to the truth)

- No relationship: "HypeBusted is not affiliated with Cloudflare, and there are no affiliate links in this article. To our knowledge Cloudflare sells domains at cost and has no affiliate program for registrations, so we earn nothing if you buy a domain there. Prices were checked in November 2026 and change often, so confirm them at checkout."
- Affiliate links: "Some links are affiliate links. If you buy through them we may earn a commission at no cost to you. It does not change what we recommend or the price you pay." (Only if true; mark the links.)

## Tone

Direct, friendly, no hype words ("revolutionary", "game-changing"). Short paragraphs (under about 90 words), concrete numbers, second person. One idea per heading. Explain a term the first time it appears or avoid it.

## Pairing with the video

The video gets a link to the article in its description; the article embeds the video (set `youtube_video_id`). Both use the same facts list and the same date. The article must be worth reading without the video, so it adds what a 3-minute video cannot: the arithmetic, the steps, the limits, the FAQ.
