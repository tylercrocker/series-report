class AlternateName < ApplicationRecord
  belongs_to :nameable, polymorphic: true

  def editable_json
    {
      key: {
        editable: false,
        type: 'key',
        value: self.id
      },
      name: {
        editable: true,
        type: 'string',
        value: self.name,
        placeholder: 'Bruce Wayne',
        required: true
      },
      language: {
        editable: true,
        type: 'string',
        value: self.language,
        placeholder: 'English (default)',
        required: false
      },
      last_updated: {
        editable: false,
        type: 'timestamp',
        value: self.updated_at
      }
    }
  end
end
