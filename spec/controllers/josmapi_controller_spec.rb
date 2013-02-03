require 'spec_helper'

describe JosmapiController do


   describe "GET 'collectshadows'" do
      before(:each) do
         @shadow = Factory(:osm_shadow)
         @t1 = Factory(:tag, :osm_shadow => @shadow, :value => "cat")
         @t2 = Factory(:tag, :osm_shadow => @shadow, :value => "dog")
      end

      describe "success" do
         before(:each) do
            @user = Factory(:user)
            @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.plain_password
         end

         it "should find the right action" do
            request.env['HTTP_AUTHORIZATION'] = @credentials
            get :collectshadows, :ways => '123,333' ,:relations => '444' 
            response.should be_success
         end
      end

      describe "failure" do
         it "should deny access to unauthorized users" do
            get :collectshadows, :ways => '123,333' ,:relations => '444' 
            response.should_not be_success
         end

         it "should send status 401" do
            get :collectshadows, :ways => '123,333' ,:relations => '444' 
            response.code.should eq("401")
         end
      end

   end

   describe "POST 'collectshadows'" do
      before(:each) do
         @shadow = Factory(:osm_shadow)
         @t1 = Factory(:tag, :osm_shadow => @shadow, :key=> "hot:simple:name", :value => "cat")
         @t2 = Factory(:tag, :osm_shadow => @shadow, :key=> "hot:simple:name", :value => "dog")
         
         #these have same osm_id as @shadow
         @shadow_dupe = Factory(:osm_shadow)
         @t3 = Factory(:tag, :osm_shadow => @shadow_dupe, :key=> "hot:simple:name", :value => "duped tag, canary")
         
         @shadow_dupe2 = Factory(:osm_shadow)
         @t4 = Factory(:tag, :osm_shadow => @shadow_dupe2, :key=> "hot:simple:name", :value => "duped tag, eagle")
         
         #same as shadow, but no tags 
         @shadow_empty = Factory(:osm_shadow)
         
         #different osm id
         @shadow2 = Factory(:osm_shadow, :osm_id => 333)
         @t5 = Factory(:tag, :osm_shadow => @shadow2, :key=> "hot:simple:name", :value => "goldfish")
         
         #different type and id
         @shadow3 = Factory(:osm_shadow, :osm_type => "node", :osm_id => 555)
         @t6 = Factory(:tag, :osm_shadow => @shadow3, :key=> "hot:simple:name", :value => "tree")

         @user = Factory(:user)
         @project = Factory(:project)
         @user.projects << @project

         @forbidden_project = Factory(:project, :name=>"forbidden",
           :tags_definition => [{ :tag => 'forbidden_key', :type => 'text',:en => "Name" }].to_json)
         @forbidden_tag1 = Factory(:tag, :osm_shadow => @shadow, :key =>"forbidden_key", :value => "secret lizard king")
         @forbidden_tag2 = Factory(:tag, :osm_shadow => @shadow, :key =>"forbidden_key", :value => "secret furry animal")
         @forbidden_tag3 = Factory(:tag, :osm_shadow => @shadow2, :key =>"forbidden_key", :value => "secret lizard king")
         @forbidden_tag4 = Factory(:tag, :osm_shadow => @shadow2, :key =>"forbidden_key", :value => "secret lizard king")
      end
     
      describe "success" do
         before(:each) do
            @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.plain_password
         end

         it "should find the right action" do
            request.env['HTTP_AUTHORIZATION'] = @credentials
            post :collectshadows, { :ways => '123,333', :relations => '444'}
            response.should be_success
         end
         
      end

      describe "With multiple records" do
         before(:each) do
            @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.plain_password
            request.env['HTTP_AUTHORIZATION'] = @credentials
        end
         
         it "should just return types specified" do
            post :collectshadows, { :nodes => '555,333'}
            doc = XML::Parser.string(response.body).parse

            returned_types = []
            doc.find('//osm_sds/osm_shadow').each do |s| 
               returned_types << s['osm_type']
            end
            
            returned_types.should include("node")
            returned_types.should_not include("way", "relation")
         end
         
         it "should just return types specified " do
            post :collectshadows, { :ways => '333,123'}
            doc = XML::Parser.string(response.body).parse

            returned_types = []
            doc.find('//osm_sds/osm_shadow').each do |s| 
               returned_types << s['osm_type']
            end
            
            returned_types.should include("way")
            returned_types.should_not include("node", "relation")
         end
         
         #osm_id is a node
         it "should not return the wrong type" do
            post :collectshadows, { :ways => '555'}
            doc = XML::Parser.string(response.body).parse
            
            doc.find('//osm_sds/osm_shadow').length.should == 0
         end
              
         it "should return only the first record saved for each unique osm_id and osm_type osm_shadow" do
            #it should return one each for @shadow 123 and shadow 333
            post :collectshadows, { :ways => '123,333'}
            doc = XML::Parser.string(response.body).parse
            
            returned_ids = []
            returned_tags = []
            doc.find('//osm_sds/osm_shadow').each do |s| 
               returned_ids << s["osm_id"]
               s.find('tag').each do |t|
                  returned_tags << {'key' => t['k'], 'value' => t['v']} 
               end
            end
            
            returned_ids.should include("123","333")
            returned_ids.should have(2).items

            returned_tags.should_not include({'key' => "hot:simple:name", 'value' => "duped tag, canary"})
            returned_tags.should_not include({'key' => "hot:simple:name", 'value' => "duped tag, eagle"})
            returned_tags.should include({'key' => "hot:simple:name", 'value' => "dog"})
            returned_tags.should have(3).items 
         end

         it "should not return any forbidden project tags" do
            post :collectshadows, { :ways => '123,333'}
            doc = XML::Parser.string(response.body).parse

            returned_ids = []
            returned_tags = []
            doc.find('//osm_sds/osm_shadow').each do |s|
               returned_ids << s["osm_id"]
               s.find('tag').each do |t|
                  returned_tags << {'key' => t['k'], 'value' => t['v']}
               end
            end

            returned_ids.should include("123","333")
            returned_ids.should have(2).items
            returned_tags.should_not include({'key'=> @forbidden_tag1.key, 'value' => @forbidden_tag1.value})
            returned_tags.should_not include({'key'=> @forbidden_tag2.key, 'value' => @forbidden_tag2.value})
            returned_tags.should_not include({'key'=> @forbidden_tag3.key, 'value' => @forbidden_tag3.value})
            returned_tags.should_not include({'key'=> @forbidden_tag4.key, 'value' => @forbidden_tag4.value})
            returned_tags.should_not include({'key' => "hot:simple:name", 'value' => "duped tag, canary"})
            returned_tags.should_not include({'key' => "hot:simple:name", 'value' => "duped tag, eagle"})
            returned_tags.should include({'key' => "hot:simple:name", 'value' => "dog"})
            returned_tags.should have(3).items
         end        
  
      end

   end


   describe "POST 'createshadows update" do
      before(:each) do
         @shadow = Factory(:osm_shadow)
         @t1 = Factory(:tag, :osm_shadow => @shadow, :key=> "hot:simple:name", :value => "cat")
         @t2 = Factory(:tag, :osm_shadow => @shadow, :key=> "hot:simple:name", :value => "dog")
         
         #these have same osm_id as @shadow
         @shadow_dupe = Factory(:osm_shadow)
         @t3 = Factory(:tag, :osm_shadow => @shadow_dupe, :key=> "hot:simple:name", :value => "duped tag, canary")
         
         @shadow_dupe2 = Factory(:osm_shadow)
         @t3 = Factory(:tag, :osm_shadow => @shadow_dupe2, :key=> "hot:simple:name", :value => "duped tag, eagle")
         
         #different osm id
         @shadow2 = Factory(:osm_shadow, :osm_id => 333)
         @t3 = Factory(:tag, :osm_shadow => @shadow2, :key=> "hot:simple:name", :value => "goldfish")
         
         
         @user = Factory(:user)
         @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.plain_password

         @project = Factory(:project)
         @user.projects << @project

          @forbidden_project = Factory(:project, :name=>"forbidden",
           :tags_definition => [{ :tag => 'forbidden_key', :type => 'text',:en => "Name" }].to_json)
          @forbidden_tag1 = Factory(:tag, :osm_shadow => @shadow, :key =>"forbidden_key", :value => "secret lizard king")

         @xml_with_new_osm_id = '<xml><osm_sds><osm_shadow osm_id="9999" osm_type="way"><tag k="hot:simple:name" v="new_value"/></osm_shadow></osm_sds></xml>'
         @xml_with_new_tag = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="hot:simple:mobile" v="new value"/></osm_shadow></osm_sds></xml>'
         @xml_with_updated_tag = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="hot:simple:name" v="elephant"/><tag k="abc" v="new value"/></osm_shadow></osm_sds></xml>'
         @xml_with_updated_forbidden_tag = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="hot:simple:name" v="elephant"/><tag k="forbidden_key" v="new value"/></osm_shadow></osm_sds></xml>'
      end
      
      it "should create a new osm shadow if one does not exist already" do
         cnt = OsmShadow.where("osm_id = ? and osm_type = ?", 9999, "way").count
         
         request.stub!(:raw_post).and_return(@xml_with_new_osm_id)
         request.env['HTTP_AUTHORIZATION'] = @credentials
         post :createshadows
         
         cnt2 = OsmShadow.where("osm_id = ? and osm_type = ?", 9999, "way").count
         
         diff = cnt2 - cnt
         diff.should == 1
         cnt.should eql 0
         
         new_osm_shadow =  OsmShadow.where("osm_id = ? and osm_type = ?", 9999, "way")[0]
         new_osm_shadow.tags.first.key.should == "hot:simple:name"
         new_osm_shadow.tags.first.value.should == "new_value"
         new_osm_shadow.tags.first.versions.first.whodunnit.should == @user.id.to_s
      end
      
      it "should not create a new osm_shadow if one exists but create a new tag if none exists" do
         cnt = OsmShadow.where("osm_id = ? and osm_type = ?", 123, "way").count
         
         tag_count = OsmShadow.find_oldest("way", 123).tags.length
    
         request.stub!(:raw_post).and_return(@xml_with_new_tag)
         request.env['HTTP_AUTHORIZATION'] = @credentials
         post :createshadows
         
         tag_count2 = OsmShadow.find_oldest("way", 123).tags.length
         cnt2 = OsmShadow.where("osm_id = ? and osm_type = ?", 123, "way").count
         diff =  tag_count2 - tag_count
         
         cnt.should eql cnt2 #no new osm object created
         diff.should == 1 #a new tag created
      end
      
      it "should update an existing tag" do
         tag_value = @shadow.tags.find_by_key("hot:simple:name").value

         request.stub!(:raw_post).and_return(@xml_with_updated_tag)
         request.env['HTTP_AUTHORIZATION'] = @credentials
         post :createshadows
         
         updated_tag_value = @shadow.tags.find_by_key("hot:simple:name").value
         
         tag_value.should_not eql updated_tag_value
         updated_tag_value.should eql "elephant"
      end

      it "should not update a forbidden tag" do
         forbidden_tag_value = @shadow.tags.find_by_key("forbidden_key").value

         request.stub!(:raw_post).and_return(@xml_with_updated_forbidden_tag)
         request.env['HTTP_AUTHORIZATION'] = @credentials
         post :createshadows

         forbidden_tag_value = @shadow.tags.find_by_key("forbidden_key").value
         forbidden_tag_value.should_not eql "new value"
         forbidden_tag_value.should eql "secret lizard king"
      end
   
   
   end

   describe "POST 'createshadows'" do

      describe "success" do
         before(:each) do
            @user = Factory(:user)
            @project = Factory(:project)
            @user.projects << @project
            @forbidden_project = Factory(:project, :name=>"forbidden",
           :tags_definition => [{ :tag => 'forbidden_key', :type => 'text',:en => "Name" }].to_json)

            @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.plain_password
            @xml = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="hot:simple:name" v="schnee"/><tag k="forbidden_key" v="secret lizard king"/></osm_shadow></osm_sds></xml>'
         end

         it "should find the right action" do
            request.stub!(:raw_post).and_return(@xml)
            request.env['HTTP_AUTHORIZATION'] = @credentials
            post :createshadows
            response.should be_success
         end

         it "should find the param" do
            request.stub!(:raw_post).and_return(@xml)
            request.env['HTTP_AUTHORIZATION'] = @credentials
            post :createshadows
            request.raw_post.to_s.should == @xml
         end

         it "should create a changeset" do
            lambda do
               request.stub!(:raw_post).and_return(@xml)
               request.env['HTTP_AUTHORIZATION'] = @credentials
               post :createshadows
            end.should change(Changeset, :count).by(1)
         end

         it "should create a osm_shadow (check without lambda)" do
            cnt = OsmShadow.where("osm_id = ? and osm_type = ?", 123, "way").count

            request.stub!(:raw_post).and_return(@xml)
            request.env['HTTP_AUTHORIZATION'] = @credentials
            post :createshadows

            cnt2 = OsmShadow.where("osm_id = ? and osm_type = ?", 123, "way").count
            diff = cnt2 - cnt 
            diff.should == 1
         end

         it "should create a osm_shadow (check with lambda)" do
            lambda do
               request.stub!(:raw_post).and_return(@xml)
               request.env['HTTP_AUTHORIZATION'] = @credentials
               post :createshadows
            end.should change(OsmShadow, :count).by(1)
         end

         it "should create one tag" do
            lambda do
               request.stub!(:raw_post).and_return(@xml)
               request.env['HTTP_AUTHORIZATION'] = @credentials
               post :createshadows
            end.should change(Tag, :count).by(1)
         end

         it "should not save tag for any forbidden projects" do
            request.stub!(:raw_post).and_return(@xml)
            request.env['HTTP_AUTHORIZATION'] = @credentials
            post :createshadows
            created_tag = Tag.find_by_key("hot:simple:name")
            forbidden_tag = Tag.find_by_key("forbidden_key")
            Tag.count.should eql 1
            created_tag.should_not be_nil
            forbidden_tag.should be_nil
         end
      end

      describe "failure" do
         it "should deny access to unauthorized users" do
            xml = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="hot:simple:name" v="schnee"/></osm_shadow></osm_sds></xml>'
            request.stub!(:raw_post).and_return(xml)
            post :createshadows
            response.should_not be_success
         end
      end
   end

end
