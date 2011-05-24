class AddPrivateStatechange < ActiveRecord::Migration
  def self.up
    add_column :comments, :previous_is_private, :boolean, :default => nil
  end

  def self.down
    remove_column :comments, :previous_is_private
  end
end
