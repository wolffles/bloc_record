require 'sqlite3'
require 'pg'

 module Connection
   def connection
     if @connection.nil?
      case BlocRecord.dbms
      when :pg
        PG::Database.new(BlocRecord.database_filename)
      when :sqlite3
        SQLite3::Database.new(BlocRecord.database_filename)
      end
    else
      @connection
    end 
   end
end
