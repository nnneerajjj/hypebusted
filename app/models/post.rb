class Post < ApplicationRecord
  enum :post_type, { review: 0, comparison: 1, journal: 2 }, suffix: true, validate: true

  has_rich_text :content

  validates :post_type, presence: true
  validates :title, presence: true
  validates :content, presence: true


  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  before_validation :generate_slug

  def generate_slug
    if title.present? && slug.blank?
      self.slug = title.to_s.parameterize
    end
  end
end
