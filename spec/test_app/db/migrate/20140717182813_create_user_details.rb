class CreateUserDetails < ActiveRecord::Migration
  def change
    create_table :user_details do |t|
      t.belongs_to :actor, index: true
      t.text :name, :default => '', :null => false

      t.timestamps :null => false
    end
  end
end
