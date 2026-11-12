# Create or remove the temporary preview post used by preview_article.sh (development database only).
#   bin/rails runner preview_post.rb create ARTICLE.html
#   bin/rails runner preview_post.rb destroy
abort "refusing to run outside development" unless Rails.env.development?
SLUG = "tmp-article-preview".freeze
mode, path = ARGV
Post.where(slug: SLUG).destroy_all
if mode == "create"
  html = File.read(path).gsub("[[IMAGE]]", "")
  Post.create!(title: "Preview: article under review", slug: SLUG, post_type: :comparison,
    published_at: 1.hour.ago, content: html)
  puts "preview post created"
else
  puts "preview post removed (#{Post.where(slug: SLUG).count} left)"
end
