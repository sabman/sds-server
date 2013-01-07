require 'spec_helper'

describe ProjectsController do
  render_views
   
  before(:each) do
    @project = Factory(:project)
    @project_2 = Factory(:project, :name => "extra project")
  end

  describe "GET 'show'" do

    describe "as not-signed-in user" do
      it "should redirect to sign-in page" do
        get 'show',  :id => @project.id
        response.should redirect_to(signin_path)
      end
    end

    describe "as a signed in non-admin user" do
      before(:each) do
        user = Factory(:user, :email => "aaaa@geofabrik.de")
        test_sign_in(user)
      end
      it "should redirect to home page" do
        get 'show', :id => @project.id
        response.should redirect_to(home_path)
      end
    end

    describe "as a signed in admin user" do
      before(:each) do
        user = Factory(:user, :email => "aaaa@geofabrik.de")
        user.toggle(:admin)
        test_sign_in(user)
      end
      it "should be successful" do
        get 'show', :id => @project.id
        response.should be_success
      end


      it "should show the specified project" do
        get 'show', :id => @project.id
        response.should have_selector("h2", :content => "#{@project.name}")
      end

    end
  end


  describe "GET 'index'" do
    describe "as not-signed-in user" do
      it "should redirect to sign-in page" do
        get 'index'
        response.should redirect_to(signin_path)
      end

    end
         
    describe "as a signed in non-admin user" do
      before(:each) do
        user = Factory(:user, :email => "aaaa@geofabrik.de")
        test_sign_in(user)
      end
      it "should redirect to home page" do
        get 'index'
        response.should redirect_to(home_path)
      end
    end

    describe "as a signed in admin user" do
      before(:each) do
        user = Factory(:user, :email => "aaaa@geofabrik.de", :admin => true)
        test_sign_in(user)
        @projects = Project.all
      end

      it "should be successful" do
        get 'index'
        response.should be_success
      end

      it "should list the projects" do
        get 'index'
        assigns(:projects).should == @projects
      end


    end

  end
      
  describe "As an admin user" do
    before(:each) do
      user = Factory(:user, :email => "aaaa@geofabrik.de", :admin => true)
      test_sign_in(user)
    end
         
    it "edits a project" do
      get :edit, :id => @project.id
      response.should be_success
      assigns(:project).should == @project
      response.should have_selector("form",  :method => "post")
    end
         
    it "deletes a project" do
      delete :destroy, :id => @project.id
      response.should redirect_to(projects_path)
    end
         
    it "deletes a project 2" do
      pcount = Project.count
      lambda {
        delete :destroy, :id => @project.id
      }.should change {Project.count}.from(pcount).to(pcount-1)
    end
         
    it "makes a new project" do
      get :new
      response.should be_success
    end


    it "updates the project name and tag specs" do
      tags_def = [
        { :tag => 'hot:simple:name',
          :type => 'text',
          :en => "Name changed" },
        { :tag => 'hot:simple:mobile',
          :type => 'text',
          :en => "Mobile", :id => "Nomor Handphone" },
        { :tag => 'hot:simple:date',
          :type => 'date',
          :en => "Date", :id => "Tanggal" },
        { :tag => 'hot:simple:choice',
          :type => 'select',
          :options => ['yes','no','maybe','of course'],
          :en => "Choice" }
      ].to_json

      form_attrs = {:name => "new name", :tags_definition => tags_def }

      put :update, :id => @project.id, :project => form_attrs

      project = Project.find(@project.id)

      project.name.should eql "new name"
      project.fields.any?{ |f| f['en'] == "Name changed" }.should be_true
    end

    pending "specs for create"
    pending "specs for data"
    pending "specs for download xls and csv"
    
  end
end
