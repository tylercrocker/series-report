class ApiFetch < ApplicationRecord

  enum :status, [:created, :processing, :success, :failure, :success_with_discrepancies]

  belongs_to :fetchable, polymorphic: true
end
