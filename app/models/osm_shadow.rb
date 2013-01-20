class OsmShadow < ActiveRecord::Base
   include OsmShadowXmlConverter

   attr_accessible :osm_id, :osm_type, :version, :changeset_id, :tags_attributes
   before_create :generate_version

   belongs_to :changeset
   has_many :tags, :dependent => :destroy
   
   #save tags when saving this object, but dont save it if it's a new tag, and it's empty 
   accepts_nested_attributes_for :tags, :allow_destroy => true, :reject_if => proc { |tag| tag['value'].blank? && tag['id'].blank?}

   validates :changeset_id, :presence => true
   validates :osm_type, :presence => true, :inclusion => { :in => ["node", "way", "relation"]}
   validates :osm_id, :presence => true, :numericality => {:less_than_or_equal_to => 9223372036854775807}

   #workaround for rails bug with creating new children and new parent objects at same time (#1943)
   before_validation :initialize_tags, :on => :create
   def initialize_tags
      tags.each { |t| t.osm_shadow = self }
   end

   
   def save_new_with_tags
      if !self.new_record?
         return false
      end

      shadow = OsmShadow.new({
         :osm_type      => osm_type, 
         :osm_id        => osm_id,
         :changeset_id  => changeset_id
      })
      shadow.save!
      self.id = shadow.id
      self.version = shadow.version

      self.tags.each do |t|
         shadow.tags.create!({
            :key            => t.key,
            :value          => t.value
         })
      end

      return shadow
   end

   

   def sibling_count
       if self.osm_id
         OsmShadow.count(:conditions => "osm_type = '#{self.osm_type}' and osm_id = #{self.osm_id}")
       else
         nil
       end
     end
   
   def self.find_oldest(otype, oid)
      OsmShadow.where("osm_type = ? and osm_id = ?", otype, oid).order("created_at ASC").first
   end

   
   
   def self.from_collectshadows_params(params)
      shadows = Array.new

      ['nodes', 'ways', 'relations'].each do |ot|
      
         unless params[ot].nil?
            ids = params[ot].split(',')
            
            ids.each do | id |
               shadow = OsmShadow.find_oldest(ot.chomp('s'), id)
               shadows << shadow unless shadow.nil?
            end
 
         end
      end
     
      return shadows
   end


   def self.from_params(params)
      shadow = OsmShadow.new({
         'osm_id' => params['osm_shadow']['osm_id'],
         'osm_type' => params['osm_shadow']['osm_type'],
         'changeset_id' => params['changeset_id']
      })

      if (!params['tags'].nil?) then
         i = 0
         while i < params['tags']['key'].length
            shadow.add_tag(params['tags']['key'][i], params['tags']['value'][i])
            i += 1
         end
      elsif (!params['taghash'].nil?) then
         params['taghash'].each do |key, value|
            if (params['unselected_value'].nil?) then
               shadow.add_tag(key, value)
            elsif (value != params['unselected_value']) then
               shadow.add_tag(key, value)
            end
         end
      end
      return shadow
   end
   

   def add_tag(key, value)
      tag = Tag.new
      tag.key = key
      tag.value = value
      self.tags << tag unless key.blank?
   end

private
   def generate_version
      version = OsmShadow.where("osm_id = ? and osm_type = ?", self.osm_id, self.osm_type).maximum("version")
      if version.nil?
         self.version = 1
      else
         self.version = version + 1
      end
   end

end
