class AlternateName < ApplicationRecord
  belongs_to :nameable, polymorphic: true
end
