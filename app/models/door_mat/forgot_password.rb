module DoorMat
  class ForgotPassword

    include ActiveModel::Model

    attr_accessor :email, :password, :password_confirmation, :token, :recovery_key

    validates_format_of :email, with: DoorMat::Regex.simple_email
    validates :password, length: { minimum: 1 }
    validates :password, confirmation: true
  end
end
