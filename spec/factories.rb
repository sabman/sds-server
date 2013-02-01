# By using the symbol :user we get Factory Girl to simulate the User model

Factory.define :user do |user|
   user.firstname                "Phil" 
   user.lastname                 "Losoph"
   user.email                    { Factory.next(:email) }
   user.plain_password            "pass"
   user.association              :project
end

Factory.sequence :email do |n|
   "person-#{n}@geofabrik.de"
end

Factory.define :project do |p|
   p.name "BBB Home Owner"
   p.partial "simple_survey"
   p.tags_definition  [
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
end


Factory.define :changeset do |changeset|
   changeset.association :user
end

Factory.define :osm_shadow do |osm_shadow|
   osm_shadow.osm_type     "way"
   osm_shadow.osm_id       123
   osm_shadow.association  :changeset
end

Factory.define :tag do |tag|
   tag.key           "highway"
   tag.value         "my_separate_value"
   tag.association   :osm_shadow
end

