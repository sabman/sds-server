class ApplicationController < ActionController::Base
   protect_from_forgery  
   include SessionsHelper

  private

   def admin_user
      redirect_to(signin_path) unless current_user.active?
      redirect_to(home_path) unless current_user.admin?
   end

   #finds project from session, or if not in session, gets it from the current users project list
   def find_project
     if session[:active_project]
       @active_project = Project.find(session[:active_project])
       unless current_user.projects.include?(@active_project)
         session[:active_project] = nil
         redirect_to(home_path, :alert => "Sorry you are not subscribed to this project")
       end
     elsif current_user.projects.first
       @active_project = current_user.projects.first
       session[:active_project] = @active_project.id
     else
       session[:active_project] = nil
       redirect_to(home_path, :alert => "Sorry you are not subscribed to this project.")
     end

   end


  def change_project
    unless params['change_project'].blank?
      target_project = Project.find(params['change_project'])
      session[:active_project] = nil
      if current_user.projects.include?(target_project)
        session[:active_project] = target_project.id
      else
        redirect_to(home_path, :alert => "Sorry you are not subscribed to this project.")
      end
    end
  end

end
