class EnablePostgresExtensions < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"     # fuzzy name/bio search
    enable_extension "cube"        # prerequisite for earthdistance
    enable_extension "earthdistance" # proximity queries without PostGIS
    enable_extension "citext"      # case-insensitive email
  end
end
