class Tag < ActiveRecord::Base
   attr_accessible :key, :value, :osm_shadow_id
   belongs_to :osm_shadow
   has_paper_trail

   validates :key, :presence => true
   # validates :value, :presence => true
   validates_presence_of :osm_shadow

  end
