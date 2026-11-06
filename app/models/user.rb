class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Set only when the row is created (console or db). Later updates are ignored.
  attr_readonly :super_admin

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
