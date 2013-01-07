class ProjectsController < ApplicationController
    before_filter :authenticate
    before_filter :admin_user

    before_filter :get_project, :only => [:show, :update, :edit, :destroy, :data]

    def show
      @title = "Showing project #{@project.name}"

    end
    
    def index
        @title = "All projects"
        @projects = Project.all
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

    def data
      @title = "Project #{@project.name} data"
      @shadows = @project.shadows
      respond_to do |format|
        format.html
        format.csv { send_data(@project.to_csv, :filename => "SDS_Project_#{@project.id}_data.csv") }
        format.xls  do
         headers["Content-Disposition"] = "attachment; filename=\"SDS_Project_#{@project.id}_data.xls\"" 
        end
      end
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
