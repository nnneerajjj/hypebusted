module ApplicationHelper
  SITE_NAME = "HypeBusted".freeze

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
end
