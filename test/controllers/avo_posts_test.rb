require "test_helper"

class AvoPostsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @post = posts(:one)
  end

  test "opens a post in Avo by its slug" do
    assert_equal "first-blog-post", @post.to_param

    get "/milo/resources/posts/#{@post.to_param}"

    assert_response :success
    assert_includes response.body, @post.title
  end

  test "still opens a post in Avo by its id" do
    get "/milo/resources/posts/#{@post.id}"

    assert_response :success
    assert_includes response.body, @post.title
  end
end
