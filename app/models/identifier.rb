class Identifier < ApplicationRecord
  belongs_to :identifiable, polymorphic: true

  class InvalidIdentifierError < StandardError; end

  def self.invalid_identifier? identifiable, new_id
    new_id.blank?
  end
end
