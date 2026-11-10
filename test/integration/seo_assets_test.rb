require "test_helper"

class SeoAssetsTest < ActionDispatch::IntegrationTest
  # Req 12
  test "robots.txt allows all, blocks admin and session, lists sitemap" do
    txt = Rails.root.join("public/robots.txt").read
    assert_match(/^User-agent: \*/i, txt)
    assert_match(%r{^Disallow: /milo}i, txt)
    assert_match(%r{^Disallow: /session}i, txt)
    assert_match(%r{^Sitemap: https?://\S+/sitemap\.xml}i, txt)
  end

  # Req 14
  test "utilities.css exists, is imported, defines prose-post" do
    util = Rails.root.join("app/assets/tailwind/utilities.css")
    assert util.exist?
    assert_match(/\.prose-post/, util.read)
    assert_match(/@import\s+["']\.\/utilities\.css["']/, Rails.root.join("app/assets/tailwind/application.css").read)
  end
end
