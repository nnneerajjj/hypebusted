require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  BROWSER = MODERN_BROWSER_HEADERS

  # Req 12
  test "sitemap is xml listing home and published posts with lastmod" do
    get "/sitemap.xml", headers: BROWSER
    assert_response :success
    assert_match %r{xml}, response.media_type
    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!
    locs = doc.xpath("//url/loc").map(&:text)
    assert_includes locs, "http://www.example.com/"
    assert_includes locs, "http://www.example.com/posts/first-blog-post"
    assert_not_includes locs, "http://www.example.com/posts/unfinished-draft-post"
    assert_not_includes locs, "http://www.example.com/posts/scheduled-future-post"
    assert_operator doc.xpath("//url/lastmod").size, :>=, Post.published.count
  end
end
