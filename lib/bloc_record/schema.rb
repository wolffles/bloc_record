require 'sqlite3'
require 'bloc_record/utility'

module Schema
  def table
    BlocRecord::Utility.underscore(name)
  end

  def schema
    unless @schema
      @schema = {}
      connection.table_info(table) do |col|
        @schema[col["name"]] = col["type"]
      end
    end
    @schema
  end

  def columns
    schema.keys
  end

  def attributes
    columns - ["id"]
  end

  def count
    # this code uses `<<-`, a Ruby heredoc operator we define SQL as a terminator.
    # execute is a SQLite3::Database instance method. it takes a SQL statement  and returns an array of rows, each of which contain an array of columns. [0][0] extracts the first column of the first row which will contain the count
    connection.execute(<<-SQL)[0][0]
      SELECT COUNT(*) FROM #{table}
    SQL
  end
end
