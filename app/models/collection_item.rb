class CollectionItem < ApplicationRecord
  belongs_to :collection
  belongs_to :collection_itemable, polymorphic: true

  def item
    collection_itemable
  end
end
