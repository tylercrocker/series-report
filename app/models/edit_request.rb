class EditRequest < ApplicationRecord
  enum :status, [:waiting, :processing, :approved, :denied, :ignored]

  belongs_to :editable, polymorphic: true

  scope :waiting, ->() { where(status: :waiting) }
end