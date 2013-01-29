class ApplicationController < ActionController::Base
   protect_from_forgery  
   include SessionsHelper
   before_filter :set_locale

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
         redirect_to(home_path, :alert => t("alert.project_not_subscribed") )
       end
     elsif current_user.projects.first
       @active_project = current_user.projects.first
       session[:active_project] = @active_project.id
     else
       session[:active_project] = nil
       redirect_to(home_path, :alert => t("alert.project_not_subscribed") )
     end

   end


  def change_project
    unless params['change_project'].blank?
      target_project = Project.find(params['change_project'])
      session[:active_project] = nil
      if current_user.projects.include?(target_project)
        session[:active_project] = target_project.id
      else
        redirect_to(home_path, :alert => t("alert.project_not_subscribed"))
      end
    end
  end

  def set_locale
    if current_user && params[:locale] && I18n.available_locales.map{|lo| lo.to_s}.include?(params[:locale])
      current_user.locale = params[:locale]
      current_user.save
    end

    if current_user && I18n.available_locales.map{|lo| lo.to_s}.include?(current_user.locale)
      session[:locale] = current_user.locale
    else
      session[:locale] = I18n.default_locale
    end

    I18n.locale = session[:locale] || I18n.default_locale
  end

end
