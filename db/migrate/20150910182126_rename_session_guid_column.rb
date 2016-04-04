class RenameSessionGuidColumn < ActiveRecord::Migration
  def change
    rename_column :door_mat_sessions, :session_guid, :hashed_token
  end
end
