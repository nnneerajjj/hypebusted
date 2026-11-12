# Check an article's HTML against what hypebusted.com will actually keep and show.
#
# Run from the repo root:
#   bin/rails runner .claude/skills/article-writing/scripts/check_article.rb ARTICLE.html "Post title"
#
# It pushes the HTML through the same Action Text sanitizer the public page uses and reports:
#   - tags and attributes that would be silently stripped (tables, inline style, iframes...)
#   - the <title> tag text (the site cuts the post title to 47 characters), the meta description
#     (first 155 characters of the plain text) and a slug suggestion
#   - structure counts, word count, very long paragraphs, leftover placeholders, missing disclosure/date
# Exit status 1 if anything in the "FAIL" group is found.
path, title = ARGV
abort "usage: bin/rails runner check_article.rb ARTICLE.html \"Post title\"" unless path && title

html = File.read(path)
content = ActionText::Content.new(html)
src = Nokogiri::HTML5.fragment(html)
out = Nokogiri::HTML5.fragment(content.to_s)

tags = ->(frag) { frag.css("*").map(&:name).tally }
attrs = ->(frag) { frag.css("*").flat_map { |n| n.attribute_nodes.map(&:name) }.tally }
lost_tags = tags.(src).reject { |name, count| tags.(out).fetch(name, 0) >= count }.keys
lost_attrs = attrs.(src).reject { |name, count| attrs.(out).fetch(name, 0) >= count }.keys
text = content.to_plain_text.to_s
description = text.squish.truncate(155)
paragraphs = src.css("p").map { |p| p.text.split.size }
fail_reasons = []
warn_reasons = []

fail_reasons << "stripped tags: #{lost_tags.join(', ')} (the page will drop them; use lists, headings and the .compare block instead)" if lost_tags.any?
fail_reasons << "stripped attributes: #{lost_attrs.join(', ')} (inline style is not allowed; use classes defined in utilities.css)" if lost_attrs.any?
fail_reasons << "placeholder [[IMAGE]] is still in the HTML; replace it with the attachment tag from the editor" if html.include?("[[IMAGE]]")
fail_reasons << "no <h2> sections" if src.css("h2").empty?
fail_reasons << "contains an <h1>; the page already renders the title as the only h1" if src.css("h1").any?

warn_reasons << "title is #{title.length} characters; the <title> tag truncates at 47, so put the search words first" if title.length > 47
warn_reasons << "no affiliation or disclosure wording found (say whether you are sponsored or use affiliate links)" unless text =~ /affiliat|sponsor|no affiliate/i
warn_reasons << "no year found; date-stamp prices and claims (for example \"checked November 2026\")" unless text =~ /20\d\d/
warn_reasons << "#{paragraphs.count { |n| n > 120 }} paragraph(s) over 120 words; split them for mobile readers" if paragraphs.any? { |n| n > 120 }
warn_reasons << "description starts with a heading-like or very short sentence; make the first paragraph a self-contained summary" if description.length < 100
warn_reasons << "no image or figure in the body (an infographic should be the first image; it becomes the social image)" if src.css("action-text-attachment, img, figure").empty?
warn_reasons << "no outbound or internal links" if src.css("a").empty?

puts "Title tag:    #{title.truncate(47)} | HypeBusted"
puts "Slug idea:    #{title.parameterize.split('-').first(8).join('-')}   (shorten to the search phrase)"
puts "Description:  #{description} (#{description.length} chars)"
puts "Structure:    #{src.css('h2').size} h2, #{src.css('h3').size} h3, #{src.css('ul').size} ul, #{src.css('ol').size} ol, " \
     "#{src.css('blockquote').size} blockquote, #{src.css('.compare').size} compare block(s), #{src.css('a').size} link(s)"
puts "Words:        #{text.split.size}"
puts "Longest para: #{paragraphs.max || 0} words"
puts
puts "FAIL: #{fail_reasons.empty? ? 'none' : ''}"
fail_reasons.each { |r| puts "  - #{r}" }
puts "WARN: #{warn_reasons.empty? ? 'none' : ''}"
warn_reasons.each { |r| puts "  - #{r}" }
exit(fail_reasons.empty? ? 0 : 1)
