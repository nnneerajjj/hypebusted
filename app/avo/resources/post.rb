class Avo::Resources::Post < Avo::BaseResource
  self.icon = "tabler/outline/ballpen"
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
