namespace :db do
  desc "Create and add an admin account"
  task :create_admin , [:firstname, :lastname, :email, :password] => :environment do |t, args|
    args.with_defaults(:firstname => "Admin", :lastname => "Adminson", :email => "admin@example.com", :password => "changemeplease")

    admin = User.create!(:firstname => args.firstname,
                         :lastname => args.lastname,
                         :email => args.email,
                         :plain_password =>args.password)
    admin.save!
    admin.toggle!(:admin)
  end
end
