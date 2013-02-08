class UsersController < ApplicationController
   before_filter :authenticate
   before_filter :admin_user,   :only => [:update, :edit, :index, :create, :show, :new]


   def update
      @user = User.find(params[:id])
      if @user.update_attributes(params[:user])
         redirect_to @user, :notice => t("notice.user_updated")
      else
         @title = "Edit User" 
         render 'edit'
      end
   end


   def edit
      @user = User.find(params[:id])
      if params[:reset_password] 
         @user.plain_password = User.generate_password
      end
      @title = "Edit User"
   end


   def index
      if params[:project_id]
        @project = Project.find(params[:project_id])
        @title = "Project #{@project.name} users"
        @users = @project.users
      else
        @title = "All users"
        @users = User.all
      end
   end


   def create
      @user = User.new(params[:user])
      if @user.save
         redirect_to @user, :notice => t("notice.user_created")
      else
         @title = "New User"
         @user.memberships = []
         render 'new'
      end
   end


   def show
      @user = User.find(params[:id])
   end


   def new
      @user = User.new
      @user.plain_password = User.generate_password
      @title = "New User"
   end
   
   #shows the change password form
   def change_password
   
   end
   
   #user can update their own password
   def update_password
      if User.authenticate(current_user.email, params[:old_password])
         if params[:password] == params[:password_confirmation]
            current_user.plain_password = params[:password]
            
               if current_user.save!
                  redirect_to home_path, :notice => t("notice.password_updated") 
               else
                  redirect_to change_password_path, :alert => t("alert.password_not_updated")
               end
            
            else
               redirect_to change_password_path, :alert => t("alert.password_mismatch")
            end
            
      else
         redirect_to change_password_path, :alert => t("alert.password_incorrect")
      end
        
   end


end
