module ApplicationHelper
  SITE_NAME = "HypeBusted".freeze
  AUTHOR_NAME = "Neeraj Singh".freeze
  ICON_PATHS = {
    arrow: "M5 12h14M13 6l6 6-6 6",
    chevron: "M9 6l6 6-6 6"
  }.freeze
  STAR_PATH = "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01z".freeze
  STAR_SIZE = 24
  STAR_FILL_ID = "star-rating-fill".freeze

  # Image src for an attached blob. On a public service (S3 behind the CDN) this is the variant's direct
  # CDN URL, so browsers and Cloudflare cache it; otherwise the Rails representation route.
  def blob_image_source(blob, **transformations)
    representation = blob.representation(**transformations)
    blob.service.public? ? representation.processed.url : representation
  end

  def seo_tags(title:, description:, type: "website", image: nil, published_at: nil)
    url = request.base_url + request.path
    metas = [
      tag.meta(name: "description", content: description),
      tag.link(rel: "canonical", href: url),
      tag.meta(property: "og:title", content: title),
      tag.meta(property: "og:description", content: description),
      tag.meta(property: "og:type", content: type),
      tag.meta(property: "og:url", content: url),
      tag.meta(property: "og:site_name", content: SITE_NAME),
      tag.meta(name: "twitter:card", content: image ? "summary_large_image" : "summary")
    ]
    metas << tag.meta(property: "og:image", content: image) if image
    metas << tag.meta(property: "article:published_time", content: published_at.iso8601) if published_at
    content_for :head, safe_join(metas, "\n")
  end

  def json_ld(data)
    tag.script(json_escape(data.to_json).html_safe, type: "application/ld+json")
  end

  # <time> element with a machine-readable ISO datetime and a human-readable strftime label.
  def time_tag_for(time, format, class: nil)
    time_tag(time, time.strftime(format), class:)
  end

  # Decorative stroke icon; size it with classes (e.g. "size-5"), never inline styles.
  def link_icon(name, class: nil)
    tag.svg(tag.path(d: ICON_PATHS.fetch(name)),
      class:, viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round",
      aria: { hidden: true }, focusable: false)
  end

  # Editorial rating: a row of empty stars with the same row on top, clipped to the rating's share of the width.
  # Stars are decorative; the visible "4.5 out of 5" text is what screen readers read.
  def star_rating(post)
    fill_width = "#{(post.rating * 100 / Post::BEST_RATING).to_i}%"
    stars = ->(**options) do
      tag.g(safe_join(Array.new(Post::BEST_RATING) { |i| tag.path(d: STAR_PATH, transform: "translate(#{i * STAR_SIZE})") }), **options)
    end
    svg = tag.svg(safe_join([
        tag.defs(content_tag("clipPath", tag.rect(width: fill_width, height: "100%"), id: STAR_FILL_ID)),
        stars.call(class: "fill-ink/15"),
        stars.call(class: "fill-accent", "clip-path": "url(##{STAR_FILL_ID})")
      ]),
      viewBox: "0 0 #{STAR_SIZE * Post::BEST_RATING} #{STAR_SIZE}", class: "h-5 w-25",
      aria: { hidden: true }, focusable: false)
    tag.p(svg + tag.span("#{post.rating_value} out of #{Post::BEST_RATING}"),
      class: "star-rating mt-3 flex items-center gap-2 font-mono text-sm")
  end
end
