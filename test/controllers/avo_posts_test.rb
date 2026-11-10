require "test_helper"

class AvoPostsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @post = posts(:one)
  end

  test "opens a post in Avo by its id" do
    get "/milo/resources/posts/#{@post.id}"

    assert_response :success
    assert_includes response.body, @post.title
  end

  test "failed slug change keeps the form pointed at the same post" do
    other = posts(:two)

    patch "/milo/resources/posts/#{@post.id}", params: { post: { slug: other.slug } }

    assert_response :unprocessable_content
    assert_select "form[action=?]", "/milo/resources/posts/#{@post.id}"
    assert_equal "first-blog-post", @post.reload.slug
    assert_equal other.slug, other.reload.slug
  end

  test "admin-entered slug is saved normalized" do
    patch "/milo/resources/posts/#{@post.id}", params: { post: { slug: " New Slug Here " } }

    assert_equal "new-slug-here", @post.reload.slug
  end
end
