class MovePostContentToActionText < ActiveRecord::Migration[8.1]
  # Copies posts.content into action_text_rich_texts (name: "content"), then drops the column.
  # Plain-text bodies are wrapped one <div> per line, the same shape Trix produces.
  def up
    select_all("SELECT id, content FROM posts WHERE content IS NOT NULL").each do |row|
      body = row["content"].to_s
      body = body.split(/\r?\n/).map { |line| "<div>#{ERB::Util.html_escape(line)}</div>" }.join unless body.include?("<")

      execute <<~SQL
        INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
        VALUES (
          'content',
          #{connection.quote(body)},
          'Post',
          #{connection.quote(row["id"])},
          NOW(),
          NOW()
        )
      SQL
    end

    remove_column :posts, :content
  end

  def down
    add_column :posts, :content, :text

    execute <<~SQL
      UPDATE posts
      SET content = (
        SELECT body FROM action_text_rich_texts
        WHERE action_text_rich_texts.record_type = 'Post'
          AND action_text_rich_texts.record_id = posts.id
          AND action_text_rich_texts.name = 'content'
      )
    SQL

    execute "DELETE FROM action_text_rich_texts WHERE record_type = 'Post' AND name = 'content'"
  end
end
