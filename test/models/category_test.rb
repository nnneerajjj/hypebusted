require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "should create a valid category" do
    category = Category.new(
      name: "Technology",
      slug: "technology",
      description: "A technology category",
      meta_title: "Technology Category",
      meta_description: "Description for technology category"
    )
    assert category.valid?
    assert category.save
    assert_equal "Technology", category.name
    assert_equal "technology", category.slug
  end

  test "should not create a category without a name" do
    category = Category.new(slug: "tech", description: "Desc")
    refute category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "should generate a friendly slug" do
    category = Category.create!(name: "My Awesome Category Name")
    assert_equal "my-awesome-category-name", category.slug
  end

  test "should validate uniqueness of name" do
    category1 = Category.create!(name: "Unique Name", slug: "unique-name")
    
    category2 = Category.new(name: "Unique Name", slug: "unique-name-2")
    refute category2.valid?
    assert_includes category2.errors[:name], "has already been taken"
  end

  test "should validate uniqueness of slug" do
    category1 = Category.create!(name: "Unique1", slug: "unique-slug")
    
    category2 = Category.new(name: "Unique2", slug: "unique-slug")
    refute category2.valid?
    assert_includes category2.errors[:slug], "has already been taken"
  end

  test "should have associated posts" do
    category = Category.create!(name: "Technology", slug: "technology", description: "Tech news and updates")
    post1 = Post.create!(title: "First Post", content: "Content", post_type: "journal", category: category)
    post2 = Post.create!(title: "Second Post", content: "Content", post_type: "journal", category: category)
    assert_includes category.posts, post1
    assert_includes category.posts, post2
  end
end
