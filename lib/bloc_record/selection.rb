require 'sqlite3'

module Selection
  def method_missing(method_name, *args, &block)
    if method_name.to_s =~ /^find_by_(.+)$/
      find_by($1.to_sym, args.join)
    else
      super(method_name, *args, &block)
    end
  end

  def self.respond_to?(method_sym, include_private = false)
   if method_sym.to_s =~ /^find_by_(.+)$/
     true
   else
     super
   end
 end

 def find_each(options)
   rows = connection.execute <<-SQL
     SELECT #{columns.join(",")} FROM #{table}
     LIMIT #{options[:batch_size]} OFFSET #{options[:start]}
   SQL

   for row in rows_to_array(rows)
     yield row
   end
 end

 def find_in_batches(options)
   rows = connection.execute <<-SQL
     SELECT #{columns.join(",")} FROM #{table}
     LIMIT #{options[:batch_size]} OFFSET #{options[:start]}
   SQL

  yield rows_to_array(rows)
 end

  def find(*ids)
    if ids.length == 1
      find_one(id.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    row = connection.get_first_row <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
      input_validation(value, attribute)
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
      SQL

      rows_to_array(rows)
    end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT *
      FROM table
      WHERE id IN (SELECT id
        FROM table
        ORDER BY RANDOM()
        LIMIT x
      )
    SQL
    # SQL engines first load projected fields of rows to memory then sort them, here we just do a random sort on id field of each row which is in memory because it's indexed, then separate X of them, and find the whole row using these X ids. consumes less ram and cpu
    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  private
  def input_validation(input,type)
    case type
    when 'string'
      input.class == String ? true : (raise ArgumentError, "input is a #{input.class} must be a String")
    when 'integer'
      input.class.superclass == Integer  ? true : (raise ArgumentError, "input is a #{input.class} must be an Integer.")
    when 'id'
      (input.class.superclass == Integer && input >= 0)  ? true : (raise ArgumentError, "input is not a valid id format.")
    when 'name'
      (input.class == String && !input.match(/[^a-zA-Z|' ']/)) ? true : (raise ArgumentError, "input must only be letters and spaces")
    when 'natural numbers'
      (input.class.superclass == Integer && input >= 0)  ? true : (raise ArgumentError, "input must be natural numbers 0,1,2,3...")
    when 'numeric'
      input.class.superclass == Numeric ? true : (raise AugumentError, "input must be a float/ decimal format")
    else
      puts  "not a recorded type"
      false
    end
  end

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
     rows.map { |row| new(Hash[columns.zip(row)]) }
  end
end
