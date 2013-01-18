class Project < ActiveRecord::Base
  require 'csv'
  
  has_many :memberships
  has_many :users, :through => :memberships

  attr_accessible :tags_definition, :name
  
  after_destroy :delete_presets
  
  #removes the directory along with any presets stored there
  def delete_presets
    FileUtils.rm_r(self.preset_filedir) if File.exists?(self.preset_filedir)
  end

  #saves an uploaded file. 
  def save_preset(file_upload)
    tmp = file_upload.tempfile
    filename = file_upload.original_filename
    
    #check to make sure it's xml and there's none of the usual naughty files being uploaded
    unless File.extname(filename) != ".xml" || (["crossdomain.xml", "clientaccesspolicy.xml"]).include?(filename)

      #get and if necessary create the preset for the project
      dest_dir = self.preset_filedir
      unless File.exists?(dest_dir)
        FileUtils.mkdir_p(dest_dir, :mode => 0755)
      end

      dest_file = File.join(dest_dir, filename)
      
      #delete any other exising presets? 
      # if self.preset_filename && File.exist?(preset_filepath)
      #   FileUtils.rm(preset_filepath)
      # end
      
      #copy from tempfile to the final resting place
      FileUtils.cp(tmp.path, dest_file)
      FileUtils.chmod(0644, dest_file)
      self.preset_filename = filename
      self.save
    end
  end
  
  def preset_filepath
    dest_dir = self.preset_filedir
    dest_filepath = File.join(dest_path, self.preset_filename)
    
    dest_filepath
  end
  
  def preset_filedir
    File.join("public/presets", self.id.to_s)
  end
  
  def preset_public_path
    File.join("/presets", self.id.to_s, self.preset_filename)
  end
  

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
    tags = Tag.where("tags.key in (?)", self.tag_keys).order("osm_shadow_id ASC, created_at DESC")

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
