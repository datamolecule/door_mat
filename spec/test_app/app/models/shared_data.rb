class SharedData < ActiveRecord::Base
  has_many :shared_keys
  has_many :actor, class_name: 'DoorMat::Actor', :through => :shared_keys
end
