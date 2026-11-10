require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "logged out visitor can see the home page" do
    get root_path
    assert_response :success
    assert_select "h1", /HypeBusted/i
  end

  test "lists published posts newest first" do
    get root_path
    assert_response :success
    assert_select "article", minimum: 1
    assert_select "article h3", text: posts(:one).title
  end

  test "groups posts into comparisons, reviews and journal sections in that order" do
    journal = Post.create!(title: "Today I Tried Things", post_type: :journal, content: "x", published_at: 1.hour.ago)

    get root_path
    assert_select "section#comparisons article h3", text: posts(:three).title
    assert_select "section#reviews article h3", text: posts(:one).title
    assert_select "section#journal article h3", text: journal.title

    assert_select "section#comparisons article h3", text: posts(:one).title, count: 0
    assert_select "section#reviews article h3", text: posts(:three).title, count: 0

    ids = css_select("main section[id]").map { |n| n["id"] }
    assert_equal %w[comparisons reviews journal], ids & %w[comparisons reviews journal]
  end

  test "omits a section that has no posts" do
    get root_path
    assert_select "section#journal", count: 0
  end

  test "hides unpublished and future posts" do
    draft = Post.create!(title: "Secret Draft", post_type: :journal, content: "x", published_at: nil)
    future = Post.create!(title: "Future Post", post_type: :journal, content: "x", published_at: 1.day.from_now)

    get root_path
    assert_select "article h3", text: draft.title, count: 0
    assert_select "article h3", text: future.title, count: 0
  end

  test "shows the empty state without posts" do
    Post.destroy_all
    get root_path
    assert_response :success
    assert_select "article", count: 0
    assert_select "p", /nothing published yet/i
  end

  # Req 3
  test "every card links once to its show page" do
    journal = Post.create!(title: "Linked Journal", post_type: :journal, content: "x", published_at: 1.hour.ago)
    get root_path
    [ posts(:one), posts(:three), journal ].each do |post|
      assert_select "article a[href=?]", "/posts/#{post.slug}", count: 1
    end
  end

  # Req 5
  test "home keeps its own title" do
    get root_path
    assert_select "title", text: /HypeBusted/
    assert_select "title", text: /\| HypeBusted\z/, count: 0
  end

  # Req 7, 8, 9
  test "home has canonical, lang, social tags and WebSite JSON-LD" do
    get root_path, params: { ref: "x" }
    assert_select "html[lang=en]"
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/"
    assert_select 'meta[property="og:title"]'
    assert_select 'meta[property="og:description"]'
    assert_select 'meta[property="og:type"][content=website]'
    assert_select 'meta[property="og:url"]'
    assert_select 'meta[property="og:site_name"]'
    assert_select 'meta[name="twitter:card"][content=summary]'
    data = css_select('script[type="application/ld+json"]').map { |n| JSON.parse(n.text) }
    assert data.any? { |j| j["@type"] == "WebSite" }
  end

  # Req 13
  test "home sends etag and public cache-control and honours If-None-Match" do
    get root_path
    assert response.headers["ETag"].present?
    assert_match(/public/, response.headers["Cache-Control"])
    get root_path, headers: { "If-None-Match" => response.headers["ETag"] }
    assert_response :not_modified
  end

  # Req 14/15
  test "home has no inline styles or arbitrary value classes" do
    get root_path
    assert_select "[style]", count: 0
    assert_no_match(/class="[^"]*\[/, response.body)
  end

  # Admin link: anonymous
  test "anonymous visitor sees no admin link and gets public caching" do
    get root_path
    assert_response :success
    assert_select 'a[href="/milo"]', count: 0
    assert_match(/public/, response.headers["Cache-Control"])
    assert_match(/max-age=300/, response.headers["Cache-Control"])
    assert response.headers["ETag"].present?
  end

  # Admin link: super admin
  test "super admin sees admin link and the page is not cached publicly" do
    sign_in_as(users(:one))
    get root_path
    assert_response :success
    assert_select 'header nav a[href="/milo"]', text: "Admin", count: 1
    cache_control = response.headers["Cache-Control"]
    assert_match(/no-store/, cache_control)
    assert_match(/private/, cache_control)
    assert_no_match(/public/, cache_control)
    assert response.headers["ETag"].blank?, "expected no ETag for super admin, got #{response.headers["ETag"].inspect}"
  end

  test "super admin sending the anonymous etag gets a fresh page with the admin link" do
    get root_path
    anonymous_etag = response.headers["ETag"]
    assert anonymous_etag.present?

    sign_in_as(users(:one))
    get root_path, headers: { "If-None-Match" => anonymous_etag }
    assert_response :success
    assert_select 'header nav a[href="/milo"]', text: "Admin", count: 1
  end

  # Admin link: regular user
  test "regular logged-in user sees no admin link and gets the public page" do
    get root_path
    anonymous_etag = response.headers["ETag"]

    sign_in_as(users(:two))
    get root_path
    assert_response :success
    assert_select 'a[href="/milo"]', count: 0
    assert_match(/public/, response.headers["Cache-Control"])
    assert_match(/max-age=300/, response.headers["Cache-Control"])
    assert_equal anonymous_etag, response.headers["ETag"]
  end

  # Clickable links Req 1
  test "comparison cards have a decorative Read comparison CTA with a centred svg arrow in a circle" do
    get root_path
    assert_select "section#comparisons article", minimum: 1
    css_select("section#comparisons article").each do |card|
      cta = card.css('[aria-hidden="true"]').find { |n| n.text.include?("Read comparison") }
      assert cta, "expected an aria-hidden CTA with text 'Read comparison'"
      svg = cta.at_css(".cta-circle svg")
      assert svg, "expected .cta-circle svg inside the CTA"
      assert_equal "true", svg["aria-hidden"]
      assert_equal "false", svg["focusable"]
      assert_equal "none", svg["fill"]
      assert_equal "currentColor", svg["stroke"]
      assert_equal "0 0 24 24", svg["viewbox"] || svg["viewBox"]
      assert_equal "M5 12h14M13 6l6 6-6 6", svg.at_css("path")&.[]("d")
    end
  end

  # Clickable links Req 2
  test "review cards have a decorative Read review CTA with the svg arrow" do
    get root_path
    assert_select "section#reviews article", minimum: 1
    css_select("section#reviews article").each do |card|
      cta = card.css('[aria-hidden="true"]').find { |n| n.text.include?("Read review") }
      assert cta, "expected an aria-hidden CTA with text 'Read review'"
      svg = cta.at_css("svg")
      assert svg, "expected an svg arrow inside the review CTA"
      assert_equal "currentColor", svg["stroke"]
      assert_equal "M5 12h14M13 6l6 6-6 6", svg.at_css("path")&.[]("d")
    end
  end

  # Clickable links Req 3
  test "journal rows end with one aria-hidden svg chevron after the time" do
    Post.create!(title: "Chevron Journal", post_type: :journal, content: "x", published_at: 1.hour.ago)
    Post.create!(title: "Second Chevron Journal", post_type: :journal, content: "x", published_at: 2.hours.ago)
    get root_path
    rows = css_select("section#journal article")
    assert_equal 2, rows.size
    rows.each do |row|
      svgs = row.css("svg")
      assert_equal 1, svgs.size, "expected exactly one svg chevron per journal row"
      assert_equal "true", svgs.first["aria-hidden"]
      children = row.element_children.map(&:name)
      assert_operator children.index("svg").to_i, :>, children.index("time").to_i, "chevron must come after <time>"
      assert_equal "svg", children.last
    end
  end

  # Clickable links Req 1/2
  test "home uses no text arrow glyph" do
    Post.create!(title: "Glyph Journal", post_type: :journal, content: "x", published_at: 1.hour.ago)
    get root_path
    assert_not_includes response.body, "→"
    assert_not_includes response.body, "&rarr;"
  end

  # Clickable links Req 4
  test "CTA, arrow and chevron are not links; each card has only the title link" do
    Post.create!(title: "Single Link Journal", post_type: :journal, content: "x", published_at: 1.hour.ago)
    get root_path
    assert_select "article a svg", count: 0
    assert_select "article a .cta-circle", count: 0
    assert_select "article a", text: /Read (comparison|review)/, count: 0
    css_select("main article").each do |card|
      assert_equal 1, card.css("a").size, "expected exactly one link per card"
      assert_includes card.css("a").first["class"].to_s, "stretched-link"
    end
  end

  # Clickable links Req 5
  test "home tags are plain labels in a tag-list without pill class" do
    get root_path
    assert_select ".pill", count: 0
    assert_select "section#reviews article ul.tag-list li", text: tags(:one).name
    css_select("ul.tag-list li").each do |li|
      assert_empty li.element_children, "tag li should hold only the tag name"
      assert_nil li["class"]
    end
    assert_select "section#comparisons article ul", count: 0
  end

  # Clickable links Req 6
  test "home with CTAs, chevrons and tags has no inline styles or arbitrary value classes" do
    Post.create!(title: "Style Journal", post_type: :journal, content: "x", published_at: 1.hour.ago)
    get root_path
    assert_select "section#comparisons .cta-circle svg", minimum: 1
    assert_select "section#journal article svg", minimum: 1
    assert_select "[style]", count: 0
    assert_no_match(/class="[^"]*\[/, response.body)
    assert_no_match(/6fdcae/i, response.body)
  end
end
