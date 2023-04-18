module Sluggable
  extend ActiveSupport::Concern

  SLUGGABLE_BY = []

  included do
    before_save :set_slug
  end

  def set_slug
    return unless self.slug.nil?

    slug_to_try = []
    self.class::SLUGGABLE_FIELDS.each do |field|
      slug_to_try << self.send(field)
    end
    binding.pry if slug_to_try.compact.blank?
    slug_to_try = slug_to_try.compact.join('_').gsub(/\_+/, '_')
    return if slug_to_try.blank? || slug_to_try == '_' # Don't allow effectively empty slugs

    slug_to_try = slug_to_try.parameterize

    # Check for existing slugs and increment if necessary
    existing_slug = self.class
    self.class::SLUGGABLE_BY.each do |sluggable_field_scope|
      existing_slug = existing_slug.where(sluggable_field_scope => self.send(sluggable_field_scope))
    end
    existing_slug = existing_slug.where('slug ~ ?', "^#{slug_to_try}(-\\d+)?$").order('LENGTH(slug) DESC', slug: :desc).limit(1).pluck(:slug).first
    if existing_slug.nil?
      self.slug = slug_to_try
      return
    elsif existing_slug == slug_to_try
      self.slug = "#{slug_to_try}-1"
      return
    end

    num = existing_slug.sub(/#{slug_to_try}-/, '').to_i
    self.slug = "#{slug_to_try}-#{num + 1}"
  end
end