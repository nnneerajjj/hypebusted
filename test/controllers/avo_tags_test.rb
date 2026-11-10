require "test_helper"

class AvoTagsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @tag = tags(:one)
  end

  test "tag posts panel lists the tag's posts through taggings" do
    get "/milo/resources/tags/#{@tag.id}/posts", params: { turbo_frame: "has_many_field_show_posts" }

    assert_response :success
    assert_includes response.body, posts(:one).title
    assert_not_includes response.body, posts(:two).title
  end
end
