class AddAccessTokenRatingColumn < ActiveRecord::Migration
  def change
    add_column :door_mat_access_tokens, :rating, :integer, :default => 0
  end
end
