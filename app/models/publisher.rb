class Publisher < ApplicationRecord
  has_many :publisher_isbn_registrations, dependent: :destroy
end
