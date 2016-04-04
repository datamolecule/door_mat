class CreateSharedData < ActiveRecord::Migration
  def change
    create_table :shared_data do |t|
      t.text :document, :default => '', :null => false
      t.text :expiration_date, :default => '', :null => false

      t.timestamps :null => false
    end
  end
end
