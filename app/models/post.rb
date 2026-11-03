class Post < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
  validates :post_type, presence: true

  belongs_to :category, optional: true # Make it optional for now, can be changed later

  enum :post_type, { journal: "journal", review: "review", comparison: "comparison" }

  before_validation :generate_slug

  def generate_slug
    if title.present? && slug.blank?
      self.slug = title.to_s.parameterize
    end
  end
end
