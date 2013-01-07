class Project < ActiveRecord::Base
  require 'csv'
  
  attr_accessible :tags_definition, :name

  #converts json from db to a Ruby hash
  def fields
    return JSON.parse(tags_definition)
  end
  
  #returns an array of tag keys
  #["hot:simple:name", "hot:simple:mobile", "hot:simple:date", "hot:simple:choice"]
  def tag_keys
      tag_keys = []
      self.fields.each do | field | 
        tag_keys << field['tag'] 
      end 
      
      tag_keys
  end
  
  # Returns an array of tag names
  #["Name", "Mobile", "Date", "Choice"]
  def tag_names
      tag_names = []
      self.fields.each do | field | 
        tag_names << field['en'] 
      end 
      
      tag_names
  end

  # gets an array of tags based on the project's fields
  #<Tag id: 10, key: "hot:simple:name", value: "", osm_shadow_id: 8, created_at: "2012-09-23 16:07:01", updated_at: "2012-09-23 16:07:01">
  def tags
    tags = Tag.where("key in (?)", self.tag_keys).order("osm_shadow_id ASC, created_at DESC")

    tags
  end

  #gets an array of objects for a shadow and their tags
  #[{ "osm_shadow_id"=>"8", "osm_id"=>"1234", "osm_type"=>"way", "tags"=>[{"hot:simple:name"=>""}, {"hot:simple:mobile"=>""}]},{.,..}]
  def shadows
    tags_list = self.fields.map{|f| f["tag"]}

    shadow_array = []

    tag_groups = self.tags.group_by {|t| t['osm_shadow_id']}

    
    tag_groups.each do | tag_group |
      osm_shadow_id =  tag_group[0]
      shadow_tags = tag_group[1]
      shadow = {}
      shadow["osm_shadow_id"] = osm_shadow_id
      osm_shadow = OsmShadow.find(osm_shadow_id)
      shadow["osm_id"] = osm_shadow.osm_id
      shadow["osm_type"] = osm_shadow.osm_type
      shadow["tags"] = []

      tags_list.each do | tag_key |
        tag_obj = {tag_key => ""}
        shadow_tags.each do | shadow_tag |
          if shadow_tag.key == tag_key
            tag_obj = {tag_key => shadow_tag.value}
          end
        end

        shadow["tags"] << tag_obj
      end # tag_key
      
      shadow_array << shadow
    end #tab_groups
      
    shadow_array
  end

  #exports the project's data as a CSV tab separated with header
  def to_csv(options = {})
    csv = ""
    ["record", "osm_id", "osm_type"]
    tag_cols = ["record", "osm_id", "osm_type"].concat(self.tag_names)
    col_num = tag_cols.length
    CSV.generate_row(tag_cols, col_num, csv, "\t")
  

    self.shadows.each do | shadow |
      tag_vals = []
      tag_vals << shadow["osm_shadow_id"]
      tag_vals << shadow["osm_id"]
      tag_vals << shadow["osm_type"]
      shadow["tags"].each do | tag |
        val = tag.values[0].empty? ? nil : tag.values[0]
        tag_vals << val
      end
    
      CSV.generate_row(tag_vals, col_num, csv, "\t" )
    end
    
  return csv
end

end
