class CreateSharedKeys < ActiveRecord::Migration
  def change
    create_table :shared_keys do |t|
      t.belongs_to :actor, index: true
      t.belongs_to :shared_data, index: true
      t.text :key, :default => '', :null => false

      t.timestamps :null => false
    end
  end
end
