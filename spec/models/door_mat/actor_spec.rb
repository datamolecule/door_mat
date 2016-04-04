require 'spec_helper'

module DoorMat
  describe Actor do
    let(:user1) { {email: 'user1@example.com', password: 'password_user1'} }
    let(:user2) { {email: 'user2@example.com', password: 'password_user2'} }

    describe '#can_add_email?' do

      it 'can not add more emails than max_email_count_per_actor' do
        actor1, _ = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user1[:email], user1[:password])
        DoorMat::configuration.max_email_count_per_actor = 1
        email = DoorMat::Email.for('user@example.com')
        expect(actor1.can_add_email?(email)).to be false
        expect(email.errors.count).to eq(1)
        expect(email.errors.full_messages.join('')).to match(/maximum number of email per account was reached/)
        DoorMat::configuration.max_email_count_per_actor = 2
      end

      it 'can not add the same email twice' do
        actor1, _ = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user1[:email], user1[:password])
        DoorMat::configuration.max_email_count_per_actor = 2
        email = DoorMat::Email.for(user1[:email])

        expect(actor1.can_add_email?(email)).to be false
        expect(email.errors.count).to eq(1)
        expect(email.errors.full_messages.join('')).to match(/already associated/)
      end

      it 'can add a new email' do
        actor1, _ = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user1[:email], user1[:password])
        DoorMat::configuration.max_email_count_per_actor = 2
        email = DoorMat::Email.for('user@example.com')

        expect(actor1.can_add_email?(email)).to be true
      end
    end

    it "can share a secret with an other actor" do
      message = "some message"
      actor1, session1 = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user1[:email], user1[:password])
      actor2, session2 = DoorMat::TestHelper.create_signed_in_actor_with_confirmed_email_address(user2[:email], user2[:password])

      share = actor1.share_with(actor2, message)

      RequestStore.store[:current_session] = session1
      messages = DoorMat::Crypto.decrypt_shared(share[:secrets], actor1.decrypt_shared_key(share[:key], session1))
      expect(message).to eq(messages.first)

      messages = DoorMat::Crypto.decrypt_shared(share[:secrets], actor2.decrypt_shared_key(share[:other_key], session2))
      expect(message).to eq(messages.first)
    end

  end
end

