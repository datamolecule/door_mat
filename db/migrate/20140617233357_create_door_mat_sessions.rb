class CreateDoorMatSessions < ActiveRecord::Migration
  def change
    create_table :door_mat_sessions do |t|
      t.belongs_to :actor, index: true
      t.belongs_to :email
      t.string :session_guid, :default => '', :null => false, index: true
      t.text :type, :default => '', :null => false
      t.text :agent, :default => '', :null => false
      t.text :ip, :default => '', :null => false
      t.text :encrypted_symmetric_actor_key, :default => '', :null => false
      t.datetime :password_authenticated_at, :default => Date.new(2014,1,1), :null => false
      t.integer :rating, :default => 0

      t.timestamps :null => false
    end
  end
end
