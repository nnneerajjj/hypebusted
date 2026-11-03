class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :meta_title
      t.text :meta_description

      t.timestamps
    end
    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true
  end
end
