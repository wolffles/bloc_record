require 'sqlite3'
require 'pg'
require 'bloc_record/schema'

module Persistence
  def self.include(base)
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end

  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map{|col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}"}.join(",")

    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL

    true
  end

   def self.included(base)
     base.extend(ClassMethods)
   end

   def update_attribute(attribute, value)
     self.class.update(self.id, {attribute => value})
   end

   def update_attributes(updates)
     self.class.update(self.id, updates)
   end

   def destroy
     self.class.destroy(self.id)
   end

   module ClassMethods
     def method_missing(method_name, *args, &block)
       if method_name.to_s =~ /^update_(.+)$/
         update($1.to_sym, args.join)
       else
         super(method_name, *args, &block)
       end
     end

     def self.respond_to?(method_sym, include_private = false)
      if method_sym.to_s =~ /^update_(.+)$/
        true
      else
        super
      end
    end

     def create(attrs)
       attrs = BlocRecord::Utility.convert_keys(attrs)
       attrs.delete "id"
       vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

       connection.execute <<-SQL
         INSERT INTO #{table} (#{attributes.join ","})
         VALUES (#{vals.join ","});
       SQL

       data = Hash[attributes.zip attrs.values]
       data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
       new(data)
     end

     def update_each(ids, updates)
       updates = BlocRecord::Utility.convert_keys(updates)
       updates.delete "id"
       updates_array = updates.map{|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}

      if ids.class == Fixnum
        where_clause = "WHERE id = #{ids};"
      elsif ids.class == Array
        where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
      else
        where_clause = ";"
      end

      connection.execute <<-SQL
        UPDATE #{table}
        SET #{updates_array + ","} #{where_clause}
      SQL

      true
    end

    def update(ids, updates)
      if updates.is_a? Array
        count = 0
        while count < ids.length
          each_update(ids[count], updates[count])
          count += 1
        end
      else
        each_update(ids, updates)
      end
    end

    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end

      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL

      true
    end

    def destroy_all(conditions)
      case conditions
      when Array
        conditions = conditions.join(" AND ")
        connection.execute <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      when Hash
        if conditions_hash && !conditions_hash.empty?
          conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
          conditions = conditions_hash.map {|key,value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")

          connection.execute <<-SQL
            DELETE FROM #{table}
            WHERE #{conditions};
          SQL
        else
          connection.execute <<-SQL
            DELETE FROM #{table}
          SQL
        end
      when String
        connection.execute <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      end

      true
    end
  end
end
