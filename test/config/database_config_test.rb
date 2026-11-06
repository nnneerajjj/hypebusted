require "test_helper"

class DatabaseConfigTest < ActiveSupport::TestCase
  test "production primary database does not seed on db:prepare" do
    config = ActiveRecord::Base.configurations.configs_for(env_name: "production", name: "primary")

    assert_not config.seeds?, "db:prepare would load db/seeds.rb (with public passwords) into production"
  end
end
