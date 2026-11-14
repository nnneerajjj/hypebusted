class Avo::Resources::Post < Avo::BaseResource
  self.icon = "tabler/outline/ballpen"

  # Wrapper targets Avo's resource-edit controller toggles (`<fieldId><Type>Wrapper`).
  TRIX_WRAPPER_TARGET = "contentTrixWrapper".freeze
  HTML_WRAPPER_TARGET = "contentHtmlTextareaWrapper".freeze
  HTML_EDITOR_ROWS = 100
  HTML_EDITOR_HINT = "The HTML editor is the default. Untick to use the rich-text editor (Trix), which strips markup; " \
    "see its warning. Switching editors does not carry over unsaved changes; save before switching.".freeze
  TRIX_WARNING = "Saving from the rich-text editor strips h2/h3 headings, CSS classes (e.g. the .compare block) " \
    "and other markup Trix doesn't support. Edit articles in the HTML editor.".freeze
  # Avo's attachments endpoint (the one its Trix uses); the route has no helper. No record id, so it works on new posts.
  IMAGE_UPLOAD_PATH = "#{Avo.configuration.root_path}/avo_api/resources/posts/attachments".freeze

  def fields
    field :id, as: :id
    field :title, as: :text
    field :content, as: :trix, help: TRIX_WARNING,
      html: -> { edit { wrapper { classes { "hidden" if record.html_editor } } } }
    field :html_editor, as: :boolean, only_on: :forms, name: "Edit as HTML", help: HTML_EDITOR_HINT,
      html: -> {
        edit do
          input do
            data action: "change->resource-edit#toggle",
              resource_edit_toggle_targets_param: [ TRIX_WRAPPER_TARGET, HTML_WRAPPER_TARGET ]
          end
        end
      }
    field :content_html, as: :textarea, only_on: :forms, name: "Content (HTML)", rows: HTML_EDITOR_ROWS,
      html: -> {
        edit do
          wrapper do
            classes { "hidden" unless record.html_editor }
            data controller: "html-image-insert", html_image_insert_url_value: IMAGE_UPLOAD_PATH
          end
          # Avo's textarea-autogrow sets the height while the field is hidden (0px); min-height keeps it usable.
          input do
            classes "font-mono text-sm"
            style "min-height: #{HTML_EDITOR_ROWS}lh"
          end
        end
      }
    field :post_type, as: :select, enum: ::Post.post_types
    field :rating, as: :number, min: ::Post::WORST_RATING, max: ::Post::BEST_RATING, step: 0.5
    field :reviewed_item_name, as: :text, name: "Reviewed item",
      help: "Tool name shown to Google, e.g. Cloudflare Registrar. Required when rating is set."
    field :tag_ids_input, as: :select, multiple: true, only_on: :forms, name: "Tags",
      options: -> { ::Tag.order(:name).pluck(:name, :id).to_h }
    field :tags, as: :text, only_on: :show, name: "Tags", format_using: -> { value.map(&:name).join(", ") }
    field :youtube_video_id, as: :text
    field :published_at, as: :date_time
    field :slug, as: :text
  end
end
