module AlternateNameable
  extend ActiveSupport::Concern

  DEFAULT_LANGUAGE = 'English'.freeze

  included do
    has_many :alternate_names, as: :nameable, dependent: :destroy
  end

  def custom_edit_alternate_names data
    data.each do |key, value|
      if key.start_with?('new_')
        # TODO : handle existing, same-named items
        self.alternate_names.create!(name: value.dig('name', 'to'), language: value.dig('language', 'to') || DEFAULT_LANGUAGE)
        next
      end

      existing = self.alternate_names.where(id: key).first
      next if existing.nil?

      value.each do |field, from_to|
        # TODO : handle cases where the name was changed by another request
        existing.send("#{field}=", from_to['to'])
      end
      existing.save!
    end
  end
end