class Tag < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  has_many :taggings, dependent: :destroy
  has_many :posts, through: :taggings

  before_validation :generate_slug

  # Uses the admin-entered slug when given, otherwise the name.
  def generate_slug
    self.slug = (slug.presence || name).to_s.parameterize
  end
end
