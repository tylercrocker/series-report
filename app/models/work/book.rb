class Work::Book < Work
  has_many :editions, class_name: 'Edition::Book', foreign_key: :work_id

  scope :joins_authors, ->() do
    joins(:people).where(contributions: { type: Contribution::AUTHOR_CLASSES.map(&:name) })
  end

  def self.sort_scope(scope, sort:, direction:)
    case sort
    when 'author'
      scope.joins_authors.order(Arel.sql("people.name #{direction}"))
    else
      super
    end
  end
end
