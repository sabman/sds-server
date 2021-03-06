require 'spec_helper'

describe OsmShadowsController do
   render_views

   describe "signed-in user" do
      before(:each) do
         @user = Factory(:user)
         test_sign_in(@user)
         @project = Factory(:project)
         @user.projects << @project
      end

      describe "GET 'index'" do
         it "should redirect to tagsearch" do
            get :index
            response.should redirect_to(tagsearch_path)
         end
      end

      describe "GET 'list'" do
         before(:each) do
            @osm_shadows = [Factory(:osm_shadow), Factory(:osm_shadow)]
            @osm_shadow = @osm_shadows.first
         end
         
         it "should be successful" do
            get :list, :osm_type => @osm_shadow.osm_type, :osm_id => @osm_shadow.osm_id
            response.should be_success
         end
         
         it "should have the right title" do
            get :list, :osm_type => @osm_shadow.osm_type, :osm_id => @osm_shadow.osm_id
            response.should have_selector("title", :content => "Records for this Object")
         end
      
         it "should assign the osm shadows" do
            get :list, :osm_type => @osm_shadow.osm_type, :osm_id => @osm_shadow.osm_id
            assigns(:osm_shadows).should == @osm_shadows
         end
         
         it "should save zoom, lat and lon from params" do
            @lat = 11.0
            @lon = 12.0
            @zoom = 13
            get :list, :osm_type => "way", :osm_id => 123, :zoom => @zoom, :lat => @lat, :lon => @lon
            @user.lat.should == @lat
            @user.lon.should == @lon
            @user.zoom.should == @zoom
         end
      
      end

      describe "GET 'show'" do
         before(:each) do
            @osm_shadow = Factory(:osm_shadow)
         end
         it "should be successfull"  do
            get :show, :id => @osm_shadow.id
            response.should be_success
         end

         it "should have the right title" do
            get :show, :id => @osm_shadow.id 
            response.should have_selector("title", :content => "Object #{@osm_shadow.id} Properties")
         end
         
          it "should assign the osm shadow" do
            get :show, :id => @osm_shadow.id
            assigns(:osm_shadow).should == @osm_shadow
         end
      end

      describe "GET 'new'" do

         it "should be successfull" do
            get :new, :osm_type => "way", :osm_id => 123
            response.should be_success
         end

         it "should have the right title" do
            get :new, :osm_type => "way", :osm_id => 123
            response.should have_selector("title", :content => "New Tags")
         end

      end

      describe "GET 'edit'" do
         before(:each) do
            @osm_shadow = Factory(:osm_shadow)
         end
         it "should be successfull" do 
            get :edit, :id => @osm_shadow.id
            response.should be_success
         end

         it "should have the right title" do
            get :edit, :id => @osm_shadow.id
            response.should have_selector("title", :content => "Edit Tags")
         end
      end
      
      describe "non admined DELETE 'destroy'" do
         before(:each) do
            @osm_shadow = Factory(:osm_shadow)
         end
         it "should redirect to list view" do 
            delete :destroy, :id => @osm_shadow.id
            response.should redirect_to(home_path)
         end
         
         it "should not reduce the osm shadow count by one" do
            lambda {
             delete :destroy, :id => @osm_shadow.id
            }.should_not change {OsmShadow.count}.from(1).to(0)
         end

      end
   end

   #updating an osm_shadow - which is more about updating the tags.
   describe "POST update" do
      describe "success" do
         before(:each) do
            @user = Factory(:user)
            @changeset = Factory(:changeset)
            @project = Factory(:project)
            @user.projects << @project

            @forbidden_project = Factory(:project, :name=>"another project",
                  :tags_definition => [{ :tag => 'akey', :type => 'text', :en => "a key"}].to_json)

            test_sign_in(@user)
            
            @shadow = Factory(:osm_shadow)
            @t1 = Factory(:tag, :osm_shadow => @shadow, :key=>"hot:simple:name", :value => "cat")
            @t2 = Factory(:tag, :osm_shadow => @shadow, :key =>"akey", :value => "dog")
            
            @osmattr = {:osm_id => @shadow.osm_id, :osm_type => @shadow.osm_type}
         end
      
         #should only update the hot:simple:name tag
         it "should update existing tags where allowed" do
            form_attrs = @osmattr.merge({:tags_attributes => {
               "0" =>{"id" => @t1.id, "key"=>"hot:simple:name", "value"=>"tabby"}, 
               "1" =>{"id" => @t2.id, "key"=>"akey", "value"=>"poodle"}
               }})
            put :update, :id => @shadow.id, :osm_shadow => form_attrs
            
            shad = OsmShadow.find(@shadow.id)
  
            shad.tags.count.should eql 2
            shad.tags.find_by_key("hot:simple:name").value.should eql "tabby"
            shad.tags.find_by_key("akey").value.should eql "dog"
         end
         
         #it should only create the new tag for the allowed project
         it "should create any new tags" do
            form_attrs = @osmattr.merge({:tags_attributes => {
               "0" =>{"id" => @t1.id, "key"=>"hot:simple:name", "value"=>"tabby"}, 
               "1" =>{"key"=>"hot:simple:mobile", "value"=>"12345"},
               "2" =>{"key"=>"surname", "value"=>"claus"}
               }})

            put :update, :id => @shadow.id, :osm_shadow => form_attrs

            shad = OsmShadow.find(@shadow.id)

            #user just has access to one project, hot:simple so only one additional tag should be created.
            #it already has 2. We update one, and add one more.
            shad.tags.count.should eql 3
            shad.tags.find_by_key("akey").value.should eql "dog" #existing, not updated by user
            shad.tags.find_by_key("hot:simple:name").value.should eql "tabby" #existing, updated
            shad.tags.find_by_key("hot:simple:mobile").value.should eql "12345" #new tag, created
            shad.tags.find_by_key("surname").should be_nil  #new tags NOT created
         end
         
         pending "should update version with each update. TODO when versioning implemented"
      
      end
   end


   describe "POST 'create'" do

      describe "success" do
         before(:each) do
            @user = Factory(:user)
            @project = Factory(:project)
            @user.projects << @project
            @changeset = Factory(:changeset)
            test_sign_in(@user)

            @attr = {
               :osm_id        => 112,
               :osm_type      => "node",
               :changeset_id  => @changeset.id
            }

            @form_attrs = @attr.merge({:tags_attributes => {
               "0"=>{"key"=>"hot:simple:name", "value"=>"aa" }, "1" => {"key"=>"BB", "value"=>"bb"},
               "2"=>{"key"=>"hot:simple:mobile", "value"=>"cc" }, "3" => {"key"=>"DD", "value"=>"dd"}
               }})
         end

         it "should redirect to osm_shadow_path" do
            post :create, :osm_shadow => @form_attrs
            response.should redirect_to(assigns(:osm_shadow))
         end


         it "should create a osm_shadow" do
            lambda do
               post :create, :osm_shadow => @form_attrs
            end.should change(OsmShadow, :count).by(1)
         end

         it "should create tags for the project the user is allowed on" do
            lambda do
               post :create, :osm_shadow => @form_attrs
            end.should change(Tag, :count).by(2)
            new_shadow = assigns(:osm_shadow)
            new_shadow.tags.count.should eql 2
            name_tag = new_shadow.tags.find_by_key("hot:simple:name")
            name_tag.value.should eql "aa"
         end
         

         it "should create osm_shadow without tags" do
            post :create, :osm_shadow => @attr
            new_shadow = assigns(:osm_shadow)
            
            new_shadow.tags.count.should eql 0
            response.should redirect_to(osm_shadow_path(assigns(:osm_shadow)))
         end


      end

   end
   
   describe "admin user" do
      before(:each) do
         @osm_shadow = Factory(:osm_shadow)
         @user = Factory(:user)
         @user.toggle(:admin)
         @project = Factory(:project)
         @user.projects << @project
         test_sign_in(@user)
      end
      
         
         it "should redirect to list view" do 
            delete :destroy, :id => @osm_shadow.id
            response.should redirect_to(list_shadows_url(:osm_type => @osm_shadow.osm_type, :osm_id=>@osm_shadow.osm_id))
         end
         
         it "should reduce the osm shadow count by one" do
            lambda {
             delete :destroy, :id => @osm_shadow.id
            }.should change {OsmShadow.count}.from(1).to(0)
         end
      
   end

   describe "inactive user" do
      before(:each) do
         @osm_shadow = Factory(:osm_shadow)
         @user = Factory(:user, :active => false)
         #test_sign_in(@user)
      end

      describe "GET 'edit'" do
         it "should redirect to signin" do
            get :edit, :id => @osm_shadow.id
            response.should redirect_to(signin_path)
         end
      end
      
     describe "DELETE 'destroy'" do
         it "should redirect to signin" do
            delete :destroy, :id => @osm_shadow.id
            response.should redirect_to(signin_path)
         end
      end
      
   end

  describe "a user with no projects" do
   before(:each) do
         @osm_shadow = Factory(:osm_shadow)
         @user = Factory(:user)
         test_sign_in(@user)
      end

     describe "GET 'show'" do
         it "should redirect to home" do
            get :show, :id => @osm_shadow.id
            response.should redirect_to(home_path)
         end
      end

      describe "GET 'edit'" do
         it "should redirect to home" do
            get :edit, :id => @osm_shadow.id
            response.should redirect_to(home_path)
         end
      end

     describe "DELETE 'destroy'" do
         it "should redirect to home" do
            delete :destroy, :id => @osm_shadow.id
            response.should redirect_to(home_path)
         end
      end
  end

  describe "a user with only one project" do
     before(:each) do
         @osm_shadow = Factory(:osm_shadow)
         @user = Factory(:user)

         @normal_project = Factory(:project)
         @forbidden_project = Factory(:project, :name=>"forbidden",
           :tags_definition => [{ :tag => 'forbidden_key', :type => 'text',:en => "Name" }].to_json)
         @project = Factory(:project, :name=>"another",
           :tags_definition => [{ :tag => 'hot:simple:name', :type => 'text',:en => "Name" }].to_json)
         @user.projects << @project
         @forbidden_tag = Factory(:tag, :osm_shadow => @osm_shadow, :key =>"forbidden_key", :value => "cats and dogs")
         @tag = Factory(:tag, :osm_shadow => @osm_shadow, :key =>"hot:simple:name", :value => "simple name")
         test_sign_in(@user)

         get :show, :id => @osm_shadow.id
      end

      describe "GET 'show'" do
         it "should redirect to home" do
            response.should be_success
         end
         
         it "should show the keys of projects it belongs to" do
            response.should have_selector("td", :content => @tag.key)
            response.should have_selector("td", :content => @tag.value)
         end

        it "should not show the keys of projects it does not belong to" do
            response.should_not have_selector("td", :content => @forbidden_tag.key)
            response.should_not have_selector("td", :content => @forbidden_tag.value)
         end
      end
  end


end
