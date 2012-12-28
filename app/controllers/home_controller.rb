class HomeController < ApplicationController
   before_filter :authenticate, :only => [:index, :status]
   before_filter :admin_user,   :only => [:status]

   def index
      @title = "Home"
   end

   def status
      @title = "Application Status"


      @cnt_objects = OsmShadow.count
      @cnt_tags = Tag.count
      @cnt_users_active = User.where("active = 'true'").count
      @users_admin  = User.where("admin  = 'true'")

      @last_edits = Changeset.limit(5)
   end



private
   def admin_user
      redirect_to(signin_path) unless current_user.active?
      redirect_to(home_path) unless current_user.admin?
   end

end
