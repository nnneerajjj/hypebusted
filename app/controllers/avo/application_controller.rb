# Replaces Avo's ApplicationController. Every Avo controller (resources, status page,
# private pages) inherits from this, so the login and super-admin checks cover all of them.
class Avo::ApplicationController < Avo::BaseApplicationController
  include Authentication

  prepend_before_action :require_authentication
  before_action :require_super_admin

  delegate :new_session_path, to: :main_app

  private
    def require_super_admin
      redirect_to main_app.root_path unless Current.user&.super_admin?
    end
end
