class ApplicationController < ActionController::Base
  include Authentication
  helper_method :super_admin_signed_in?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    # Public pages are cached by shared caches for 5 minutes. A super admin's page
    # shows the admin link, so it must never be stored ("private, no-store", no ETag).
    def cache_publicly(object = nil, **options)
      if super_admin_signed_in?
        no_store
        response.cache_control[:private] = true
        return
      end

      expires_in 5.minutes, public: true
      fresh_when object, **options, public: true
    end
end
