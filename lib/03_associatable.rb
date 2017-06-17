require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name = options[:class_name]
    @primary_key = options[:primary_key]
    @foreign_key = options[:foreign_key]

    #If not supplied in options
    @class_name ||= name.to_s.camelcase.singularize
    @primary_key ||= :id
    @foreign_key ||= "#{name.to_s.underscore}_id".to_sym
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name = options[:class_name]
    @primary_key = options[:primary_key]
    @foreign_key = options[:foreign_key]

    #If not supplied in options
    @class_name ||= name.to_s.camelcase.singularize
    @primary_key ||= :id
    @foreign_key ||= "#{self_class_name.to_s.underscore}_id".to_sym
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      value = self.send(options.foreign_key)
      target_class = options.model_class
      target_class.where(options.primary_key => value).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      value = self.send(options.primary_key)
      target_class = options.model_class
      target_class.where(options.foreign_key => value)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
