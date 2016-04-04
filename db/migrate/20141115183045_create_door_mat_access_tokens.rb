class CreateDoorMatAccessTokens < ActiveRecord::Migration
  def change
    create_table :door_mat_access_tokens do |t|

      t.belongs_to :actor
      t.text :hashed_token, :default => '', :null => false, index: true
      t.text :name, :default => '', :null => false
      t.integer :token_for, :default => 0
      t.integer :status, :default => 0
      t.text :identifier, :default => '', :null => false
      t.text :data, :default => '', :null => false
      t.integer :reference_id, :default => 0, :null => false

      t.timestamps :null => false
    end
  end
end
