module DoorMat
  class SignUp

    include ActiveModel::Model

    attr_accessor :email, :password, :password_confirmation

    validates_format_of :email, with: DoorMat::Regex.simple_email
    validates :password, length: { minimum: 1 }
    validates :password, confirmation: true

    def add_generic_error_msg
      self.errors[:base] << I18n.t("door_mat.sign_up.failed")
    end

  end
end
