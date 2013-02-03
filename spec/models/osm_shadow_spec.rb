require 'spec_helper'

describe OsmShadow do


   before(:each) do
      @changeset = Factory(:changeset)
      @attr = {
         :osm_id => 123,
         :osm_type => "node"
      }
   end

   it "should create a new instance given valid attributes" do
      @changeset.osm_shadows.create!(@attr)
   end

   describe "changeset associations" do
      before(:each) do
         @osm_shadow = @changeset.osm_shadows.create(@attr)
      end

      it "should have a changeset attribute" do
         @osm_shadow.should respond_to(:changeset)
      end

      it "should have the right associated changeset" do
         @osm_shadow.changeset_id.should == @changeset.id
         @osm_shadow.changeset.should == @changeset
      end
   end

   describe "osm_shadow associations" do
      before(:each) do
         @os1 = Factory(:osm_shadow, :changeset => @changeset, :created_at => 1.day.ago)
         @os2 = Factory(:osm_shadow, :changeset => @changeset, :created_at => 1.hour.ago)
      end

      it "should have a osm_shadows attribute" do
         @changeset.should respond_to(:osm_shadows)
      end
   end

   describe "validations" do

      it "should require a changeset id" do
         OsmShadow.new(@attr).should_not be_valid
         OsmShadow.new(@attr.merge(:changeset_id => 1)).should be_valid
      end

      it "should require an osm_id" do
         @changeset.osm_shadows.build(@attr).should be_valid
         @changeset.osm_shadows.build(@attr.merge(:osm_id => nil)).should_not be_valid
      end

      it "should have an numeric osm_id" do
         @changeset.osm_shadows.build(@attr.merge(:osm_id => 333)).should be_valid
         @changeset.osm_shadows.build(@attr.merge(:osm_id => "foo")).should_not be_valid
      end

      it "should have a valid osm_type (node, way or relation)" do
         @changeset.osm_shadows.build(@attr.merge(:osm_type => "node")).should be_valid
         @changeset.osm_shadows.build(@attr.merge(:osm_type => "way")).should be_valid
         @changeset.osm_shadows.build(@attr.merge(:osm_type => "relation")).should be_valid
         @changeset.osm_shadows.build(@attr.merge(:osm_type => "foo")).should_not be_valid
         @changeset.osm_shadows.build(@attr.merge(:osm_type => nil)).should_not be_valid
      end



   end





   it "should find osm_shadow object from current tables" do
      pending "todo when versioning is in place"
      #shadow  = @changeset.osm_shadows.new({:osm_id => 345, :osm_type => 'way'})
      #shadow.tags << Tag.new({ :key => "name", :value => "blub"})
      #shadow.save_with_current
      #blub = OsmShadow.find_current("way", 345)
      #blub.should be_a_kind_of(CurrentOsmShadow)
   end

end
