class PopularMatches < ActiveRecord::Migration
  def self.up
    create_table :popular_matches do |t|
      t.column :hits, :integer
      t.column :hash, :string
      t.column :text, :string
      t.column :updated_on, :datetime
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :popular_matches
  end
end
