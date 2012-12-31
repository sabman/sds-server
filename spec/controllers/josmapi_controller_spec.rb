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
            @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.password
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
         @t1 = Factory(:tag, :osm_shadow => @shadow, :value => "cat")
         @t2 = Factory(:tag, :osm_shadow => @shadow, :value => "dog")
         
         #these have same osm_id as @shadow
         @shadow_dupe = Factory(:osm_shadow)
         @t3 = Factory(:tag, :osm_shadow => @shadow_dupe, :value => "duped tag, canary")
         
         @shadow_dupe2 = Factory(:osm_shadow)
         @t4 = Factory(:tag, :osm_shadow => @shadow_dupe2, :value => "duped tag, eagle")
         
         #same as shadow, but no tags 
         @shadow_empty = Factory(:osm_shadow)
         
         #different osm id
         @shadow2 = Factory(:osm_shadow, :osm_id => 333)
         @t5 = Factory(:tag, :osm_shadow => @shadow2, :value => "goldfish")
         
         #different type and id
         @shadow3 = Factory(:osm_shadow, :osm_type => "node", :osm_id => 555)
         @t6 = Factory(:tag, :osm_shadow => @shadow3, :value => "tree")
      end
     
      describe "success" do
         before(:each) do
            @user = Factory(:user)
            @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.password
         end

         it "should find the right action" do
            request.env['HTTP_AUTHORIZATION'] = @credentials
            post :collectshadows, { :ways => '123,333', :relations => '444'}
            response.should be_success
         end
         
      end
      
      describe "With multiple records" do
         before(:each) do
            @user = Factory(:user)
            @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.password
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
 
            returned_tags.should_not include({'key' => "highway", 'value' => "duped tag, canary"})
            returned_tags.should_not include({'key' => "highway", 'value' => "duped tag, eagle"})
            returned_tags.should include({'key' => "highway", 'value' => "dog"})
            returned_tags.should have(3).items  
               
         end
         
  
      end

   end


   describe "POST 'createshadows update" do
      before(:each) do
         @shadow = Factory(:osm_shadow)
         @t1 = Factory(:tag, :osm_shadow => @shadow, :value => "cat")
         @t2 = Factory(:tag, :osm_shadow => @shadow, :value => "dog")
         
         #these have same osm_id as @shadow
         @shadow_dupe = Factory(:osm_shadow)
         @t3 = Factory(:tag, :osm_shadow => @shadow_dupe, :value => "duped tag, canary")
         
         @shadow_dupe2 = Factory(:osm_shadow)
         @t3 = Factory(:tag, :osm_shadow => @shadow_dupe2, :value => "duped tag, eagle")
         
         #different osm id
         @shadow2 = Factory(:osm_shadow, :osm_id => 333)
         @t3 = Factory(:tag, :osm_shadow => @shadow2, :value => "goldfish")
         
         
         @user = Factory(:user)
         @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.password
         @xml_with_new_osm_id = '<xml><osm_sds><osm_shadow osm_id="9999" osm_type="way"><tag k="new_tag" v="new_value"/></osm_shadow></osm_sds></xml>'
         @xml_with_new_tag = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="abc" v="new value"/></osm_shadow></osm_sds></xml>'
         @xml_with_updated_tag = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="highway" v="elephant"/><tag k="abc" v="new value"/></osm_shadow></osm_sds></xml>'
         
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
         new_osm_shadow.tags.first.key.should == "new_tag" 
         new_osm_shadow.tags.first.value.should == "new_value" 
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
         tag_value = @shadow.tags.find_by_key("highway").value

         request.stub!(:raw_post).and_return(@xml_with_updated_tag)
         request.env['HTTP_AUTHORIZATION'] = @credentials
         post :createshadows
         
         updated_tag_value = @shadow.tags.find_by_key("highway").value
         
         tag_value.should_not eql updated_tag_value
         updated_tag_value.should eql "elephant"
      end
   
   
   end

   describe "POST 'createshadows'" do

      describe "success" do
         before(:each) do
            @user = Factory(:user)
            @credentials = ActionController::HttpAuthentication::Basic.encode_credentials @user.email, @user.password
            @xml = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="abc" v="schnee"/></osm_shadow></osm_sds></xml>'
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

         it "should create a tag" do
            lambda do
               request.stub!(:raw_post).and_return(@xml)
               request.env['HTTP_AUTHORIZATION'] = @credentials
               post :createshadows
            end.should change(Tag, :count).by(1)
         end
      end

      describe "failure" do
         it "should deny access to unauthorized users" do
            xml = '<xml><osm_sds><osm_shadow osm_id="123" osm_type="way"><tag k="abc" v="schnee"/></osm_shadow></osm_sds></xml>'
            request.stub!(:raw_post).and_return(xml)
            post :createshadows
            response.should_not be_success
         end
      end
   end

end
