class ApplicationController < ActionController::Base
   protect_from_forgery  
   include SessionsHelper

  private

   def admin_user
      redirect_to(signin_path) unless current_user.active?
      redirect_to(home_path) unless current_user.admin?
   end

  def change_project
    @user = current_user
    unless params['change_project'].blank?
      target_project = Project.find(params['change_project'])
      if target_project.in?(current_user.projects)
        current_user.project_id = params['change_project']
        current_user.save!
      end
    end
  end

end
