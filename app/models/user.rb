class User < ActiveRecord::Base
   attr_accessible :firstname, :lastname, :email, :plain_password, :project_id, :active, :admin, :memberships_attributes
   attr_accessor :plain_password
   
   has_many :changesets
   belongs_to :project #project_id TODO move to session
   has_many :memberships
   has_many :projects, :through => :memberships
   accepts_nested_attributes_for :memberships, :allow_destroy => true

   validates :firstname, :presence => true, :length => {:maximum => 64}
   validates :lastname,  :presence => true, :length => {:maximum => 64}
   validates :plain_password, :presence => true, :on => :create

   email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
   validates :email, 
      :presence => true, 
      :format => {:with => email_regex}, 
      :uniqueness => {:case_sensitive => false}

   validates :active, :inclusion => { :in => [true, false] }

   before_save :encrypt_password

   #workaround for rails bug with creating new children and new parent objects at same time (#1943)
   before_validation :initialize_memberships, :on => :create
   def initialize_memberships
      memberships.each { |t| t.user = self }
   end

   def self.authenticate(email, password)
      user = find_by_email(email)
      return nil if user.nil?
      return nil if (user.active? == false)
      if user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
         user
      else
         nil
      end
   end
   

   #returns the visible keys permitted to the user from it's projects
   def find_visible_tag_keys
      visible_tag_keys = []
      self.projects.map {|x| visible_tag_keys.concat(x.tag_keys)}

      visible_tag_keys
   end


   def encrypt_password
    if plain_password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(plain_password, password_salt)
    end
   end
   
private 
   def self.generate_password
      foo = (('A'..'Z').to_a << ('a'..'z').to_a << ('1'..'9').to_a ).flatten
      foo.delete_if {|x| x == "I" }
      foo.delete_if {|x| x == "l" }
      foo.delete_if {|x| x == "O" }
      bar = String.new
      10.times { bar << foo.shuffle[0] }
      
      return bar
   end   

end
