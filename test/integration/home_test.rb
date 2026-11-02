require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "root renders the starter landing page" do
    get root_url

    assert_response :success
    assert_select "h1", "A solid start.Room to build."
    assert_select "a[href='/up']", "App status ↗"
    assert_select "section#stack"
  end
end
