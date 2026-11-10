require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  # Req 12
  test "sitemap is xml listing home and published posts with lastmod" do
    get "/sitemap.xml"
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

  test "sitemap is reachable logged out and logged in" do
    get "/sitemap.xml"
    assert_response :success
    sign_in_as(users(:one))
    get "/sitemap.xml"
    assert_response :success
  end
end
