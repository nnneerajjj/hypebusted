require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "should create a valid post" do
    post = Post.new(
      title: "My First Blog Post",
      content: "This is the content of my first blog post.",
      post_type: "review",
      published_at: Time.current,
    )
    assert post.valid?
    assert post.save
    assert_equal "My First Blog Post", post.title
    assert_equal "review", post.post_type
  end

  test "should not create a post without a title" do
    post = Post.new(content: "Content", post_type: "review")
    refute post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "should not create a post without content" do
    post = Post.new(title: "Title", post_type: "review")
    refute post.valid?
    assert_includes post.errors[:content], "can't be blank"
  end

  test "should not create a post without a post_type" do
    post = Post.new(title: "Title", content: "Content")
    refute post.valid?
    assert_includes post.errors[:post_type], "can't be blank"
  end

  test "should generate a friendly slug" do
    post = Post.create!(
      title: "My Awesome Post Title for SEO",
      content: "Some content.",
      post_type: "review",
    )
    assert_equal "my-awesome-post-title-for-seo", post.slug
  end

  test "should have post_type as an enum" do
    post = Post.new(
      title: "Enum Test",
      content: "Enum content.",
      post_type: "review",
    )
    assert_equal "review", post.post_type

    post.post_type = "comparison"
    assert_equal "comparison", post.post_type

    post.post_type = "journal"
    assert_equal "journal", post.post_type

    # Test invalid enum type - this should throw an error during initialization
    begin
      invalid_post = Post.new(
        title: "Invalid Enum",
        content: "Invalid content.",
        post_type: "invalid_type",
      )
      # If we get here, the validation didn't throw an error, so the test should fail
      refute invalid_post.valid?
      assert_includes invalid_post.errors[:post_type], "is not included in the list"
    rescue ArgumentError => e
      # This is expected - the enum validation should throw an error
      assert e.message.include?("is not a valid post_type")
    end
  end

  test "content is stored as rich text and survives a save" do
    post = Post.create!(title: "Rich", content: "<div>Hello <strong>world</strong></div>", post_type: :review)

    post.reload
    assert_equal "<div>Hello <strong>world</strong></div>", post.content.body.fragment.to_html
    assert_equal "Hello world", post.content.to_plain_text
  end

  test "content is required" do
    post = Post.new(title: "No body", post_type: :review)

    assert_not post.valid?
    assert_includes post.errors[:content], "can't be blank"
  end

  # Req 16
  test "slug must be unique" do
    dup = Post.new(title: "Other", slug: posts(:one).slug, content: "x", post_type: :review)
    assert_not dup.valid?
    assert_includes dup.errors[:slug], "has already been taken"
  end

  test "to_param is the id, so Avo can use plain ids" do
    assert_equal posts(:one).id.to_s, posts(:one).to_param
  end

  test "admin-entered slug is normalized" do
    post = Post.new(title: "T", slug: "  My Custom_Slug!  ", content: "x", post_type: :review)
    assert post.valid?
    assert_equal "my-custom_slug", post.slug
  end

  test "blank slug is generated from title" do
    post = Post.new(title: "Daily Log", slug: "", content: "x", post_type: :review)
    assert post.valid?
    assert_equal "daily-log", post.slug
  end

  test "slug that normalizes to nothing is invalid" do
    post = Post.new(title: "T", slug: "!!!", content: "x", post_type: :review)
    assert_not post.valid?
    assert_includes post.errors[:slug], "can't be blank"
  end

  test "normalized slug that matches another post is taken" do
    post = Post.new(title: "T", slug: " First Blog Post ", content: "x", post_type: :review)
    assert_not post.valid?
    assert_includes post.errors[:slug], "has already been taken"
  end

  # Req 6
  test "seo_description is squished plain text truncated to 155" do
    post = Post.new(title: "T", post_type: :review, content: "<div>Hello   <strong>world</strong>\n again</div>")
    assert_equal "Hello world again", post.seo_description
    long = Post.new(title: "T", post_type: :review, content: "<div>#{'abc ' * 100}</div>")
    assert_operator long.seo_description.length, :<=, 155
  end

  # Raw HTML editing (Avo "Edit as HTML")
  test "content_html returns the stored body HTML" do
    assert_equal "<div>This is the content for the first blog post.</div>", posts(:one).content_html
  end

  test "content_html is empty for a new post" do
    assert_equal "", Post.new.content_html
  end

  # R1a: the HTML editor is the default
  test "html_editor defaults to true" do
    assert_equal true, Post.new.html_editor
  end

  test "html_editor is true on a post loaded from the database" do
    assert_equal true, Post.find(posts(:one).id).html_editor
  end

  # R1f: callers that only set content (seeds, tests) still save it
  test "creating a post with only content saves that content" do
    post = Post.create!(title: "Content Only", content: "<div>Only content</div>", post_type: :review)
    assert_equal "<div>Only content</div>", post.reload.content.body.to_html
  end

  test "updating only content saves that content" do
    post = posts(:one)
    post.update!(content: "<div>Updated content</div>")
    assert_equal "<div>Updated content</div>", post.reload.content.body.to_html
  end

  # R1e: a full article saved in HTML mode keeps headings, classes and attachment attributes
  test "full article saved in HTML mode keeps headings, compare block and attachment" do
    blob = image_blob
    post = posts(:one)
    post.update!(html_editor: true, content_html: article_html(blob))

    body = post.reload.content.body.to_html
    assert_includes body, COMPARE_BLOCK_HTML
    assert_includes body, "<h2>Section heading</h2>"
    assert_includes body, "<h3>Sub heading</h3>"

    attachment = Nokogiri::HTML5.fragment(body).at_css("action-text-attachment")
    assert attachment, "expected an action-text-attachment in #{body}"
    assert_equal blob, ActionText::Attachable.from_attachable_sgid(attachment["sgid"])
    assert_equal "Cap", attachment["caption"]
    assert_equal "gallery", attachment["presentation"]
    assert_equal blob.id, post.cover_image.blob.id
  end

  test "html_editor true replaces content with content_html on save" do
    post = posts(:one)
    post.update!(html_editor: true, content_html: "<h1>New</h1>")
    assert_equal "<h1>New</h1>", post.reload.content.body.to_html
  end

  test "html_editor true makes content_html win over content assigned in the same update" do
    post = posts(:one)
    post.update!(html_editor: true, content: "<div>trix</div>", content_html: "<h1>Raw</h1>")
    assert_equal "<h1>Raw</h1>", post.reload.content.body.to_html
  end

  test "html_editor false ignores content_html" do
    post = posts(:one)
    post.update!(html_editor: false, content_html: "<h1>Ignored</h1>")
    assert_equal "<div>This is the content for the first blog post.</div>", post.reload.content.body.to_html
  end

  test "html_editor cast from Avo's checkbox values" do
    post = Post.new(html_editor: "1")
    assert_equal true, post.html_editor
    post.html_editor = "0"
    assert_equal false, post.html_editor
  end

  test "html_editor true with blank content_html is invalid on content" do
    post = posts(:one)
    post.assign_attributes(html_editor: true, content_html: "")
    assert_not post.valid?
    assert_includes post.errors[:content], "can't be blank"
    assert_equal "", post.content_html
  end

  test "content_html normalizes CRLF to LF" do
    post = Post.new
    post.content_html = "<div>a</div>\r\n<div>b</div>"
    assert_equal "<div>a</div>\n<div>b</div>", post.content_html
  end

  test "CRLF in content_html is stored as LF" do
    post = posts(:one)
    post.update!(html_editor: true, content_html: "<div>a</div>\r\n<div>b</div>")
    body = post.reload.content.body.to_html
    assert_includes body, "<div>b</div>"
    assert_not_includes body, "\r"
  end

  test "html with an image attachment saved in HTML mode keeps cover_image" do
    blob = image_blob
    post = posts(:one)
    post.update!(html_editor: true,
      content_html: %(<div>Intro<action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment></div>))
    cover = post.reload.cover_image
    assert cover, "expected cover_image"
    assert_equal blob.id, cover.blob_id
  end

  # Tag selection (Avo multiple select, submitted as tag_ids_input)
  test "tag_ids_input sets tags on save for a new post" do
    post = Post.new(title: "Tagged New", content: "<div>x</div>", post_type: :review)
    post.tag_ids_input = [ tags(:two).id.to_s, tags(:three).id.to_s ]
    post.save!

    assert_equal [ tags(:two).id, tags(:three).id ].sort, post.reload.tag_ids.sort
  end

  test "tag_ids_input replaces the tag set on save" do
    post = posts(:one)
    post.tag_ids_input = [ tags(:three).id.to_s ]
    post.save!

    assert_equal [ tags(:three).id ], post.reload.tag_ids
  end

  test "tag_ids_input nil leaves tags unchanged" do
    post = posts(:one)
    post.tag_ids_input = nil
    post.save!

    assert_equal [ tags(:one).id ], post.reload.tag_ids
  end

  test "tag_ids_input empty array clears tags" do
    post = posts(:one)
    post.tag_ids_input = []
    post.save!

    assert_empty post.reload.tags
  end

  test "tag_ids_input ignores unknown, non-numeric and huge ids" do
    post = posts(:one)
    post.tag_ids_input = [ "999999", "abc", "9999999999999999999999", tags(:two).id.to_s ]
    assert_nothing_raised { post.save! }

    assert_equal [ tags(:two).id ], post.reload.tag_ids
  end

  test "tag_ids_input dedupes ids without a unique-index error" do
    post = posts(:one)
    post.tag_ids_input = [ tags(:two).id.to_s, tags(:two).id.to_s ]
    assert_nothing_raised { post.save! }

    assert_equal [ tags(:two).id ], post.reload.tag_ids
  end

  test "invalid save does not change taggings" do
    post = posts(:one)
    post.tag_ids_input = [ tags(:two).id.to_s, tags(:three).id.to_s ]
    post.title = ""
    assert_not post.save

    assert_equal [ tags(:one).id ], Tagging.where(post_id: posts(:one).id).pluck(:tag_id)
    assert_equal [ tags(:two).id.to_s, tags(:three).id.to_s ].sort, post.tag_ids_input.sort
  end

  test "tag_ids_input reader returns current ids as strings" do
    assert_equal [ "#{tags(:one).id}" ], posts(:one).tag_ids_input
  end

  test "html_editor save keeps tag_ids_input tags" do
    post = posts(:one)
    post.update!(html_editor: true, content_html: "<h1>x</h1>", tag_ids_input: [ tags(:two).id.to_s ])

    assert_equal [ tags(:two).id ], post.reload.tag_ids
  end

  test "changing only tags bumps updated_at so the ETag changes" do
    post = posts(:one)
    before = post.updated_at
    travel 1.minute do
      post.update!(tag_ids_input: [ tags(:two).id.to_s ])
    end

    assert_operator post.reload.updated_at, :>, before
  end

  test "saving the same tags does not bump updated_at" do
    post = posts(:one)
    before = post.reload.updated_at
    travel 1.minute do
      post.update!(tag_ids_input: [ tags(:one).id.to_s ])
    end

    assert_equal before, post.reload.updated_at
  end

  test "youtube_video_id accepts an 11-character id or blank" do
    post = posts(:one)
    [ "dQw4w9WgXcQ", "a_b-c_d-e_f", "", nil ].each do |id|
      post.youtube_video_id = id
      assert post.valid?, "expected #{id.inspect} to be valid"
    end
  end

  test "youtube_video_id rejects urls, query strings and paths" do
    post = posts(:one)
    [ "https://youtu.be/dQw4w9WgXcQ", "abc?autoplay=1&mute=1", "../watch?v=x", "short" ].each do |id|
      post.youtube_video_id = id
      assert_not post.valid?, "expected #{id.inspect} to be invalid"
      assert post.errors[:youtube_video_id].any?
    end
  end

  # Editorial rating
  def rated_post(rating, post_type: :review, reviewed_item_name: "Example Tool")
    Post.new(title: "Rated", content: "x", post_type: post_type, rating: rating, reviewed_item_name: reviewed_item_name)
  end

  # Rating Req 12
  test "rating scale constants" do
    assert_equal 1, Post::WORST_RATING
    assert_equal 5, Post::BEST_RATING
    assert_equal [ 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0 ], Post::RATINGS
  end

  # Rating Req 2
  test "every half-star rating from 1 to 5 is valid on a review" do
    Post::RATINGS.each do |rating|
      post = rated_post(rating)
      assert post.valid?, "expected #{rating} to be valid: #{post.errors.full_messages}"
    end
  end

  test "rating given as a form string is valid" do
    assert rated_post("4.5").valid?
  end

  test "nil rating is valid on a review" do
    assert rated_post(nil, reviewed_item_name: nil).valid?
  end

  test "ratings outside the scale or off the half-star step are invalid" do
    [ 0, 0.5, 4.3, 5.5 ].each do |rating|
      post = rated_post(rating)
      assert_not post.valid?, "expected #{rating} to be invalid"
      assert post.errors[:rating].any?, "expected a rating error for #{rating}"
    end
  end

  # Rating Req 3
  test "rating on a comparison or journal post is invalid" do
    %i[comparison journal].each do |type|
      post = rated_post(4, post_type: type)
      assert_not post.valid?, "expected rating on #{type} to be invalid"
      assert post.errors[:rating].any?, "expected a rating error on #{type}"
    end
  end

  test "nil rating is valid on every post type" do
    Post.post_types.each_key do |type|
      assert rated_post(nil, post_type: type, reviewed_item_name: nil).valid?, "expected unrated #{type} to be valid"
    end
  end

  test "changing a rated review to a comparison is invalid until the rating is cleared" do
    post = posts(:one)
    post.post_type = :comparison
    assert_not post.valid?
    post.rating = nil
    assert post.valid?
  end

  # Rating Req 4
  test "rating requires a reviewed item name" do
    [ nil, "", "  " ].each do |name|
      post = rated_post(4.5, reviewed_item_name: name)
      assert_not post.valid?, "expected #{name.inspect} reviewed_item_name to be invalid"
      assert_includes post.errors[:reviewed_item_name], "can't be blank"
    end
  end

  test "reviewed item name without a rating is allowed" do
    assert rated_post(nil, reviewed_item_name: "Example Tool").valid?
  end

  # Rating Req 1/5
  test "rating persists as a decimal and unrated fixtures stay valid" do
    assert_equal BigDecimal("4.5"), posts(:one).reload.rating
    assert_equal "Example Tool", posts(:one).reviewed_item_name
    %i[three four draft future no_video].each do |name|
      assert_nil posts(name).rating
      assert posts(name).valid?, "expected #{name} to stay valid"
    end
  end

  # Rating Req 6
  test "rating_value is nil without a rating" do
    assert_nil rated_post(nil).rating_value
  end

  test "rating_value is an Integer for whole ratings" do
    value = rated_post(4).rating_value
    assert_equal 4, value
    assert_kind_of Integer, value
    assert_equal "4", value.to_s
    assert_equal "4", value.to_json
  end

  test "rating_value is a Float for half ratings" do
    value = rated_post(4.5).rating_value
    assert_equal 4.5, value
    assert_kind_of Float, value
    assert_equal "4.5", value.to_s
    assert_equal "4.5", value.to_json
  end

  test "rating_value from a persisted decimal rating" do
    assert_equal 4.5, posts(:one).reload.rating_value
    assert_kind_of Integer, posts(:two).reload.rating_value
    assert_equal 4, posts(:two).rating_value
  end
end
