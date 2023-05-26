module Sluggable
  extend ActiveSupport::Concern

  class MissingSlugDataError < StandardError;end
  class FailedSlugIncrementationError < StandardError;end

  SLUGGABLE_BY = [].freeze
  SLUGGABLE_FIELDS = [].freeze

  included do
    before_save :set_slug
  end

  class_methods do
    # The slug finder is pretty good, but it can get stuck with high throughput
    # This just tries to do it a few times, which should alleviate the issue.
    def create_with_slug! **fields
      tries = 3
      begin
        self.create!(fields)
      rescue ActiveRecord::NotNullViolation
        # If the slug ended up being nil then we can just return nil,
        # this is OK and we should be handling it at the place this is being used
        return
      rescue ActiveRecord::RecordNotUnique
        raise FailedSlugIncrementationError, "Failed to increment slug for #{self.class.name} with fields #{fields.inspect}" if tries.zero?

        tries -= 1
        retry
      end
    end
  end

  def set_slug force_update: false
    return unless self.slug.nil? || force_update

    self.slug = nil if force_update

    slug_to_try = []
    self.class::SLUGGABLE_FIELDS.each do |field|
      slug_to_try << self.send(field)
    end

    raise MissingSlugDataError, "No slug data found for #{self.class} record, #{self.class::SLUGGABLE_FIELDS.inspect}" if slug_to_try.compact.blank?

    slug_to_try = slug_to_try.compact.join('_').squeeze('_').gsub(/&#\d+;/, '')
    return if slug_to_try.blank? || slug_to_try == '_' # Don't allow effectively empty slugs


    slug_to_try_parameterized = slug_to_try.parameterize
    slug_to_try = if slug_to_try_parameterized.empty?
      # In this case we had special characters, probably from a non-english language,
      # like "زیبایی های حجاب وسیره حضرت زهرا(س)"
      # Rails' parameterize method just strips these out.
      # Let's do some special stuff for now just so things work,
      # we can analyze what all we need to do to make them URL safe later
      slug_to_try.squeeze(' ').gsub(/[#!@+\^\$\&\(\)\s\_\/\*\?\.\\\[\]]/, '-').squeeze('-').gsub(/^-|-$/, '')
    else
      slug_to_try_parameterized
    end

    return unless slug_to_try.squeeze.length > 1

    # Check for existing slugs and increment if necessary
    existing_slug = self.class
    self.class::SLUGGABLE_BY.each do |sluggable_field_scope|
      existing_slug = existing_slug.where(sluggable_field_scope => self.send(sluggable_field_scope))
    end
    begin
      existing_slug = existing_slug.where('slug ~ ?', "^#{slug_to_try}(-\\d+)?$").order('LENGTH(slug) DESC', slug: :desc).limit(1).pluck(:slug).first
    rescue ActiveRecord::StatementInvalid => e
      return if e.message.start_with?('PG::InvalidRegularExpression')

      raise e
    end

    if existing_slug.nil?
      self.slug = slug_to_try
      return
    elsif existing_slug == slug_to_try
      self.slug = "#{slug_to_try}-1"
      return
    end

    num = existing_slug.sub(/#{slug_to_try}-/, '')

    # rjusting can need to happen when a number is parsed out of existing data.
    # this DOES result a 0 adjusted number pushing the count further
    # I definitely should keep an eye on this happening though, it's usually because of special HTML characters in names.
    # Hopefully instances of this are either stripped out after the fact or I can just ignore them.
    self.slug = "#{slug_to_try}-#{(num.to_i + 1).to_s.rjust(num.length, '0')}"
  end
end
