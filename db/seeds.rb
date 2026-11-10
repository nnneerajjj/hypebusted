# seeds.rb
#
# Safe to run more than once: posts are matched by slug and updated in place.
#
# Article bodies are HTML files in db/seeds/articles/<slug>.html. A line such as
#   {{image: twenty-dashboard | Caption text}}
# is replaced with the shared seed image (db/seeds/assets/seed-image.jpg), stored in
# Active Storage and embedded as an Action Text attachment.

# Create tags
tag_names = [
  "CRM", "Open Source", "Self-Hosted", "Sales Pipeline", "Personal CRM",
  "Docker", "GitHub Actions", "Kamal", "Security",
  "AI", "Content Creation", "Productivity", "Developer Tools",
  "VS Code", "Extensions", "Tech Stack", "Startups"
]

tag_names.each do |name|
  Tag.find_or_create_by!(name: name)
end

# Create users
users = [
  { email: 'admin@example.com', password: 'securepassword123', super_admin: true },
  { email: 'editor@example.com', password: 'editorpassword456' },
  { email: 'author@example.com', password: 'authorpassword789' }
]

users.each do |user|
  User.find_or_create_by!(email_address: user[:email]) do |u|
    u.password_digest = BCrypt::Password.create(user[:password])
    u.super_admin = user[:super_admin] || false
  end
end

# Every article image is the same local file (db/seeds/assets/seed-image.jpg, gitignored).
# Set SEED_IMAGE_PATH to use a different file.
seed_image_path = Pathname.new(ENV.fetch("SEED_IMAGE_PATH") { Rails.root.join("db/seeds/assets/seed-image.jpg").to_s })

unless seed_image_path.file?
  raise <<~MESSAGE
    Seed image not found: #{seed_image_path}
    Create it by copying any free-to-use image (CC0 or public domain, e.g. from wordpress.org/photos)
    to db/seeds/assets/seed-image.jpg, then run the seeds again.
    The file is gitignored, so each machine needs its own copy.
  MESSAGE
end

seed_image_bytes = seed_image_path.binread
seed_image_checksum = Digest::MD5.base64digest(seed_image_bytes)

attach_image = lambda do |caption|
  blob = ActiveStorage::Blob.find_by(filename: "seed-image.jpg", checksum: seed_image_checksum) ||
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new(seed_image_bytes), filename: "seed-image.jpg", content_type: "image/jpeg")
  ActionText::Attachment.from_attachable(blob, caption: caption).to_html
end

article_html = lambda do |attrs|
  path = Rails.root.join("db/seeds/articles", "#{attrs[:slug]}.html")
  File.read(path).gsub(/\{\{image:\s*([\w-]+)\s*\|\s*(.+?)\s*\}\}/) do
    attach_image.(Regexp.last_match(2))
  end
end

# Create posts
posts = [
  # Open source CRM cluster: five reviews, then the comparison that links to them.
  {
    slug: "twenty-crm-review",
    title: "Twenty CRM Review: A Modern Open Source CRM for Developers",
    post_type: "review",
    published_at: "2026-09-02 09:00",
    youtube_video_id: "0yihtp5It6g",
    tag_names: [ "CRM", "Open Source", "Self-Hosted" ]
  },
  {
    slug: "suitecrm-review",
    title: "SuiteCRM Review: Full-Featured Open Source CRM with a Long History",
    post_type: "review",
    published_at: "2026-09-16 09:00",
    youtube_video_id: "yXUT3_Eze3Y",
    tag_names: [ "CRM", "Open Source", "Self-Hosted" ]
  },
  {
    slug: "espocrm-review",
    title: "EspoCRM Review: Lightweight, Customizable and Easy to Self-Host",
    post_type: "review",
    published_at: "2026-09-30 09:00",
    youtube_video_id: "gYP6IoaBQ9k",
    tag_names: [ "CRM", "Open Source", "Self-Hosted" ]
  },
  {
    slug: "frappe-crm-review",
    title: "Frappe CRM Review: A Clean Sales CRM from the Frappe Ecosystem",
    post_type: "review",
    published_at: "2026-10-14 09:00",
    youtube_video_id: "JLk6R3QFCm8",
    tag_names: [ "CRM", "Open Source", "Sales Pipeline" ]
  },
  {
    slug: "krayin-crm-review",
    title: "Krayin CRM Review: A Laravel CRM for Teams That Like to Tinker",
    post_type: "review",
    published_at: "2026-10-28 09:00",
    youtube_video_id: "xcYQmURVAGs",
    tag_names: [ "CRM", "Open Source", "Self-Hosted" ]
  },
  {
    slug: "open-source-crm-comparison",
    title: "Open Source CRM Comparison: Five Self-Hosted Options Tested",
    post_type: "comparison",
    published_at: "2026-11-04 08:00",
    youtube_video_id: "w3X9cJFcNx4",
    tag_names: [ "CRM", "Open Source", "Self-Hosted", "Sales Pipeline" ]
  },
  {
    slug: "monica-personal-crm-review",
    title: "Monica Review: A Personal CRM for Remembering the People You Care About",
    post_type: "review",
    published_at: "2027-01-12 09:00",
    youtube_video_id: "FKFXwvU1cfk",
    tag_names: [ "Personal CRM", "Open Source", "Self-Hosted" ]
  },
  {
    slug: "self-hosting-twenty-with-docker-compose",
    title: "Self-Hosting Twenty with Docker Compose: A Setup Guide",
    post_type: "journal",
    published_at: "2026-11-24 09:00",
    youtube_video_id: "p5k7gBCByi4",
    tag_names: [ "CRM", "Self-Hosted", "Docker", "Open Source" ]
  },

  # Other reviews, comparisons and journal entries.
  {
    slug: "best-ai-tools-for-content-creation",
    title: "Best AI Tools for Content Creation",
    post_type: "review",
    published_at: "2026-06-18 09:00",
    youtube_video_id: "RQrCDM4IZo4",
    tag_names: [ "AI", "Content Creation", "Productivity" ]
  },
  {
    slug: "recommended-tech-stack-for-startups",
    title: "Recommended Tech Stack for Startups in 2026",
    post_type: "comparison",
    published_at: "2026-06-25 09:00",
    youtube_video_id: "gqMzRJKQvuU",
    tag_names: [ "Tech Stack", "Startups", "Developer Tools" ]
  },
  {
    slug: "essential-vs-code-extensions-for-developers",
    title: "Essential VS Code Extensions for Developers",
    post_type: "journal",
    published_at: "2026-07-22 09:00",
    youtube_video_id: "W4Uj1_9RYVw",
    tag_names: [ "VS Code", "Extensions", "Developer Tools" ]
  },
  {
    slug: "daily-log-moving-docker-builds-to-github-actions",
    title: "Daily Log: Moving the Docker Build into GitHub Actions",
    post_type: "journal",
    published_at: "2026-08-12 09:00",
    youtube_video_id: "x7f9x30W_dI",
    tag_names: [ "Docker", "GitHub Actions", "Kamal" ]
  },
  {
    slug: "daily-log-locking-down-the-deploy-user",
    title: "Daily Log: Locking Down the Deploy User",
    post_type: "journal",
    published_at: "2026-08-27 09:00",
    youtube_video_id: "sPUk9-1WVXI",
    tag_names: [ "Kamal", "Security" ]
  },
  {
    slug: "daily-log-a-week-of-ai-pair-programming",
    title: "Daily Log: A Week of AI Pair Programming",
    post_type: "journal",
    published_at: "2026-09-10 09:00",
    youtube_video_id: "MTmhgIVhpag",
    tag_names: [ "AI", "Developer Tools", "Productivity" ]
  },
  {
    slug: "daily-log-crm-demo-day",
    title: "Daily Log: Demo Day for Open Source CRMs",
    post_type: "journal",
    published_at: "2026-10-09 09:00",
    youtube_video_id: "msucdsodPFY",
    tag_names: [ "CRM", "Sales Pipeline", "Open Source" ]
  }
]

posts.each do |attrs|
  post = Post.find_or_initialize_by(slug: attrs[:slug])
  post.assign_attributes(
    title: attrs[:title],
    post_type: attrs[:post_type],
    youtube_video_id: attrs[:youtube_video_id],
    published_at: Time.zone.parse(attrs[:published_at]),
    tags: attrs[:tag_names].map { |name| Tag.find_by!(name: name) }
  )
  post.content = article_html.(attrs)
  post.save!
end

# Create sessions
users.each do |user|
  user_record = User.find_by(email_address: user[:email])
  Session.find_or_create_by!(user_id: user_record.id, ip_address: '127.0.0.1') do |s|
    s.user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36'
  end
end
