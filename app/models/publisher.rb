class Publisher < ApplicationRecord
  has_many :publisher_isbn_registrations, dependent: :destroy
  has_many :publishable_publishers, dependent: :destroy
end
