require "test_helper"

class BrandAssetsTest < ActionDispatch::IntegrationTest
  # Browsers request favicon and touch icons from fixed root URLs, so these must live in public/.
  test "favicon and app icons are in public/" do
    %w[favicon.ico favicon.svg apple-touch-icon.png icon-192.png icon-512.png].each do |name|
      assert Rails.root.join("public", name).exist?, "missing public/#{name}"
    end
  end

  test "layout links the favicon and apple touch icon" do
    get root_path
    assert_response :success
    assert_select 'link[rel="icon"][href="/favicon.ico"]'
    assert_select 'link[rel="icon"][href="/favicon.svg"][type="image/svg+xml"]'
    assert_select 'link[rel="apple-touch-icon"][href="/apple-touch-icon.png"]'
  end

  test "header shows the logo, linked to the home page" do
    get root_path
    assert_response :success
    assert_select "header a[href=?] img[alt=?][src*=?]", root_path, "HypeBusted", "hypebusted-header-on-light"
  end
end
