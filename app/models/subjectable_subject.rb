class SubjectableSubject < ApplicationRecord
  belongs_to :subject
  belongs_to :subjectable, polymorphic: true
end
