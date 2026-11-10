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
end
