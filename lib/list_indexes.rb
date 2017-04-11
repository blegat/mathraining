ActiveRecord::Base.connection.tables.each do |t|
  puts ActiveRecord::Base.connection.indexes(t).inspect
end
