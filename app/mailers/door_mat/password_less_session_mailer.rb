module DoorMat
  class PasswordLessSessionMailer < ActionMailer::Base
    default from: DoorMat.configuration.mailer_from_address

    def send_token(parameters)
      @parameters = parameters

      mail to: @parameters[:address], subject: (@parameters[:subject] || I18n.t("door_mat.password_less_session_mailer.send_token.subject"))
    end

  end
end
