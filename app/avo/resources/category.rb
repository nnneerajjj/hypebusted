class Avo::Resources::Category < Avo::BaseResource
  self.icon = "tabler/outline/folder"
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
    field :name, as: :text
    field :slug, as: :text
    field :description, as: :textarea
    field :meta_title, as: :text
    field :meta_description, as: :textarea
    field :posts, as: :has_many
  end
end
