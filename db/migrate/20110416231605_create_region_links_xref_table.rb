class CreateRegionLinksXrefTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :region_link_xrefs do |t|
      t.string :name
      t.string :url
      t.string :description
    end
  end

  def self.down
    drop_table :region_link_xrefs
  end
end
