#!/usr/bin/env ruby
# frozen_string_literal: true

# Database Indexes Analysis Script
# Checks for missing indexes on foreign keys and commonly queried columns

puts 'Database Indexes Analysis:'
puts '=' * 60

# Get all tables except Rails internal ones
tables = ActiveRecord::Base.connection.tables - ['ar_internal_metadata', 'schema_migrations']

missing_indexes = []
existing_indexes_count = 0

tables.sort.each do |table|
  columns = ActiveRecord::Base.connection.columns(table)
  indexes = ActiveRecord::Base.connection.indexes(table)
  indexed_columns = indexes.flat_map { |idx| idx.columns.is_a?(Array) ? idx.columns : [idx.columns] }
  
  existing_indexes_count += indexes.count
  
  # Check for foreign keys without indexes
  columns.each do |column|
    if column.name.end_with?('_id') && column.name != 'id' && !indexed_columns.include?(column.name)
      missing_indexes << { table: table, column: column.name, type: 'Foreign Key' }
    end
  end
  
  # Check for status/type enum columns
  %w[status role visibility update_type].each do |enum_col|
    if columns.any? { |c| c.name == enum_col } && !indexed_columns.include?(enum_col)
      missing_indexes << { table: table, column: enum_col, type: 'Enum/Status' }
    end
  end
end

puts "Total tables analyzed: #{tables.count}"
puts "Total indexes found: #{existing_indexes_count}"
puts

if missing_indexes.empty?
  puts '✅ All critical columns are properly indexed!'
else
  puts "⚠️  Missing indexes found (#{missing_indexes.count}):"
  missing_indexes.group_by { |mi| mi[:table] }.each do |table, mis|
    puts "\n  #{table}:"
    mis.each do |mi|
      puts "    - #{mi[:column]} (#{mi[:type]})"
    end
  end
  
  puts "\n📝 Recommendation: Add these indexes for better query performance"
end

puts "\n" + "=" * 60
