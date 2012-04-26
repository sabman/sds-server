class AddSampleProjects < ActiveRecord::Migration
  def change
    
   Project.create!(:name => "Rate it", :partial => "rate_it")
   Project.create!(:name => "Hospital", :partial => "hospital")
   Project.create!(:name => "Simple Survey", :partial => "simple_survey")
    
    
  end

  
end
