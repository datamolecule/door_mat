class SharedKey < ActiveRecord::Base
  include DoorMat::AttrAsymmetricStore

  belongs_to :actor, class_name: 'DoorMat::Actor'
  belongs_to :shared_data

  attr_asymmetric_store :key
end
