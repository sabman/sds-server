class ProjectsController < ApplicationController
    before_filter :authenticate
    before_filter :admin_user

    before_filter :get_project, :only => [:show, :update, :edit, :destroy]

    def show

    end
    
    def index
        @projects = Project.all
        logger.debug @projects.inspect
    end
    
    def new
        @project = Project.new
    end

    def create
        @project = Project.new(params[:project])
      
      if @project.save
         redirect_to(@project, :notice => "Record successfully saved.")
      else
         render :action => "new", :alert => "Sorry, Record was unable to be saved."
      end
    end

    def edit
    end

    def update
        if @project.update_attributes!(params[:project])
         redirect_to(@project, :notice => "Project updated successfully")
       else
         redirect_to(edit_project_path(@project), :alert => "Sorry, Record was unable to be updated.")
       end
    end

    def destroy
      @project.destroy
      redirect_to(projects_path, :notice => "Record was successfully deleted.")
    end

    private
    def get_project
        @project = Project.find_by_id(params[:id])
    end

   def admin_user
      redirect_to(signin_path) unless current_user.active?
      redirect_to(home_path) unless current_user.admin?
   end
end
