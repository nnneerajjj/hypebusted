require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  test "duplicate post and tag pair is a validation error, not a DB error" do
    tagging = Tagging.new(post: posts(:one), tag: tags(:one))

    assert_not tagging.valid?
    assert_includes tagging.errors[:tag_id], "has already been taken"
    assert_nothing_raised { assert_not tagging.save }
  end

  test "same tag on a different post is valid" do
    assert Tagging.new(post: posts(:three), tag: tags(:one)).valid?
  end
end
