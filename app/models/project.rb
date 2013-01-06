class Project < ActiveRecord::Base
  attr_accessible :tags_definition, :name

  def fields
    return JSON.parse(tags_definition)
  end

end
