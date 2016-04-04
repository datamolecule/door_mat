require 'spec_helper'

module DoorMat

  describe "DoorMat::Process::CreateNewAnonymousActor" do
    let(:user_alice) { {name: 'Alice', email: 'alice@example.com', password: 'k#dkvKfdj38g!'} }
    let(:user_bob) { {name: 'Bob', email: 'bob@example.com', password: 'je&*hK38,%D'} }

    it 'returns nil if an exception was raised while creating the anonymous actor' do
      anonymous_actor = DoorMat::Process::CreateNewAnonymousActor.owned_by(nil)
      expect(anonymous_actor).to be_nil
    end

    it 'allows Alice and Bob to share information' do
      TestHelper::create_signed_up_actor_with_confirmed_email_address(user_alice[:email], user_alice[:password])
      TestHelper::create_signed_up_actor_with_confirmed_email_address(user_bob[:email], user_bob[:password])

      alice, session = TestHelper::sign_in_existing_actor(user_alice[:email], user_alice[:password])
      anonymous_actor = DoorMat::Process::CreateNewAnonymousActor.owned_by(alice)

      # Reusing UserDetail here but this could be any model
      # with a field protected by an attr_symmetric_store
      anonymous_actor.user_detail = UserDetail.new
      anonymous_actor.user_detail.name = 'a message'
      anonymous_actor.user_detail.save!

      # At this point, an actor exist for Bob but he is not signed in
      membership = alice.memberships.first
      locked_actor_bob = DoorMat::Email.matching(user_bob[:email]).first.actor
      expect(membership.share_with!(locked_actor_bob)).to be_truthy

      TestHelper::sign_out(session)

      # Bob sign in and can access the message shared by Alice
      bob, session = TestHelper::sign_in_existing_actor(user_bob[:email], user_bob[:password])
      membership = bob.memberships.first
      expect(membership.load_sub_session).to be_truthy

      expect(membership.member_of.user_detail.name).to eq('a message')

      TestHelper::sign_out(session)
    end

  end

  describe "DoorMat::Process::ActorPasswordChange" do
    let(:user) { {name: 'Alice', email: 'user@example.com', password: 'k#dkvKfdj38g!', new_password: 'new_k#dkvKfdj38g!'} }

    it 'changes the password' do
      alice, session = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])

      user_detail = UserDetail.new
      user_detail.actor = alice
      user_detail.name = user[:name]
      user_detail.save

      (5..10).each do |i|
        g = Game.init_for_actor_and_doors(alice, i)
        g.save
      end
      game_first_state, game_last_state = Game.first.state, Game.last.state
      TestHelper::sign_out(session)

      alice, session = TestHelper::sign_in_existing_actor(user[:email], user[:password])

      expect(DoorMat::Process::ActorPasswordChange.with(alice, 'new_pwd_1', user[:password])).to be true
      TestHelper::sign_out(session)

      alice, session = TestHelper::sign_in_existing_actor(user[:email], 'new_pwd_1')

      expect(DoorMat::Process::ActorPasswordChange.with(alice, 'new_pwd_2', 'new_pwd_1')).to be true
      TestHelper::sign_out(session)

      _, _ = TestHelper::sign_in_existing_actor(user[:email], 'new_pwd_2')
      expect(Game.first.state).to eq(game_first_state)
      expect(Game.last.state).to eq(game_last_state)

      expect(UserDetail.first.name).to eq(user[:name])
    end

    it 'fails if the current session is not valid' do
      alice, session = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
      allow(session).to receive(:valid?).and_return(false)
      expect(DoorMat::Process::ActorPasswordChange.with(alice, 'new_pwd_1', user[:password])).to be false
    end

    it 're-raise exceptions other than a RecordNotFound' do
      alice, session = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])
      allow(session).to receive(:valid?).and_raise(RuntimeError)
      expect {
        DoorMat::Process::ActorPasswordChange.with(alice, 'new_pwd_1', user[:password])
      }.to raise_error(RuntimeError)
    end


    it 'changes the password' do
      alice, session = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])

      TestHelper::sign_out(session)

      alice_1, session_1 = TestHelper::sign_in_existing_actor(user[:email], user[:password])
      alice_2, session_2 = TestHelper::sign_in_existing_actor(user[:email], user[:password])
      expect(RequestStore.store[:current_session]).to eq(session_2)

      expect(DoorMat::Process::ActorPasswordChange.with(alice_2, 'new_pwd_1', user[:password])).to be true
      TestHelper::sign_out(session_2)

      RequestStore.store[:current_session] = session_1

      expect(DoorMat::Process::ActorPasswordChange.with(alice_1, 'new_pwd_2', user[:password])).to be false
      expect(DoorMat::Process::ActorPasswordChange.with(alice_1, 'new_pwd_2', nil)).to be false
    end

    it 'can still access data if password change fails' do
      alice, old_session = TestHelper::create_signed_in_actor_with_confirmed_email_address(user[:email], user[:password])

      user_detail = UserDetail.new
      user_detail.actor = alice
      user_detail.name = user[:name]
      user_detail.save

      encrypted_name_before = encrypted_name_after = ''
      DoorMat::Crypto.skip_crypto_callback { encrypted_name_before = UserDetail.all.first.name }
      allow(DoorMat::Crypto::SymmetricStore).to receive(:decrypt).and_raise(OpenSSL::Cipher::CipherError)
      expect(DoorMat::Process::ActorPasswordChange.with(alice, user[:new_password])).to be false
      DoorMat::Crypto.skip_crypto_callback { encrypted_name_after = UserDetail.all.first.name }
      expect(encrypted_name_before).to eq(encrypted_name_after)
      allow(DoorMat::Crypto::SymmetricStore).to receive(:decrypt).and_call_original

      _, new_session = TestHelper::sign_in_existing_actor(user[:email], user[:password])
      expect(old_session.id).not_to eq(new_session.id)
      expect(UserDetail.first.name).to eq(user[:name])
    end

    it 'fails the ActivityResetPassword if after_password_reset fails' do
      alice = TestHelper::create_signed_up_actor_with_confirmed_email_address(user[:email], user[:password])

      email = alice.emails.first
      token = SecureRandom.uuid

      activity = DoorMat::ActivityResetPassword.new
      activity.actor = email.actor
      activity.email = email
      activity.link_hash = DoorMat::ActivityResetPassword.hash_token(token)
      activity.started!

      recovery_key = StringIO.new 'the recovery key'
      forgot_password = DoorMat::ForgotPassword.new(email: user[:email],
                                                    password: user[:new_password],
                                                    password_confirmation: user[:new_password],
                                                    token: token,
                                                    recovery_key: recovery_key)

      allow(DoorMat::Process::ActorPasswordChange).to receive(:after_password_reset).and_return(false)
      expect(DoorMat::Process::ResetPassword.with(forgot_password)).to be false
    end

  end
end
