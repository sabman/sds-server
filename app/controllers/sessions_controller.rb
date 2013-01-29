class SessionsController < ApplicationController
   def new
      @title = t("sessions.new.head")
   end

   def create 
      user = User.authenticate(params[:session][:email], params[:session][:password])
      if user.nil?
         flash.now[:alert] = t("alert.invalid_email_pw")
         @title = t("sessions.new.head")
         render 'new'
      else
         sign_in user
         redirect_to home_path
      end 
   end

   def destroy
      sign_out
      redirect_to root_path
   end
end
