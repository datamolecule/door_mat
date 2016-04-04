require 'spec_helper'

module DoorMat
  describe ActivityConfirmEmail do

    it 're-raise an error that occurs while sending the email' do
      controller = Object.new
      allow(controller).to receive(:confirm_email_url).and_return('some_url')
      allow(DoorMat::ActivityMailer).to receive(:confirm_email).and_raise(RuntimeError)
      actor = build(:actor)
      email = build(:email, id: 1, status: :not_confirmed)
      email.actor = actor

      expect{
        DoorMat::ActivityConfirmEmail.for(email, controller)
      }.to raise_error(RuntimeError)
    end

  end

  describe ActivityResetPassword do

    it 're-raise an error that occurs while sending the email' do
      controller = Object.new
      allow(controller).to receive(:choose_new_password_url).and_return('some_url')
      allow(DoorMat::ActivityMailer).to receive(:reset_password).and_raise(RuntimeError)
      actor = build(:actor)
      email = build(:email, id: 1, status: :not_confirmed)
      email.actor = actor

      expect{
        DoorMat::ActivityResetPassword.for(email, controller)
      }.to raise_error(RuntimeError)
    end

  end
end

