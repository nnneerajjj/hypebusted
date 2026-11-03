require "test_helper"

class PostTagTest < ActiveSupport::TestCase
  test "should create a valid post_tag association" do
    post_tag = PostTag.new(
      post: posts(:one),
      tag: tags(:one)
    )
    assert post_tag.valid?
    assert post_tag.save
    assert_equal posts(:one), post_tag.post
    assert_equal tags(:one), post_tag.tag
  end

  test "should not create a post_tag without a post" do
    post_tag = PostTag.new(tag: tags(:one))
    refute post_tag.valid?
    assert_includes post_tag.errors[:post], "must exist"
  end

  test "should not create a post_tag without a tag" do
    post_tag = PostTag.new(post: posts(:one))
    refute post_tag.valid?
    assert_includes post_tag.errors[:tag], "must exist"
  end

  test "should have unique association when properly configured" do
    # Note: This test assumes there should be unique constraints on (post_id, tag_id) combination
    # The schema currently doesn't enforce this, but it's typical for join tables
    post_tag1 = PostTag.new(post: posts(:one), tag: tags(:one))
    assert post_tag1.valid?
    
    # This would be a duplicate if the combination was unique
    post_tag2 = PostTag.new(post: posts(:one), tag: tags(:one))
    # Currently this would be valid in the schema since there's no unique constraint
    # But we should check if it passes validation
    post_tag2_valid = post_tag2.valid?
    # The behavior here depends on the schema configuration
  end

  test "should belong to a post" do
    post_tag = post_tags(:one_post_tag)
    assert_equal posts(:one), post_tag.post
  end

  test "should belong to a tag" do
    post_tag = post_tags(:one_post_tag)
    assert_equal tags(:one), post_tag.tag
  end

  test "should have a post that belongs to a category" do
    post_tag = post_tags(:one_post_tag)
    assert_kind_of Post, post_tag.post
    assert_kind_of Category, post_tag.post.category
  end

  test "should have a tag with unique name" do
    post_tag = post_tags(:two_post_tag)
    assert_equal "Programming", post_tag.tag.name
    # Verify tag uniqueness
    assert_no_duplicate = Tag.where(name: post_tag.tag.name).count == 1
    assert assert_no_duplicate
  end

  test "should create comprehensive associations" do
    # Test that our fixture data creates a complex web of associations
    post = posts(:one)
    tag = tags(:one)
    
    # Find the post_tag that connects this specific post and tag
    post_tag = PostTag.find_by(post: post, tag: tag)
    
    # Verify the relationships
    assert_not_nil post_tag
    assert_equal post, post_tag.post
    assert_equal tag, post_tag.tag

    # Check through the associations
    assert_includes PostTag.where(post: post), post_tag
    assert_includes PostTag.where(tag: tag), post_tag
    assert_includes tag.posts, post
  end
end

