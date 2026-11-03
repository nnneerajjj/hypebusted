class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :content
      t.string :post_type
      t.string :youtube_video_id
      t.datetime :published_at
      t.string :meta_title
      t.text :meta_description
      t.integer :rating

      t.timestamps
    end
  end
end
