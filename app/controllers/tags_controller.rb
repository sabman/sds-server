class TagsController < ApplicationController
  before_filter :authenticate

  def show
    @tag = Tag.find(params[:id])
    @osm_shadow = @tag.osm_shadow
    @tags = Array.new
    @taghash = Hash.new
    @visible_tag_keys = current_user.find_visible_tag_keys

    if (!@osm_shadow.nil?) then
      @osm_shadow.tags.each do |tag|
        @tags.push(tag)
        @taghash[tag.key] = tag.value
      end
    end
  end

  def revert
    #previous_tag = Tag.find(params[:id])
    @tag = Version.find(params[:id]).reify
    @tag.save
    redirect_to(@tag, :notice => t("notice.tag_reverted"))
  end
   
end