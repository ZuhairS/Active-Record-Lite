require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    col = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @columns = col.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) { self.attributes[column] }
      define_method("#{column}=") { |value| self.attributes[column] = value }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    table_name = self.table_name
    results = DBConnection.execute(<<-SQL, table_name)
      SELECT *
      FROM #{table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    results.each do |row|
      self.new(row)
    end
  end

  def self.find(id)
    # ...
  end

  def initialize(params = {})
    columns = self.class.columns
    params.each do |attr_name, value|
      name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless columns.include?(name)
      self.send("#{name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # ...
  end

  def insert
    # ...
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
