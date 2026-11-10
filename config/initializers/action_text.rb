# Keep lazy-loading hints on images rendered by the blob partial (the sanitizer drops them otherwise).
Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_attributes =
    Rails::HTML5::SafeListSanitizer.allowed_attributes + ActionText::Attachment::ATTRIBUTES + %w[loading decoding]
end
