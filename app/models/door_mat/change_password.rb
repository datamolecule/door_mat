module DoorMat
  class ChangePassword

    include ActiveModel::Model

    attr_accessor :old_password, :new_password, :new_password_confirmation

    validates :old_password, length: { minimum: 1 }
    validates :new_password, length: { minimum: 1 }
    validates :new_password, confirmation: true
  end
end
