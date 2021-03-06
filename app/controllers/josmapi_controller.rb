class JosmapiController < ApplicationController
   before_filter :authenticate,  :only => [:createshadows, :collectshadows]
   skip_before_filter :verify_authenticity_token

   def collectshadows 
      doc = OsmShadowXmlConverter.get_xml_doc 

      allowed_tag_keys = @current_user.find_visible_tag_keys
      shadows = OsmShadow.from_collectshadows_params(params)
      shadows.each do |s|
         doc.root << s.to_xml_node(allowed_tag_keys)
      end

      render :text => doc.to_s, :content_type => "text/xml"
   end

   def createshadows
      allowed_tag_keys = @current_user.find_visible_tag_keys
      
      existing_shadows, new_shadows = OsmShadowXmlConverter.from_xml(request.raw_post, allowed_tag_keys)

      changeset = Changeset.new
      changeset.user = current_user
      changeset.save!
      
      new_shadows.each do | shadow|
         shadow.changeset_id = changeset.id
         
         shad = OsmShadow.new({
             :osm_type      => shadow.osm_type,
             :osm_id        => shadow.osm_id,
             :changeset_id  => shadow.changeset_id
          })
          shad.save!
          shadow.id = shad.id

          shadow.tags.each do |t|
            tag = Tag.new(:key => t.key, :value => t.value)
            shad.tags << tag
          end

       end 

      render :text => changeset.id.to_s, :content_type => "text/xml"
   end

private
   def authenticate
      if user = authenticate_with_http_basic { |u, p| User.authenticate(u, p) }
         @current_user = user
         PaperTrail.whodunnit = @current_user.id.to_s
      else
         request_http_basic_authentication
      end
   end

end

