require "test_helper"

class SolidCableSchemaTest < ActiveSupport::TestCase
  test "solid_cable_messages table exists with the columns Solid Cable writes" do
    connection = ActiveRecord::Base.connection

    assert connection.table_exists?("solid_cable_messages"),
      "Action Cable (solid_cable) needs the solid_cable_messages table"

    columns = connection.columns("solid_cable_messages").map(&:name)
    assert_equal %w[id channel payload created_at channel_hash].sort, columns.sort

    indexes = connection.indexes("solid_cable_messages").map(&:columns)
    assert_includes indexes, [ "channel_hash" ]
    assert_includes indexes, [ "created_at" ]
  end
end
