class Avo::Resources::Tagging < Avo::BaseResource
  # self.icon = "tabler/outline/users"

  def fields
    field :id, as: :id
    field :post, as: :belongs_to
    field :tag, as: :belongs_to
  end
end
