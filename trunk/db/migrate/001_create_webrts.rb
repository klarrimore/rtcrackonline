class CreateWebrts < ActiveRecord::Migration
  def self.up
    create_table :webrts do |t|
       t.column :gstring, :string
       t.column :lmhash, :string, :null => false
       t.column :lmhash_half1, :string, :null => false
       t.column :lmhash_half2, :string
       t.column :status, :string
       t.column :text, :string
       t.column :text_half1, :string
       t.column :text_half2, :string
       t.column :cracked_half1, :boolean, :default => false
       t.column :cracked_half2, :boolean, :default => false
       t.column :email, :string
       t.column :ip_address, :string
       t.column :elapsed_time, :string
       t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :webrts
  end
end
