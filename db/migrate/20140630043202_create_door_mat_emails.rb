class CreateDoorMatEmails < ActiveRecord::Migration
  def change
    create_table :door_mat_emails do |t|
      t.belongs_to :actor, index: true
      t.text :address_hash, :default => '', :null => false, index: true
      t.text :address, :default => '', :null => false
      t.integer :status, :default => 0

      t.timestamps :null => false
    end
  end
end
