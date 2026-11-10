require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  def svg_for(html)
    Nokogiri::HTML5.fragment(html).at_css("svg")
  end

  # Clickable links Req 7
  test "link_icon arrow renders a decorative, symmetric inline svg" do
    svg = svg_for(link_icon(:arrow))
    assert svg, "expected an svg"
    assert_equal "true", svg["aria-hidden"]
    assert_equal "false", svg["focusable"]
    assert_equal "none", svg["fill"]
    assert_equal "currentColor", svg["stroke"]
    assert_equal "0 0 24 24", svg["viewbox"] || svg["viewBox"]
    assert_equal "M5 12h14M13 6l6 6-6 6", svg.at_css("path")["d"]
    assert_nil svg["style"]
  end

  test "link_icon chevron renders the chevron path" do
    svg = svg_for(link_icon(:chevron))
    assert_equal "M9 6l6 6-6 6", svg.at_css("path")["d"]
    assert_equal "true", svg["aria-hidden"]
  end

  test "link_icon passes class through and never sets style" do
    html = link_icon(:arrow, class: "size-5")
    svg = svg_for(html)
    assert_equal "size-5", svg["class"]
    assert_nil svg["style"]
    assert html.html_safe?
  end

  test "time_tag_for renders a time element with an ISO datetime and the given format" do
    time = Time.utc(2026, 3, 5, 14, 30)
    el = Nokogiri::HTML5.fragment(time_tag_for(time, "%b %-d, %Y")).at_css("time")
    assert_equal time.iso8601, el["datetime"]
    assert_equal "Mar 5, 2026", el.text
    assert_nil el["class"]
  end

  test "time_tag_for passes class through" do
    el = Nokogiri::HTML5.fragment(time_tag_for(Time.utc(2026, 3, 5), "%b %-d", class: "eyebrow")).at_css("time")
    assert_equal "eyebrow", el["class"]
    assert_equal "Mar 5", el.text
  end
end
