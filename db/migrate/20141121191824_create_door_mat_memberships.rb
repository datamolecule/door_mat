class CreateDoorMatMemberships < ActiveRecord::Migration
  def change
    create_table :door_mat_memberships do |t|
      t.belongs_to :member, index: true, class_name: "DoorMat::Actor"
      t.belongs_to :member_of, index: true, class_name: "DoorMat::Actor"
      t.integer :sponsor, :default => 0
      t.integer :owner, :default => 0
      t.integer :permission, :default => 0
      t.text :key, :default => '', :null => false

      t.timestamps :null => false
    end
  end
end
