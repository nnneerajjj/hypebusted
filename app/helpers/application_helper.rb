module ApplicationHelper
  SITE_NAME = "HypeBusted".freeze
  ICON_PATHS = {
    arrow: "M5 12h14M13 6l6 6-6 6",
    chevron: "M9 6l6 6-6 6"
  }.freeze

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

  # Decorative stroke icon; size it with classes (e.g. "size-5"), never inline styles.
  def link_icon(name, class: nil)
    tag.svg(tag.path(d: ICON_PATHS.fetch(name)),
      class:, viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round",
      aria: { hidden: true }, focusable: false)
  end
end
