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
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    all_rows = []
    results.each do |row|
      all_rows << self.new(row)
    end
    all_rows
  end

  def self.find(id)
    obj = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{self.table_name}
      WHERE id = ?
      LIMIT 1
    SQL
    self.parse_all(obj).last
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
    self.class.columns.map { |col| self.send(col) }
  end

  def insert
    col_names = self.class.columns
    question_marks = (["?"] * col_names.length).join(", ")
    col_names = col_names.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns
    set_line = col_names.map { |attr_name| "#{attr_name} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
