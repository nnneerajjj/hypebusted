class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    published = Post.published.newest_first.includes(:tags)

    @comparisons = published.comparison_post_type.limit(4).to_a
    @reviews = published.review_post_type.limit(6).to_a
    @journal = published.journal_post_type.limit(10).to_a

    cache_publicly etag: [ @comparisons, @reviews, @journal ]
  end
end
