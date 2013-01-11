class AddPresetFilenameToProject < ActiveRecord::Migration
  def change
    add_column :projects, :preset_filename, :string
  end
end
