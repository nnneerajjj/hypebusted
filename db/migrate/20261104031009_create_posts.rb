class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :content
      t.integer :post_type, null: false
      t.string :youtube_video_id
      t.datetime :published_at
      t.string :slug

      t.timestamps
    end

    add_index :posts, :post_type
    add_index :posts, :slug, unique: true
  end
end
