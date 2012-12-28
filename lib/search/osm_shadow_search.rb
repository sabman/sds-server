class OsmShadowSearch

   def initialize(method, string)
      @method = method
      @string = string
   end

   def execute
      send(@method.to_sym, @string)
   end

   def by_tagstring(string)
      result = Array.new
      matched = Array.new
      tags = Tag.where("lower(value) like '%'||?||'%' or lower(key) like '%'||?||'%'", string.downcase, string.downcase)
      tags.each do |tag|
         shadow = OsmShadow.find(tag.osm_shadow_id)
         if (!matched.include?(shadow.id)) then
            result.push(shadow)
         end
         matched.push(shadow.id)
      end
      return result
   end

end
