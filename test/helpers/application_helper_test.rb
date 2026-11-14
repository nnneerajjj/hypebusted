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

  # Editorial star rating (Rating Req 8/11/12)
  def rating_fragment(rating)
    Nokogiri::HTML5.fragment(star_rating(Post.new(post_type: :review, rating: rating, reviewed_item_name: "Tool")))
  end

  # Fill percentage of the filled overlay, from an inline width style or a width attribute.
  def fill_widths(fragment)
    fragment.css("*").filter_map do |node|
      node["style"].to_s[/width:\s*([^;]+)/, 1]&.strip || (node["width"].to_s.end_with?("%") ? node["width"] : nil)
    end
  end

  def visible_text(node)
    return "" if node.element? && node["aria-hidden"] == "true"
    return node.text if node.text?
    node.children.map { |child| visible_text(child) }.join
  end

  test "author name is defined once next to the site name" do
    assert_equal "Neeraj Singh", ApplicationHelper::AUTHOR_NAME
  end

  test "star_rating wraps output in a star-rating element and is html safe" do
    html = star_rating(Post.new(post_type: :review, rating: 4.5, reviewed_item_name: "Tool"))
    assert html.html_safe?
    assert Nokogiri::HTML5.fragment(html).at_css(".star-rating"), "expected .star-rating wrapper"
  end

  test "star_rating visible text uses rating_value" do
    assert_equal "4.5 out of 5", visible_text(rating_fragment(4.5).at_css(".star-rating")).squish
    assert_equal "4 out of 5", visible_text(rating_fragment(4).at_css(".star-rating")).squish
    assert_equal "1 out of 5", visible_text(rating_fragment(1).at_css(".star-rating")).squish
  end

  test "star_rating svgs are hidden from assistive tech" do
    stars = rating_fragment(4.5).css("svg")
    assert_operator stars.size, :>=, 1
    stars.each do |svg|
      hidden = svg["aria-hidden"] == "true" || svg.ancestors.any? { |a| a.respond_to?(:[]) && a["aria-hidden"] == "true" }
      assert hidden, "expected star svg to be aria-hidden"
    end
  end

  test "star_rating draws five stars in the empty and the filled layers" do
    paths = rating_fragment(4.5).css("svg path, svg polygon, svg use").reject { |n| n.ancestors("defs, symbol").any? }
    assert_equal 10, paths.size, "expected 5 empty + 5 filled star shapes"
  end

  test "star_rating fill width is a clean integer percentage of the best rating" do
    { 4.5 => "90%", 5 => "100%", 1 => "20%", 4 => "80%", 2.5 => "50%" }.each do |rating, width|
      assert_equal [ width ], fill_widths(rating_fragment(rating)), "fill width for #{rating}"
    end
  end

  test "star_rating does not use the stroke-only link icon paths" do
    html = star_rating(Post.new(post_type: :review, rating: 3, reviewed_item_name: "Tool"))
    ApplicationHelper::ICON_PATHS.each_value { |d| assert_not_includes html, d }
  end
end
