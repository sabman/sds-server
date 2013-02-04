require 'spec_helper'

describe TagsController do
  render_views

  before(:all) do
    @user = Factory(:user)
    @changeset = Factory(:changeset)
    @project = Factory(:project)
    @user.projects << @project

    @forbidden_project = Factory(:project, :name=>"forbidden project",
      :tags_definition => [{ :tag => 'akey', :type => 'text', :en => "a key"}].to_json)

    @shadow = Factory(:osm_shadow)
    @tag1 = Factory(:tag, :osm_shadow => @shadow, :key=>"hot:simple:name", :value => "cat")
    
    @tag2 = Factory(:tag, :osm_shadow => @shadow, :key=>"hot:simple:name", :value => "robot")
    @tag2.value = "machine"
    @tag2.save
    @tag2.value = "android"
    @tag2.save

    @forbidden_tag = Factory(:tag, :osm_shadow => @shadow, :key=>"akey", :value => "forbade")
    @forbidden_tag.value = "nope"
    @forbidden_tag.save
    @forbidden_tag.value = "nuh uh"
    @forbidden_tag.save
  end

  with_versioning do
    describe "GET 'show'" do
      
      before(:each) do
        test_sign_in(@user)
      end

      it "should show the tag" do
        get :show, :id => @tag1.id
        response.should be_success
        assigns(:tag).should == @tag1
      end

      it "should show versions" do
        get :show, :id => @tag2.id
        response.should be_success
        response.should have_selector("td", :content => "robot")
        response.should have_selector("td", :content => "machine")
        response.should have_selector("td", :content => "android")
        response.should have_selector('input', :value => "Revert")
      end

      it "should not show a forbidden tag" do
        get :show, :id => @forbidden_tag.id
        response.should_not be_success
        response.should redirect_to(home_path)
      end

    end

    describe "PUT 'revert'" do
      before(:each) do
        test_sign_in(@user)
      end

      it "show revert an allowed tag" do
        versions = @tag2.versions
        machine_version = versions[2]
        put :revert, :id => machine_version.id
        response.should redirect_to(tag_path(@tag2))
        reverted_tag = Tag.find(@tag2.id)
        reverted_tag.value.should eql machine_version.reify.value
      end

      it "should not revert a forbidden tag" do
        versions = @forbidden_tag.versions
        nope_version = versions[2] # nope
        put :revert, :id => nope_version.id
        response.should_not be_success
        response.should redirect_to(home_path)
        tag = Tag.find(@forbidden_tag)
        tag.value.should eql "nuh uh"
      end
      
    end

  end

end