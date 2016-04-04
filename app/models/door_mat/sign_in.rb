module DoorMat
  class SignIn

    include ActiveModel::Model

    attr_accessor :email, :password, :is_public, :remember_me

    validates_format_of :email, with: DoorMat::Regex.simple_email
    validates :password, length: { minimum: 1 }

    def initialize(attributes={})
      super

      @is_public = '1' if @is_public.nil?
      @remember_me = '0' if @remember_me.nil?
    end

    def is_public?
      '1' == @is_public
    end

    def remember_me?
      '1' == @remember_me
    end

    def add_generic_error_msg
      self.errors[:base] << I18n.t("door_mat.sign_in.failed")
    end

  end
end
