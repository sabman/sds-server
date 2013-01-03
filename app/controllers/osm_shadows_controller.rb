class OsmShadowsController < ApplicationController
   before_filter :authenticate,  :only => [:index, :show, :list, :new, :edit, :create, :destroy]
   before_filter :change_project, :only => [:show, :list, :new, :edit]
   before_filter :admin_user,   :only => [:destroy]


   require 'xml/libxml'
   require 'pp'

   def index
      redirect_to tagsearch_path
   end


   def show
      @title = "Object Properties"
      retrieve_object
   end

   def list
      @title = "Records for this Object"
      
      retrieve_objects
      
      if (@osm_shadow.nil?) then
         @osm_shadow = OsmShadow.new
         @osm_shadow.osm_type = params[:osm_type]
         @osm_shadow.osm_id = params[:osm_id]
         @tags = Array.new
         @taghash = Hash.new
      end
      
      if params['zoom']
         current_user.zoom = params['zoom'] || 0
         current_user.lon  = params['lon'] || 0
         current_user.lat  = params['lat'] || 0
         current_user.save!
      end
   end


   def edit 
      @title = "Edit Tags"
      retrieve_object
   end


   def new
      @title = "New Tags"

      @osm_shadow = OsmShadow.new
      @osm_shadow.osm_type = params[:osm_type]
      @osm_shadow.osm_id = params[:osm_id]
      @tags = Array.new
      @taghash = Hash.new
   end


   def update
      if (!current_changeset.nil?) then
         changeset = current_changeset
      elsif (!current_user.nil?) then
         changeset = Changeset.new
         changeset.user_id = current_user.id
         changeset.save!
         store_changeset(changeset)
      end
      params['osm_shadow']['changeset_id'] = changeset.id
      
      shadow = OsmShadow.find(params[:id])
      shadow.changeset = changeset
      
       if shadow.update_attributes!(params["osm_shadow"])
         redirect_to(shadow, :notice => "Record updated successfully")
       else
         redirect_to({:action => :edit}, {:alert => "Sorry, Record was unable to be updated."})
       end

   end

   def create
   
      if (!current_changeset.nil?) then
         changeset = current_changeset
      elsif (!current_user.nil?) then
         changeset = Changeset.new
         changeset.user_id = current_user.id
         changeset.save!
         store_changeset(changeset)
      end
      params['osm_shadow']['changeset_id'] = changeset.id
      
      @osm_shadow = OsmShadow.new(params['osm_shadow'])
      
      if @osm_shadow.save
         redirect_to(@osm_shadow, :notice => "Record successfully saved.")
      else
         @tags = Array.new
         @taghash = Hash.new
         render :action => "new", :alert => "Sorry, Record was unable to be saved."
      end
   end


   def destroy
      @osm_shadow = OsmShadow.find(params[:id])
      @osm_shadow.destroy
      
      redirect_to(list_shadows_url(:osm_type => @osm_shadow.osm_type, :osm_id=>@osm_shadow.osm_id), {:notice => "Record was successfully deleted."})
   end
   
private

   def retrieve_object
      if params[:id]
         @osm_shadow = OsmShadow.find(params[:id])
      else
         @osm_shadow = OsmShadow.find_oldest(params[:osm_type], params[:osm_id])
      end
     
      @tags = Array.new
      @taghash = Hash.new
      if (!@osm_shadow.nil?) then
         @osm_shadow.tags.each do |tag|
            @tags.push(tag)
            @taghash[tag.key] = tag.value
         end
      end
   end


   def retrieve_objects
      @osm_shadows = OsmShadow.where("osm_type = ? and osm_id = ?",  params[:osm_type], params[:osm_id])
      @osm_shadow = @osm_shadows.first
   end


   def change_project
      @user = current_user
      if !params['change_project'].blank? then
         current_user.project_id = params['change_project']
         current_user.save!
      end
   end
   
   def admin_user
      redirect_to(signin_path) unless current_user.active?
      redirect_to(home_path) unless current_user.admin?
   end
   
end
