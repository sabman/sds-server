class JosmapiController < ApplicationController
   before_filter :authenticate,  :only => [:createshadows, :collectshadows]
   skip_before_filter :verify_authenticity_token

   def collectshadows 
      doc = OsmShadowXmlConverter.get_xml_doc 

      shadows = OsmShadow.from_collectshadows_params(params)
      shadows.each do |s|
         doc.root << s.to_xml_node
      end

      render :text => doc.to_s, :content_type => "text/xml"
   end

   def createshadows
      existing_shadows, new_shadows = OsmShadowXmlConverter.from_xml(request.raw_post)

      changeset = Changeset.new
      changeset.user = current_user
      changeset.save!
      
      new_shadows.each do | shadow|
         shadow.changeset_id = changeset.id
         shadow.save_new_with_tags
      end

      render :text => changeset.id.to_s, :content_type => "text/xml"
   end

private
   def authenticate
      if user = authenticate_with_http_basic { |u, p| User.authenticate(u, p) }
         @current_user = user
      else
         request_http_basic_authentication
      end
   end

end

