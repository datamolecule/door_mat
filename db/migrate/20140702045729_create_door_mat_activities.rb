class CreateDoorMatActivities < ActiveRecord::Migration
  def change
    create_table :door_mat_activities do |t|
      t.belongs_to :actor, index: true
      t.string :type, :default => '', :null => false
      t.integer :notifier_id, :null => false
      t.string :notifier_type, :default => '', :null => false
      t.text :link_hash, :default => '', :null => false
      t.integer :status, :default => 0

      t.timestamps :null => false
    end
  end
end
