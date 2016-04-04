class CreateDoorMatActors < ActiveRecord::Migration
  def change
    create_table :door_mat_actors do |t|
      # The salt of the user's password derived key; used for symmetric encryption of data
      t.text :key_salt, :default => '', :null => false
      # The salt of the password
      t.text :password_salt, :default => '', :null => false
      # The resulting hash used for authentication
      t.text :password_hash, :default => '', :null => false
      # A symmetric encryption key used by the system to encrypt data before handing it to the user
      t.text :system_key, :default => '', :null => false
      # The encrypted user key, used to recover data in a password recovery scenario
      t.text :recovery_key, :default => '', :null => false

      # The key to decrypt the pem pbkey; it is encrypted using the user's password derived key
      t.text :encrypted_pem_key, :default => '', :null => false
      t.text :pem_encrypted_pkey, :default => '', :null => false
      t.text :pem_public_key, :default => '', :null => false

      t.timestamps :null => false
    end
  end
end
