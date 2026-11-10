class Post < ApplicationRecord
  enum :post_type, { review: 0, comparison: 1, journal: 2 }, suffix: true, validate: true

  has_rich_text :content

  # Virtual flag set by the Avo "Edit as HTML" checkbox; not persisted.
  attribute :html_editor, :boolean, default: false

  validates :post_type, presence: true
  validates :title, presence: true
  validates :content, presence: true
  validates :slug, presence: true, uniqueness: true

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  scope :published, -> { where(published_at: ..Time.current) }
  scope :newest_first, -> { order(published_at: :desc) }

  before_validation :normalize_slug
  before_validation :apply_content_html, if: :html_editor

  # Raw body HTML for the Avo HTML textarea: the submitted value if any, else the stored body.
  def content_html
    @content_html.nil? ? content.body&.to_html.to_s : @content_html
  end

  def content_html=(value)
    @content_html = value.to_s.gsub("\r\n", "\n")
  end

  # Uses the admin-entered slug when given, otherwise the title.
  def normalize_slug
    self.slug = (slug.presence || title).to_s.parameterize
  end

  # In HTML mode the raw HTML replaces whatever the rich-text editor submitted.
  def apply_content_html
    self.content = @content_html unless @content_html.nil?
  end

  def seo_description
    content.to_plain_text.squish.truncate(155)
  end

  def cover_image
    content.embeds.find(&:image?)
  end
end
