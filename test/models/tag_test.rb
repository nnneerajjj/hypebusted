require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "should create a valid tag" do
    tag = Tag.new(
      name: "Ruby",
      slug: "ruby"
    )
    assert tag.valid?
    assert tag.save
    assert_equal "Ruby", tag.name
    assert_equal "ruby", tag.slug
  end

  test "should not create a tag without a name" do
    tag = Tag.new(slug: "tech")
    refute tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "should generate a friendly slug" do
    tag = Tag.create!(name: "My Awesome Tag Name")
    assert_equal "my-awesome-tag-name", tag.slug
  end

  test "should validate uniqueness of name" do
    tag1 = Tag.create!(name: "Unique Tag Name", slug: "unique-tag-name")
    
    tag2 = Tag.new(name: "Unique Tag Name", slug: "unique-tag-name-2")
    refute tag2.valid?
    assert_includes tag2.errors[:name], "has already been taken"
  end

  test "should validate uniqueness of slug" do
    tag1 = Tag.create!(name: "Unique Tag 1", slug: "unique-slug")
    
    tag2 = Tag.new(name: "Unique Tag 2", slug: "unique-slug")
    refute tag2.valid?
    assert_includes tag2.errors[:slug], "has already been taken"
  end

  test "should have associated posts through post_tags" do
    # Create a tag and associate it with posts
    tag = Tag.create!(name: "Ruby", slug: "ruby")

    # Create posts and associate them with the tag
    post1 = Post.create!(title: "First Post", content: "Content", post_type: "journal", category: categories(:one))
    post2 = Post.create!(title: "Second Post", content: "Content", post_type: "journal", category: categories(:two))

    # Create post_tags associations
    PostTag.create!(post: post1, tag: tag)
    PostTag.create!(post: post2, tag: tag)

    # Verify the associations
    assert_includes tag.posts, post1
    assert_includes tag.posts, post2
  end

  test "should have post_tags associations" do
    # Create a tag
    tag = Tag.create!(name: "Ruby", slug: "ruby")

    # Create posts and associate them with the tag
    post1 = Post.create!(title: "First Post", content: "Content", post_type: "journal", category: categories(:one))
    post2 = Post.create!(title: "Second Post", content: "Content", post_type: "journal", category: categories(:two))

    # Create post_tags associations
    post_tag1 = PostTag.create!(post: post1, tag: tag)
    post_tag2 = PostTag.create!(post: post2, tag: tag)

    # Verify the associations
    assert_includes tag.post_tags, post_tag1
    assert_includes tag.post_tags, post_tag2
  end
end
