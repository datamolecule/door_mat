require 'door_mat'
require 'door_mat/test_helper'

namespace :door_mat do

  desc "Create an admin actor in the system, useful if you need to share data between a user and the system - specify admin_account_email and admin_account_pwd in your rails secret file using environment variables."
  task :create_admin_actor => :environment do

    if DoorMat::Email.matching(Rails.application.secrets.admin_account_email).count == 0
      DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(
          Rails.application.secrets.admin_account_email,
          Rails.application.secrets.admin_account_pwd
      )
      puts "SUCCESS: #{Rails.application.secrets.admin_account_email} is now defined in the database"
    else
      puts "ERROR: #{Rails.application.secrets.admin_account_email} is already defined in the database"
    end

  end

  desc "Environment cleanup before building gem"
  task :cleanup => :environment do
    list = Dir['spec/test_app/db/*sqlite3', 'spec/test_app/db/schema.rb', 'spec/test_app/tmp', 'spec/test_app/log/*log']
    list.each do |file|
      FileUtils.remove_entry_secure(file)
      puts file
    end
    puts "Ready to run: rake build"
  end

end
