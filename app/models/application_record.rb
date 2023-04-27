class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def sti_type
    self.class.name.split('::').last.downcase
  end
end
