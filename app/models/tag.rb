class Tag < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  has_many :taggings, dependent: :destroy
  has_many :posts, through: :taggings

  before_validation :generate_slug

  def generate_slug
    if name.present? && slug.blank?
      self.slug = name.to_s.parameterize
    end
  end
end
