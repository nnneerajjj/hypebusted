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
end
