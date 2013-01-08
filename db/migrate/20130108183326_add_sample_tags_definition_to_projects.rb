class AddSampleTagsDefinitionToProjects < ActiveRecord::Migration
  def change
    #let's add the same data too
    p = Project.find_by_name("Rate it")
    p.tags_definition = [
      { :tag => 'hot:rate:name',
        :type => 'text',
        :en => "Nick Name" },
      { :tag => 'hot:rate:choice',
        :type => 'select',
        :options => ['1','2','3','4','5'],
        :en => "Stars" }
    ].to_json
    p.save

    p = Project.find_by_name("Hospital")
    p.tags_definition = [
      { :tag => 'hot:hospital:director_name',
        :type => 'text',
        :en => "Director Name" },
      { :tag => 'hot:simple:director_mobile',
        :type => 'text',
        :en => "Director Mobile Number" },
      { :tag => 'hot:hospital:full_beds',
        :type => 'text',
        :en => "Total Full Beds"},
      { :tag => 'hot:hospital:doctors',
        :type => 'text',
        :en => "Doctors on Staff" }
    ].to_json
    p.save

    p = Project.find_by_name("Simple Survey")
    p.tags_definition = [
      { :tag => 'hot:simple:name',
        :type => 'text',
        :en => "Name" },
      { :tag => 'hot:simple:mobile',
        :type => 'text',
        :en => "Mobile", :id => "Nomor Handphone" },
      { :tag => 'hot:simple:date',
        :type => 'date',
        :en => "Date", :id => "Tanggal" },
      { :tag => 'hot:simple:choice',
        :type => 'select',
        :options => ['yes','no','maybe','of course'],
        :en => "Choice" }
    ].to_json
    p.save

  end
end
