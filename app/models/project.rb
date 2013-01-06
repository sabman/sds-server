class Project < ActiveRecord::Base
  attr_accessible :tags_definition, :name

  def fields
    return JSON.parse(tags_definition)
  end

  # gets an array of tags based on the project's fields
  #<Tag id: 10, key: "hot:simple:name", value: "", osm_shadow_id: 8, created_at: "2012-09-23 16:07:01", updated_at: "2012-09-23 16:07:01">
  def tags
    tag_keys = []
    self.fields.each {| f| tag_keys << f["tag"]  }

    tags = Tag.where("key in (?)", tag_keys).order("osm_shadow_id ASC, created_at DESC")

    tags
  end

  #gets an array of objects for a shadow and their tags
  #[{ "osm_shadow_id"=>"8", "tags"=>[{"hot:simple:name"=>""}, {"hot:simple:mobile"=>""}]},{.,..}]
  def shadows
    tags_list = self.fields.map{|f| f["tag"]}

    shadow_array = []

    tag_groups = self.tags.group_by {|t| t['osm_shadow_id']}

    
    tag_groups.each do | tag_group |
      osm_shadow_id =  tag_group[0]
      shadow_tags = tag_group[1]
      shadow = {}
      shadow["osm_shadow_id"] = osm_shadow_id
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


end
