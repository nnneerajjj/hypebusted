require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "root renders the default Rails welcome page" do
    get root_url

    assert_response :success
    assert_select "title", "Ruby on Rails #{Rails.version}"
  end
end
