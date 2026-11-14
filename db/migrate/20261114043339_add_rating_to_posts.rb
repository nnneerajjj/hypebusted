class AddRatingToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :rating, :decimal, precision: 2, scale: 1
    add_column :posts, :reviewed_item_name, :string
  end
end
