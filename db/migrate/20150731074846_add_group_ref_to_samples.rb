class AddGroupRefToSamples < ActiveRecord::Migration
  def change
    add_reference :samples, :group, index: true
    remove_column :groups, :sample_id
  end
end
