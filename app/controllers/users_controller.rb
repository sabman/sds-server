class UsersController < ApplicationController
   before_filter :authenticate, :only => [:update, :edit, :index, :create, :show, :new]
   before_filter :admin_user,   :only => [:update, :edit, :index, :create, :show, :new]


   def update
      @user = User.find(params[:id])
      if @user.update_attributes(params[:user])
         redirect_to @user, :notice => "User updated successfully!"
      else
         @title = "Edit User" 
         render 'edit'
      end
   end


   def edit
      @user = User.find(params[:id])
      @title = "Edit User"
   end


   def index
      @title = "All users"
      @users = User.all
      # @users = User.paginate(:page => params[:page], :per_page => 20)
   end


   def create
      @user = User.new(params[:user])
      if @user.save
         redirect_to @user, :notice => "Created new user successfully!"
      else
         @title = "New User"
         render 'new'
      end
   end


   def show
      @user = User.find(params[:id])
   end


   def new
      @user = User.new
      @title = "New User"
   end

  private
      def admin_user
         redirect_to(signin_path) unless current_user.active?
         redirect_to(home_path) unless current_user.admin?
      end
end
