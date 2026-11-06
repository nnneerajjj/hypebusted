require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "super_admin defaults to false" do
    user = User.create!(email_address: "new@example.com", password: "password")
    assert_not user.super_admin?
  end

  test "super_admin cannot be changed after creation" do
    user = users(:two)

    assert_raises(ActiveRecord::ReadonlyAttributeError) { user.update!(super_admin: true) }
    assert_not user.reload.super_admin?
  end

  test "Avo admin role is driven by super_admin" do
    assert_equal :super_admin?, Avo.configuration.is_admin_method
  end
end
