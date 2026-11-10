require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  CRM_REVIEW_SLUGS = %w[
    twenty-crm-review
    suitecrm-review
    espocrm-review
    frappe-crm-review
    krayin-crm-review
  ].freeze

  SEEDED_SLUGS = (CRM_REVIEW_SLUGS + %w[
    open-source-crm-comparison
    best-ai-tools-for-content-creation
    recommended-tech-stack-for-startups
    essential-vs-code-extensions-for-developers
    daily-log-moving-docker-builds-to-github-actions
    daily-log-locking-down-the-deploy-user
    daily-log-a-week-of-ai-pair-programming
    daily-log-crm-demo-day
    self-hosting-twenty-with-docker-compose
    monica-personal-crm-review
  ]).freeze

  setup do
    load Rails.root.join("db/seeds.rb")
  end

  def with_env(key, value)
    original = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = original
  end

  def html_of(post)
    Nokogiri::HTML5.fragment(post.content.body.to_html)
  end

  test "seeds create every expected post" do
    assert_equal SEEDED_SLUGS.sort, Post.where(slug: SEEDED_SLUGS).pluck(:slug).sort
  end

  test "the CRM comparison links to each of the five CRM reviews" do
    comparison = Post.find_by!(slug: "open-source-crm-comparison")
    assert_predicate comparison, :comparison_post_type?

    hrefs = html_of(comparison).css("a").map { |link| link["href"] }
    CRM_REVIEW_SLUGS.each do |slug|
      assert_includes hrefs, Rails.application.routes.url_helpers.post_path(slug)
      assert_predicate Post.find_by!(slug: slug), :review_post_type?
    end
  end

  test "each seeded post has a heading, a bullet list, an image, a YouTube ID and tags" do
    SEEDED_SLUGS.each do |slug|
      post = Post.find_by!(slug: slug)
      fragment = html_of(post)

      assert fragment.at_css("h2"), "#{slug} needs an h2 heading"
      assert fragment.at_css("ul li"), "#{slug} needs a bullet list"
      assert post.cover_image, "#{slug} needs an embedded image"
      assert_match Post::YOUTUBE_ID_FORMAT, post.youtube_video_id.to_s, "#{slug} needs a valid YouTube ID"
      assert_predicate post.tags, :any?, "#{slug} needs at least one tag"
    end
  end

  test "seeded posts have one or two scheduled posts in the future and the rest in the past" do
    posts = Post.where(slug: SEEDED_SLUGS)
    future_count = posts.where("published_at > ?", Time.current).count

    assert_includes 1..2, future_count
    assert_operator posts.where("published_at <= ?", Time.current).count, :>=, 10
  end

  test "seeds stop with a clear message when the seed image is missing" do
    missing = Rails.root.join("db/seeds/assets/does-not-exist.jpg").to_s

    error = assert_raises(RuntimeError) do
      with_env("SEED_IMAGE_PATH", missing) { load Rails.root.join("db/seeds.rb") }
    end

    assert_includes error.message, missing
    assert_match(/create/i, error.message)
  end

  test "running the seeds again does not duplicate posts or tags" do
    assert_no_difference([ "Post.count", "Tag.count" ]) do
      load Rails.root.join("db/seeds.rb")
    end
  end
end
