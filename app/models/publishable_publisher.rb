class PublishablePublisher < ApplicationRecord
  belongs_to :publisher
  belongs_to :publishable, polymorphic: true
end
