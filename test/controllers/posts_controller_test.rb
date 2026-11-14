require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  def show(post, params: {}, headers: {})
    get "/posts/#{post.slug}", params: params, headers: headers
  end

  def create_post_with_image(caption: nil, filename: "sample-product-shot.png", **attrs)
    blob = image_blob(filename: filename)
    cap = caption ? %( caption="#{caption}") : ""
    Post.create!({ title: "Image Post", post_type: :review, published_at: 1.hour.ago,
      content: %(<div>Intro text<action-text-attachment sgid="#{blob.attachable_sgid}"#{cap}></action-text-attachment></div>) }.merge(attrs))
  end

  def json_ld(type)
    css_select('script[type="application/ld+json"]').map { |n| JSON.parse(n.text) }.find { |j| j["@type"] == type }
  end

  # Req 1
  test "route uses slug param" do
    assert_equal "/posts/first-blog-post", post_path(posts(:one).slug)
  end

  test "published post is visible without login" do
    show posts(:one)
    assert_response :success
  end

  # Req 2
  test "draft, future and unknown slugs are 404 and do not leak the title" do
    [ posts(:draft), posts(:future) ].each do |p|
      show p
      assert_response :not_found
      assert_not_includes response.body, p.title
    end
    get "/posts/does-not-exist"
    assert_response :not_found
  end

  # Req 4
  test "show page has one h1 and semantic structure" do
    show posts(:one)
    assert_select "h1", count: 1
    assert_select "h1", text: posts(:one).title
    assert_select "header", minimum: 1
    assert_select "main article", count: 1
    assert_select "article time[datetime]", count: 1
    assert_select "article", text: /This is the content for the first blog post/
  end

  test "tags render as a list, and no empty list without tags" do
    show posts(:one)
    assert_select "article ul li", text: tags(:one).name
    show posts(:three)
    assert_select "article ul", count: 0
  end

  # Req 5
  test "title tag is post title plus site name and short" do
    show posts(:one)
    assert_select "title", text: "First Blog Post | HypeBusted"
    assert_operator css_select("title").first.text.length, :<=, 60
  end

  # Req 6
  test "meta description derived from content and unique per post" do
    show posts(:one)
    desc = css_select('meta[name="description"]').first["content"]
    assert_equal posts(:one).seo_description, desc
    assert_includes desc, "This is the content for the first blog post."
    assert_operator desc.length, :<=, 160
    show posts(:two)
    assert_not_equal desc, css_select('meta[name="description"]').first["content"]
  end

  test "long content description is truncated to 160 characters" do
    post = Post.create!(title: "Long", post_type: :review, published_at: 1.hour.ago, content: "<div>#{'word ' * 200}</div>")
    show post
    assert_operator css_select('meta[name="description"]').first["content"].length, :<=, 160
  end

  # Req 7
  test "canonical is absolute and without query string; html lang en" do
    show posts(:one), params: { utm_source: "x" }
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/posts/first-blog-post"
    assert_select "html[lang=en]"
  end

  # Req 8
  test "open graph and twitter tags for a post without image" do
    show posts(:one)
    assert_select 'meta[property="og:title"]'
    assert_select 'meta[property="og:description"]'
    assert_select 'meta[property="og:type"][content=article]'
    assert_select 'meta[property="og:url"][content=?]', "http://www.example.com/posts/first-blog-post"
    assert_select 'meta[property="og:site_name"][content=HypeBusted]'
    assert_select 'meta[property="article:published_time"]'
    assert_select 'meta[property="og:image"]', count: 0
    assert_select 'meta[name="twitter:card"][content=summary]'
  end

  test "og:image and large twitter card when post has an image" do
    show create_post_with_image
    assert_select 'meta[property="og:image"][content^="http"]'
    assert_select 'meta[name="twitter:card"][content=summary_large_image]'
  end

  # Req 9
  test "BlogPosting JSON-LD" do
    show posts(:one)
    data = json_ld("BlogPosting")
    assert data, "expected BlogPosting JSON-LD"
    %w[headline datePublished description mainEntityOfPage author publisher].each { |k| assert data[k].present?, "missing #{k}" }
    assert_equal "First Blog Post", data["headline"]
  end

  # Req 10
  test "content images have alt, lazy loading, async decoding and dimensions" do
    show create_post_with_image(caption: "Dashboard screenshot")
    assert_select "article img[alt='Dashboard screenshot'][loading=lazy][decoding=async][width][height]"
  end

  test "image alt falls back to humanised filename" do
    show create_post_with_image
    img = css_select("article img").first
    assert_equal "Sample product shot", img["alt"]
  end

  # The benefits comparison block (.compare) is styled by CSS classes inside the post body, so the sanitizer must keep them.
  test "body keeps class attributes for the side-by-side comparison block" do
    post = Post.create!(title: "Compare", post_type: :comparison, published_at: 1.hour.ago, content:
      %(<div class="compare"><div class="compare-col compare-yes"><p class="compare-title">Yes</p><ul><li>One</li></ul></div>) +
      %(<div class="compare-col compare-no"><p class="compare-title">No</p><ul><li>Two</li></ul></div></div>))
    show post
    assert_select "article .compare .compare-col.compare-yes li", text: "One"
    assert_select "article .compare .compare-col.compare-no li", text: "Two"
    assert_select "article .compare > .compare-col", count: 2
  end

  # Req 11
  test "youtube embed uses nocookie host with title and lazy loading" do
    show posts(:one)
    assert_select "iframe[src*='youtube-nocookie.com'][src*='ABCDEFG123'][loading=lazy][title]", count: 1
    assert_select "iframe[title='']", count: 0
    assert_select "article iframe", count: 1
    assert_select "article .aspect-video iframe"
  end

  test "no iframe without youtube id" do
    show posts(:no_video)
    assert_response :success
    assert_select "iframe", count: 0
  end

  # Req 13
  test "etag, public cache-control and 304 on conditional get" do
    show posts(:one)
    assert_response :success
    assert response.headers["ETag"].present?
    assert_match(/public/, response.headers["Cache-Control"])
    show posts(:one), headers: { "If-None-Match" => response.headers["ETag"] }
    assert_response :not_modified
  end

  # Req 14/15
  test "no inline styles or arbitrary value classes; reading measure class" do
    show posts(:one)
    assert_select "[style]", count: 0
    assert_no_match(/class="[^"]*\[/, response.body)
    assert_select "article.prose-post"
  end

  test "HTML saved in HTML mode renders on the public page" do
    post = posts(:one)
    post.update!(html_editor: true, content_html: "<div><em>Hand written</em></div>")
    show post
    assert_response :success
    assert_includes response.body, "<em>Hand written</em>"
  end

  # Admin link: anonymous
  test "anonymous visitor sees no admin link on a post and gets public caching" do
    assert posts(:one).published_at.past?
    show posts(:one)
    assert_response :success
    assert_select 'a[href="/milo"]', count: 0
    assert_match(/public/, response.headers["Cache-Control"])
    assert_match(/max-age=300/, response.headers["Cache-Control"])
    assert response.headers["ETag"].present?
  end

  # Admin link: super admin
  test "super admin sees admin link on a post and the page is not cached publicly" do
    sign_in_as(users(:one))
    show posts(:one)
    assert_response :success
    assert_select 'header nav a[href="/milo"]', text: "Admin", count: 1
    cache_control = response.headers["Cache-Control"]
    assert_match(/no-store/, cache_control)
    assert_match(/private/, cache_control)
    assert_no_match(/public/, cache_control)
    assert response.headers["ETag"].blank?, "expected no ETag for super admin, got #{response.headers["ETag"].inspect}"
  end

  test "super admin sending the anonymous etag gets a fresh post page with the admin link" do
    show posts(:one)
    anonymous_etag = response.headers["ETag"]
    assert anonymous_etag.present?

    sign_in_as(users(:one))
    show posts(:one), headers: { "If-None-Match" => anonymous_etag }
    assert_response :success
    assert_select 'header nav a[href="/milo"]', text: "Admin", count: 1
  end

  # Admin link: regular user
  test "regular logged-in user sees no admin link on a post and gets the public page" do
    show posts(:one)
    anonymous_etag = response.headers["ETag"]

    sign_in_as(users(:two))
    show posts(:one)
    assert_response :success
    assert_select 'a[href="/milo"]', count: 0
    assert_match(/public/, response.headers["Cache-Control"])
    assert_match(/max-age=300/, response.headers["Cache-Control"])
    assert_equal anonymous_etag, response.headers["ETag"]
  end

  # R3e/R4: admin JS loads only on Avo pages
  test "public home and post pages do not load avo_admin" do
    get "/"
    assert_response :success
    assert_not_includes response.body, "avo_admin"
    show posts(:one)
    assert_response :success
    assert_not_includes response.body, "avo_admin"
  end

  # Clickable links Req 5
  test "post page tags are plain labels in a tag-list without pill class" do
    show posts(:one)
    assert_select ".pill", count: 0
    assert_select "article ul.tag-list li", text: tags(:one).name
    css_select("article ul.tag-list li").each do |li|
      assert_empty li.element_children
      assert_nil li["class"]
    end
    assert_select "[style]", count: 0
  end

  # Editorial star rating
  def ld_json_scripts
    css_select('script[type="application/ld+json"]').map { |n| JSON.parse(n.text) }
  end

  def star_rating_node
    node = css_select(".star-rating").first
    assert node, "expected a .star-rating element"
    node
  end

  def review_ld
    data = json_ld("Review")
    assert data, "expected Review JSON-LD"
    data
  end

  # Text a screen reader announces: everything outside aria-hidden subtrees.
  def accessible_text(node)
    return "" if node.element? && node["aria-hidden"] == "true"
    return node.text if node.text?
    node.children.map { |child| accessible_text(child) }.join
  end

  # Rating Req 8
  test "rated review shows the star rating between the h1 and the date line" do
    show posts(:one)
    assert_select "header .star-rating", count: 1
    rating = star_rating_node
    assert_equal "h1", rating.previous_element&.name, "star rating must come directly after the h1"
    date_line = rating.next_element
    assert date_line, "expected the date line after the star rating"
    assert date_line.at_css("time[datetime]"), "expected the date line directly after the star rating"
  end

  test "rated review star rating has visible text and decorative svgs" do
    show posts(:one)
    rating = star_rating_node
    assert_equal "4.5 out of 5", accessible_text(rating).squish
    svgs = rating.css("svg")
    assert_operator svgs.size, :>=, 1
    svgs.each do |svg|
      hidden = svg.ancestors.any? { |a| a.respond_to?(:[]) && a["aria-hidden"] == "true" } || svg["aria-hidden"] == "true"
      assert hidden, "every star svg must be aria-hidden"
    end
  end

  test "star rating uses no javascript" do
    show posts(:one)
    rating = star_rating_node
    assert_empty rating.css("script")
    assert_empty rating.css("[data-controller]")
    assert_nil rating["data-controller"]
  end

  test "whole-number rating shows without a decimal" do
    show posts(:two)
    assert_equal "4 out of 5", accessible_text(star_rating_node).squish
    assert_not_includes response.body, "4.0 out of 5"
  end

  # Rating Req 10
  test "rated review renders BlogPosting and a Review JSON-LD block" do
    post = posts(:one)
    show post
    scripts = ld_json_scripts
    assert_equal 2, scripts.size
    assert_equal %w[BlogPosting Review], scripts.map { |j| j["@type"] }

    expected = {
      "@context" => "https://schema.org",
      "@type" => "Review",
      "name" => post.title,
      "url" => post_url(post.slug),
      "datePublished" => post.published_at.iso8601,
      "itemReviewed" => { "@type" => "SoftwareApplication", "name" => "Example Tool" },
      "reviewRating" => { "@type" => "Rating", "ratingValue" => 4.5, "bestRating" => 5, "worstRating" => 1 },
      "author" => { "@type" => "Person", "name" => "Neeraj Singh" },
      "publisher" => { "@type" => "Organization", "name" => "HypeBusted" }
    }
    assert_equal expected, review_ld
  end

  test "Review JSON-LD ratingValue is a JSON number, an integer for whole ratings" do
    show posts(:two)
    rating = review_ld["reviewRating"]
    assert_equal 4, rating["ratingValue"]
    assert_kind_of Integer, rating["ratingValue"]
    assert_kind_of Integer, rating["bestRating"]
    assert_kind_of Integer, rating["worstRating"]
    assert_includes response.body, '"ratingValue":4,'
    assert_includes response.body, '"bestRating":5'
  end

  test "rated review keeps the BlogPosting JSON-LD unchanged" do
    post = posts(:one)
    show post
    site = { "@type" => "Organization", "name" => "HypeBusted" }
    expected = {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => post.title,
      "description" => post.seo_description,
      "datePublished" => post.published_at.iso8601,
      "dateModified" => post.updated_at.iso8601,
      "mainEntityOfPage" => post_url(post.slug),
      "author" => site,
      "publisher" => site
    }
    assert_equal expected, json_ld("BlogPosting")
  end

  # Rating Req 11
  test "visible rating text and JSON-LD ratingValue agree" do
    [ posts(:one), posts(:two) ].each do |post|
      show post
      value = review_ld["reviewRating"]["ratingValue"]
      assert_equal "#{value} out of 5", accessible_text(star_rating_node).squish
    end
  end

  test "reviewed item name is escaped in JSON-LD and not shown visibly" do
    post = Post.create!(title: "Escaping", post_type: :review, published_at: 1.hour.ago, content: "<div>x</div>",
      rating: 3, reviewed_item_name: "</script><script>alert(1)</script>")
    show post
    assert_response :success
    assert_equal "</script><script>alert(1)</script>", review_ld["itemReviewed"]["name"]
    assert_equal 2, css_select("script").count { |s| s["type"] == "application/ld+json" }
    assert_not_includes response.body, "<script>alert(1)</script>"
  end

  # Rating Req 5/9
  test "unrated review and comparison render no star rating and only BlogPosting JSON-LD" do
    [ posts(:four), posts(:three), posts(:no_video) ].each do |post|
      assert_nil post.rating
      show post
      assert_response :success
      assert_select ".star-rating", count: 0
      assert_select "article header svg", count: 0
      assert_not_includes response.body, "out of 5"
      assert_equal [ "BlogPosting" ], ld_json_scripts.map { |j| j["@type"] }
    end
  end

  test "unrated post page has no inline styles" do
    show posts(:four)
    assert_select "[style]", count: 0
  end
end
