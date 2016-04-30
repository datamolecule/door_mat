$:.push File.expand_path('../lib', __FILE__)

require 'door_mat/version'

Gem::Specification.new do |s|
  s.name        = 'door_mat'
  s.version     = DoorMat::VERSION
  s.authors     = ['Luc Lussier']
  s.email       = ['luc.lussier@gmail.com']
  s.homepage    = 'https://github.com/datamolecule/door_mat'
  s.summary     = 'User authentication and data encryption'
  s.description = 'DoorMat is a Rails Engine that provides a solution for both user authentication and the encryption of user information. It aims to offer safe defaults so you can get going with what your website is really about.'
  s.license     = 'MIT'

  s.files = Dir['{app,bin,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md', '.rspec', 'door_mat.gemspec', 'Gemfile']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '~> 4.2'
  s.add_dependency 'bcrypt', '~> 3.1' #https://github.com/codahale/bcrypt-ruby
  s.add_dependency 'request_store', '~> 1.1'

  s.add_development_dependency 'sprockets', '2.12.4' # to prevent https://github.com/rails/rails/issues/19853
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'rspec-rails', '~> 3.4.2'
  s.add_development_dependency 'factory_girl_rails', '~> 4.4.1'
  s.add_development_dependency 'email_spec', '~> 2.0'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'show_me_the_cookies'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'better_errors'
  s.add_development_dependency 'binding_of_caller'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'codeclimate-test-reporter'
end
