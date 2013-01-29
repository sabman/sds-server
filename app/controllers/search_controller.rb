class SearchController < ApplicationController
before_filter :authenticate, :only => [:mapsearch, :tagsearch]
before_filter :change_project, :only => [:tagsearch]
before_filter :find_project, :only => [:tagsearch]

   def mapsearch
      @title = t("search.mapsearch.head")
   end

   def tagsearch
      @title = t("search.tagsearch.head")

      if !params[:tagstring].blank? then
         @title = t("search.tagsearch.results_title")

         search = OsmShadowSearch.new("by_tagstring", params[:tagstring])
         @result = search.execute
      end
   end

end
