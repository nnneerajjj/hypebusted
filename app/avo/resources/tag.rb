class Avo::Resources::Tag < Avo::BaseResource
  self.icon = "tabler/outline/tag"

  def fields
    field :id, as: :id
    field :name, as: :text
    field :slug, as: :text
    field :posts, as: :has_many, through: :post_tags
  end
end
