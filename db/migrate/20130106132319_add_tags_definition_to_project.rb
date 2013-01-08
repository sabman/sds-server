class AddTagsDefinitionToProject < ActiveRecord::Migration
  def change
    add_column :projects, :tags_definition, :text
  end
end
