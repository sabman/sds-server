class RemovePasswordFromUsersAndEncrypt < ActiveRecord::Migration
  def up
    User.reset_column_information
    User.all.each do |u |
      unless u.password.blank?
        u.plain_password = u.password
        u.encrypt_password
        u.save
      end
    end
    User.reset_column_information
    remove_column :users, :password
  end

  def down
    add_column :users, :password, :string
  end
end
