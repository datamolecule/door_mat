class UserDetail < ActiveRecord::Base
  include DoorMat::AttrSymmetricStore

  belongs_to :actor, class_name: 'DoorMat::Actor'

  attr_symmetric_store :name
end
