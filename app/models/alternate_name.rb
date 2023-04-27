class AlternateName < ApplicationRecord
  belongs_to :nameable, polymorphic: true

  def editable_json
    {
      name: {
        editable: true,
        type: 'string',
        value: self.name
      },
      language: {
        editable: true,
        type: 'string',
        value: self.language
      },
      last_updated: {
        editable: false,
        type: 'timestamp',
        value: self.updated_at
      }
    }
  end
end
