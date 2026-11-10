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
  before_save :apply_tag_ids, if: -> { !@tag_ids_input.nil? }

  # Tag ids from the Avo multi-select (submitted as strings). nil means the field was not submitted.
  def tag_ids_input=(values)
    @tag_ids_input = values.nil? ? nil : Array(values).map(&:to_s).grep(/\A\d+\z/).map(&:to_i).uniq
  end

  # Submitted ids as strings when set, otherwise the stored tag ids.
  def tag_ids_input
    (@tag_ids_input.nil? ? tag_ids : @tag_ids_input).map(&:to_s)
  end

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

  # Runs in the save transaction, so a failed validation leaves taggings untouched.
  def apply_tag_ids
    self.tags = ::Tag.where(id: @tag_ids_input)
  end

  def seo_description
    content.to_plain_text.squish.truncate(155)
  end

  def cover_image
    content.embeds.find(&:image?)
  end
end
