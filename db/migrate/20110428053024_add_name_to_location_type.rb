class AddNameToLocationType < ActiveRecord::Migration[4.2]
  def self.up
    add_column :location_types, :name, :string
  end

  def self.down
    remove_column :location_types, :name
  end
end
