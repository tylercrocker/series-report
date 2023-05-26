class CreateCollections < ActiveRecord::Migration[7.0]
  def change
    create_table :collections do |t|
      t.string :type, null: false
      t.string :slug, null: false
      t.string :title, null: false

      t.text :description

      t.timestamps
    end

    add_index :collections, [:type, :slug], unique: true, name: 'collections_unique_constraint'

    create_table :collection_items do |t|
      t.references :collection, foreign_key: { on_delete: :restrict }, index: false, null: false
      t.string :collection_itemable_type, null: false
      t.bigint :collection_itemable_id, null: false

      # I SHOULD be able to use precision: 5, scale: 2 for the following:
      # Covers general partial positions like 1.5 for a novella between books 1 and 2
      # Covers odd partial positions like Scalzi's `The Human Division` that was originally published in 14 parts as #5.01-#5.14
      # I currently can't think of a reason to go past two decimals,
      # => why would you need more than 100 parts of a book?
      # => Pirateaba's `The Wandering Inn` is technically published chapter by chapter on their website but the books themselves are published as books
      # Covers extremely large values just in case (custom lists?) up to 999.99
      # => this effectively gives someone 99,999 entries if they wanted to increment by 100ths
      # => values past 1,000 (or 100,000 in the latter case) just seem rediculous and I can't think of a real world example
      # Technically One Piece has over 1,000 episodes; maybe once I get to TV shows I'll have to consider increasing this?
      # I'm going to use precision: 6, scale: 3 just for the sake of future proofing and will address it again when I get to adding more involved media types
      t.decimal :position, precision: 6, scale: 3

      # These would always have a null position and would be sorted after books with normal positions
      # This is intended for things like omnibuses and published volumes
      # This also handles "Parts" for multiple books that share the same position.
      t.string :position_extra

      t.timestamps
    end

    add_index :collection_items, [:collection_id, :collection_itemable_type, :collection_itemable_id], unique: true, name: 'collection_items_unique_constraint'
    add_index :collection_items, [:collection_itemable_type, :collection_itemable_id], name: 'reverse_index'
  end
end
