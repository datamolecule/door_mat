class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.belongs_to :actor, index: true
      t.text :state, :default => '', :null => false

      t.timestamps :null => false
    end
  end
end
