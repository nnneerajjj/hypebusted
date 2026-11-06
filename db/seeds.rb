# seeds.rb

# Create tags
tags = [
  { name: 'CRM', slug: 'crm' },
  { name: 'AI', slug: 'ai' },
  { name: 'Machine Learning', slug: 'machine-learning' },
  { name: 'VS Code', slug: 'vs-code' },
  { name: 'Extensions', slug: 'extensions' },
  { name: 'Tech Stack', slug: 'tech-stack' },
  { name: 'Setup', slug: 'setup' },
  { name: 'Reviews', slug: 'reviews' }
]

tags.each do |tag|
  Tag.find_or_create_by!(name: tag[:name]) do |t|
    t.slug = tag[:slug]
  end
end

# Create users
users = [
  { email: 'admin@example.com', password: 'securepassword123' },
  { email: 'editor@example.com', password: 'editorpassword456' },
  { email: 'author@example.com', password: 'authorpassword789' }
]

users.each do |user|
  User.find_or_create_by!(email_address: user[:email]) do |u|
    u.password_digest = BCrypt::Password.create(user[:password])
  end
end

# Create posts
posts = [
  {
    title: 'Top CRM Tools for Small Businesses',
    slug: 'top-crm-tools-for-small-businesses',
    content: 'When choosing a CRM tool for your small business, consider factors like ease of use, pricing, and integration capabilities...',
    post_type: 'review',
    published_at: Time.now,
    tag_names: [ 'CRM', 'Reviews' ]
  },
  {
    title: 'Best AI Tools for Content Creation',
    slug: 'best-ai-tools-for-content-creation',
    content: 'Artificial Intelligence is revolutionizing content creation with tools that can generate text, images, and even videos...',
    post_type: 'review',
    published_at: Time.now,
    tag_names: [ 'AI', 'Machine Learning', 'Reviews' ]
  },
  {
    title: 'Essential VS Code Extensions for Developers',
    slug: 'essential-vs-code-extensions-for-developers',
    content: 'Visual Studio Code has become a popular choice among developers due to its extensibility...',
    post_type: 'journal',
    published_at: Time.now,
    tag_names: [ 'VS Code', 'Extensions' ]
  },
  {
    title: 'Recommended Tech Stack for Startups',
    slug: 'recommended-tech-stack-for-startups',
    content: 'Choosing the right technology stack is crucial for the success of a startup...',
    post_type: 'comparison',
    published_at: Time.now,
    tag_names: [ 'Tech Stack', 'Reviews' ]
  },
  {
    title: 'Daily Tech Findings: October 1, 2023',
    slug: 'daily-tech-findings-october-1-2023',
    content: 'Today, we discovered a new AI tool that can generate realistic images from text descriptions...',
    post_type: 'journal',
    published_at: Time.now,
    tag_names: [ 'Setup', 'Reviews' ]
  }
]

posts.each do |post|
  tags = post[:tag_names].map { |name| Tag.find_by(name: name) }

  Post.find_or_create_by!(title: post[:title]) do |p|
    p.slug = post[:slug]
    p.content = post[:content]
    p.post_type = post[:post_type]
    p.published_at = post[:published_at]
    p.tags = tags
  end
end

# Create sessions
users.each do |user|
  user_record = User.find_by(email_address: user[:email])
  Session.find_or_create_by!(user_id: user_record.id, ip_address: '127.0.0.1') do |s|
    s.user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36'
  end
end
