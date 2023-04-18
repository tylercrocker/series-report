class Collection::Series < Collection

  def merge! series, contributions:
    destroyables = []

    # Update all contribution records to point to the new series
    # These need to be done one by one cause I have to check their 
    series.contributions.preload(:person).each do |contribution|
      begin
        contribution.contributable_id = self.id
        contribution.type = contributions[contribution.person.slug]
        contribution.save!
      rescue ActiveRecord::RecordNotUnique
        # TODO : should I try to update the contribution on the existing record?
        destroyables << contribution
      end
    end
    
    # Update all contained relations to point to the new series
    unless series.id == self.id
      series.contained_relations.each do |relation|
        begin
          relation.collection_id = self.id
          relation.save!
        rescue ActiveRecord::RecordNotUnique
          destroyables << relation
        end
      end
    end

    # TODO : should I merge parent associations as well?
    # Maybe I need another bit of information in the UI first...

    # Cleanup the old data afterward :)
    destroyables.map(&:destroy)
    series.reload.destroy! unless series.id == self.id
  end

end
