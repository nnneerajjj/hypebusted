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
end

