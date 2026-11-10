class Post < ApplicationRecord
  enum :post_type, { review: 0, comparison: 1, journal: 2 }, suffix: true, validate: true

  has_rich_text :content

  validates :post_type, presence: true
  validates :title, presence: true
  validates :content, presence: true
  validates :slug, presence: true, uniqueness: true

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  scope :published, -> { where(published_at: ..Time.current) }
  scope :newest_first, -> { order(published_at: :desc) }

  before_validation :normalize_slug

  # Uses the admin-entered slug when given, otherwise the title.
  def normalize_slug
    self.slug = (slug.presence || title).to_s.parameterize
  end

  def seo_description
    content.to_plain_text.squish.truncate(155)
  end

  def cover_image
    content.embeds.find(&:image?)
  end

  def to_param
    slug
  end

  def seo_description
    content.to_plain_text.squish.truncate(155)
  end

  def cover_image
    content.embeds.find(&:image?)
  end
end
