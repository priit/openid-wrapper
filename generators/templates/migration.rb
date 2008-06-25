class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :openid_identifier, :null => false
      t.timestamps

      # openid simple registration all fields
      t.string :dob, :language, :nickname, :timezone, :country
      t.string :fullname, :gender, :email
      t.integer :postcode
    end
    
    create_table :openid_associations, :force => true do |t|
      t.binary :server_url, :issued
      t.string :handle, :assoc_type
      t.integer :issued, :lifetime
    end

    create_table :openid_nonces, :force => true do |t|
      t.string :server_url, :null => false
      t.string :timestamp, :null => false
      t.string :salt, :null => false
    end
  end

  def self.down
    drop_table :users
    drop_table :openid_associations
    drop_table :openid_nonces
  end
end
