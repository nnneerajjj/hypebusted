class HomeController < ApplicationController
  def index
    published = Post.published.newest_first.includes(:tags)

    @comparisons = published.comparison_post_type.limit(4).to_a
    @reviews = published.review_post_type.limit(6).to_a
    @journal = published.journal_post_type.limit(10).to_a

    expires_in 5.minutes, public: true
    fresh_when etag: [ @comparisons, @reviews, @journal ], public: true
  end
end
