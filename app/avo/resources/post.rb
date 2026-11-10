class Avo::Resources::Post < Avo::BaseResource
  self.icon = "tabler/outline/ballpen"

  # Post URLs use the slug (Post#to_param), so Avo must look records up by slug.
  # Falls back to id so older links and Avo's own id-based lookups keep working.
  self.find_record_method = -> {
    if id.is_a?(Array)
      query.where(slug: id)
    else
      query.find_by(slug: id.to_s) || query.find(id)
    end
  }
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :title, as: :text
    field :content, as: :trix
    field :post_type, as: :select, enum: ::Post.post_types
    field :youtube_video_id, as: :text
    field :published_at, as: :date_time
    field :slug, as: :text
  end
end
