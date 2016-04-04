module DoorMat
  class ActivityMailer < ActionMailer::Base
    default from: DoorMat.configuration.mailer_from_address

    def confirm_email(parameters)
      @parameters = parameters

      mail to: @parameters[:address], subject: (@parameters[:subject] || I18n.t("door_mat.activity_mailer.confirm_email.subject"))
    end

    def reset_password(parameters)
      @parameters = parameters

      mail to: @parameters[:address], subject: (@parameters[:subject] || I18n.t("door_mat.activity_mailer.reset_password.subject"))
    end

  end
end
