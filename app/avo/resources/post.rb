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
    field :content, as: :textarea
    field :post_type, as: :select, enum: ::Post.post_types
    field :youtube_video_id, as: :text
    field :published_at, as: :date_time
    field :meta_title, as: :text
    field :meta_description, as: :textarea
    field :rating, as: :number
    field :slug, as: :text
    field :category_id, as: :number
    field :category, as: :belongs_to
  end
end
