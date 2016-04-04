require 'spec_helper'

module DoorMat
  describe Session do
    let(:user1) { {email: 'user1@example.com', password: 'password_user1'} }
    let(:user2) { {email: 'user2@example.com', password: 'password_user2'} }

    it "initialize a session with an actor and password" do
      actor = DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user1[:email], user1[:password])

      session = DoorMat::Session.new
      session.ip = "request.remote_ip"
      session.agent = "request.user_agent"
      session.initialize_with(actor, user1[:password])
      expect(session.valid?).to be true
    end

    it "fail to initialize a session if an error is raised" do
      actor = DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(user1[:email], user1[:password])

      allow(DoorMat::Crypto::PasswordHash).to receive(:pbkdf2_hash).and_raise(StandardError)

      session = DoorMat::Session.new
      session.ip = "request.remote_ip"
      session.agent = "request.user_agent"
      session.initialize_with(actor, 'wrong_password')
      expect(session.valid?).to be false
    end

    it 'can add an authenticated sub session' do
      _, session1 = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user1[:email], user1[:password])
      _, session2 = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user2[:email], user2[:password])
      invalid_session = DoorMat::Session.new

      RequestStore.store[:current_session] = session2
      expect(session1.append_sub_session(session2)).to be false

      RequestStore.store[:current_session] = session1
      expect(session1.append_sub_session(invalid_session)).to be false

      expect(session1.append_sub_session(session2)).to be true

      expect(session1.append_sub_session(session2)).to be true
    end

    it 'can encrypt and decrypt messages' do
        message = "some message"
        _, session1 = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user1[:email], user1[:password])

        ciphertext = session1.encrypt(message)
        expect(session1.decrypt(ciphertext)).to eq message

        allow(DoorMat::Crypto::SymmetricStore).to receive(:decrypt).and_raise(OpenSSL::Cipher::CipherError)
        expect(session1.decrypt(ciphertext)).to be_nil
    end

    it 'can encrypt and decrypt the recovery key' do
      actor1, session1 = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user1[:email], user1[:password])

      recovery_key = session1.package_recovery_key
      expect(session1.recovery_key_restore(actor1, recovery_key)).to be true

      allow(DoorMat::Crypto::SymmetricStore).to receive(:decrypt).and_raise(OpenSSL::Cipher::CipherError)
      expect(session1.recovery_key_restore(actor1, recovery_key)).to be false
    end

  end
end

