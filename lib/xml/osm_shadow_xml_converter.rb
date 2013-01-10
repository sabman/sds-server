module OsmShadowXmlConverter

   require 'xml/libxml'

   def to_xml_node(allowed_tag_keys)
      node = XML::Node.new 'osm_shadow'
      node['osm_id'] = self.osm_id.to_s
      node['osm_type'] = self.osm_type

      self.tags.each do |tag|
        if allowed_tag_keys.include?(tag.key)
         tnode = XML::Node.new 'tag'
         tnode['k'] = tag.key
         tnode['v'] = tag.value
         node << tnode
        end
      end

      return node
   end

   
   def self.from_xml(xml, allowed_tag_keys)
      collection = []
      existing_shadows  = []
      parser = XML::Parser.string(xml)
      doc = parser.parse

      doc.find('//osm_sds/osm_shadow').each do |s|
         #find and update an existing osm shadow, and if necessary, update or create any tags
         if OsmShadow.exists?(:osm_id => s['osm_id'], :osm_type => s['osm_type'])
            existing_shadow = OsmShadow.find_oldest(s['osm_type'], s['osm_id'])
            s.find('tag').each do |t|
              if allowed_tag_keys.include?(t['k'])
                 tag = existing_shadow.tags.find_or_initialize_by_key(t['k'])
                 tag.value = t['v']
                 tag.save
              end
            end
            
            existing_shadows << existing_shadow
         else
            shadow = OsmShadow.new({'osm_id' => s['osm_id'], 'osm_type' => s['osm_type']})

            s.find('tag').each do |t|
              if allowed_tag_keys.include?(t['k'])
               tag = Tag.new({'key' => t['k'], 'value' => t['v']})
               shadow.tags << tag
              end
            end
            collection.push(shadow)
         end
      end
      new_shadows = collection
      
      return existing_shadows, new_shadows
   end
   

   def self.get_xml_doc
      doc = XML::Document.new
      doc.encoding = XML::Encoding::UTF_8
      root = XML::Node.new 'osm_sds'
      doc.root = root
      return doc
   end

end
