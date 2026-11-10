class Avo::Resources::Post < Avo::BaseResource
  self.icon = "tabler/outline/ballpen"

  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  # Wrapper targets Avo's resource-edit controller toggles (`<fieldId><Type>Wrapper`).
  TRIX_WRAPPER_TARGET = "contentTrixWrapper".freeze
  HTML_WRAPPER_TARGET = "contentHtmlTextareaWrapper".freeze
  HTML_EDITOR_ROWS = 100
  HTML_EDITOR_HINT = "Edit the raw HTML of the post body. Saving later from the rich-text editor may strip " \
    "markup Trix doesn't support, and the public page strips unsupported tags and attributes. " \
    "Switching editors does not carry over unsaved changes — save before switching.".freeze

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :title, as: :text
    field :content, as: :trix,
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
          wrapper { classes { "hidden" unless record.html_editor } }
          # Avo's textarea-autogrow sets the height while the field is hidden (0px); min-height keeps it usable.
          input do
            classes "font-mono text-sm"
            style "min-height: #{HTML_EDITOR_ROWS}lh"
          end
        end
      }
    field :post_type, as: :select, enum: ::Post.post_types
    field :youtube_video_id, as: :text
    field :published_at, as: :date_time
    field :slug, as: :text
  end
end
