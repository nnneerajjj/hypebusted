class SitemapsController < ApplicationController
  def show
    expires_in 1.hour, public: true
    @posts = Post.published.newest_first
  end
end
