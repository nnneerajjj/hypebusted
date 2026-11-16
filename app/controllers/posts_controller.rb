class PostsController < ApplicationController
  allow_unauthenticated_access

  def show
    @post = visible_posts.includes(:tags, rich_text_content: { embeds_attachments: :blob }).find_by!(slug: params[:slug])
    cache_publicly @post
  end
end
