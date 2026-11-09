require "test_helper"

class AvoAccessTest < ActionDispatch::IntegrationTest
  ADMIN_PATH = "/milo".freeze

  setup do
    @super_admin = users(:one)
    @regular = users(:two)
  end

  test "logged out visitor is sent to login" do
    get ADMIN_PATH
    assert_redirected_to "/session/new"
  end

  test "logged out visitor cannot reach the status page" do
    get "#{ADMIN_PATH}/avo_private/status"
    assert_redirected_to "/session/new"
  end

  test "logged in user without super_admin is sent to the site root" do
    sign_in_as(@regular)

    get ADMIN_PATH
    assert_redirected_to "/"
  end

  test "super admin can open the admin" do
    sign_in_as(@super_admin)

    get ADMIN_PATH
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "admin panel loads without errors for a super admin" do
    sign_in_as(@super_admin)

    get ADMIN_PATH
    follow_redirect! while response.redirect?

    assert_response :success
    assert_no_match(/Something went wrong|Error|exception/i, response.body)
  end

  test "super admin can open the status page" do
    sign_in_as(@super_admin)

    get "#{ADMIN_PATH}/avo_private/status"
    assert_response :success
  end

  test "regular user cannot open the status page" do
    sign_in_as(@regular)

    get "#{ADMIN_PATH}/avo_private/status"
    assert_redirected_to "/"
  end

  test "post content uses the rich text (Trix) editor in the admin" do
    sign_in_as(@super_admin)

    get "#{ADMIN_PATH}/resources/posts/#{posts(:one).id}/edit"
    follow_redirect! while response.redirect?

    assert_response :success
    assert_select "trix-editor"
  end

  test "old /avo path is gone" do
    sign_in_as(@super_admin)

    get "/avo"
    assert_response :not_found
  end
end
