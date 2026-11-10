class PostsController < ApplicationController
  def show
    @post = Post.published.includes(:tags, rich_text_content: { embeds_attachments: :blob }).find_by!(slug: params[:slug])
    expires_in 5.minutes, public: true
    fresh_when @post, public: true
  end
end
