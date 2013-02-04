class TagsController < ApplicationController
  before_filter :authenticate

  def show
    @tag = Tag.find(params[:id])

    @visible_tag_keys = current_user.find_visible_tag_keys
    
    unless @visible_tag_keys.include? @tag.key
      redirect_to(home_path, :alert => t("alert.not_allowed"))
    else

      @osm_shadow = @tag.osm_shadow
      @tags = Array.new
      @taghash = Hash.new
    
      if (!@osm_shadow.nil?) then
        @osm_shadow.tags.each do |tag|
          @tags.push(tag)
          @taghash[tag.key] = tag.value
        end
      end
    end
  end

  def revert
    @tag = Version.find(params[:id]).reify

    @visible_tag_keys = current_user.find_visible_tag_keys
    
    unless @visible_tag_keys.include? @tag.key
      redirect_to(home_path, :alert => t("alert.not_allowed"))
    else
      @tag.save
      redirect_to(@tag, :notice => t("notice.tag_reverted"))
    end
  end
   
end