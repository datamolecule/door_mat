require 'spec_helper'

module DoorMat
  describe "DoorMat attr_store" do
    it 'must belong to an Actor' do
      allow(ActiveRecord::Base).to receive(:table_exists?).and_return(true)

      expect {
        class SomeRandomClassA < ActiveRecord::Base
          include DoorMat::AttrSymmetricStore

          def self.columns()
            @columns ||= [];
          end

          def self.column(name, sql_type = nil, default = nil, null = true)
            columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
          end

          column :name, :string

          attr_symmetric_store :name

        end
      }.to raise_error(ActiveRecord::ActiveRecordError, /attr_symmetric_store records must belong to a DoorMat::Actor/)
    end
    it 'must be a string or text field' do
      allow(ActiveRecord::Base).to receive(:table_exists?).and_return(true)

      expect {
        class SomeRandomClassB < ActiveRecord::Base
          include DoorMat::AttrSymmetricStore

          def self.columns()
            @columns ||= [];
          end

          def self.column(name, sql_type = nil, default = nil, null = true)
            columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
          end

          column :actor_id, :int
          column :counter, :int

          belongs_to :actor, class_name: 'DoorMat::Actor'
          attr_symmetric_store :counter

        end
      }.to raise_error(ActiveRecord::ActiveRecordError, /attr_symmetric_store only support text and string column types/)
    end
    it "Encrypt and decrypt data when current session is valid" do
      actor, session = TestHelper::create_signed_in_actor_with_confirmed_email_address
      details = UserDetail.new
      details.name = "Secret User Name"
      actor.user_detail = details
      actor.save!

      confirm_details = UserDetail.all.first
      expect(details.name).to eq(confirm_details.name)
      expect(details.__id__).not_to eq(confirm_details.__id__)

      encrypted_details_name = ''
      DoorMat::Crypto.skip_crypto_callback { encrypted_details_name = UserDetail.all.first.name }
      expect(encrypted_details_name).not_to eq("Secret User Name")
      expect(encrypted_details_name).not_to eq(UserDetail.all.first.name)
      expect(encrypted_details_name).not_to eq('')
    end
    it "Respects string encoding" do
      actor, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address
      details = UserDetail.new
      details.name = "Secret User Name"
      encoding_before = details.name.encoding.name
      actor.user_detail = details
      actor.save!

      confirm_details = UserDetail.all.first
      encoding_after = confirm_details.name.encoding.name
      expect(details.name).to eq(confirm_details.name)
      expect(details.__id__).not_to eq(confirm_details.__id__)
      expect(encoding_before).to eq(encoding_after)
    end
  end
  describe "DoorMat attr_asymmetric_store" do

    it 'must belong to an Actor' do
      allow(ActiveRecord::Base).to receive(:table_exists?).and_return(true)

      expect {
        class SomeSharedKeyA < ActiveRecord::Base
          include DoorMat::AttrAsymmetricStore

            def self.columns()
              @columns ||= [];
            end

            def self.column(name, sql_type = nil, default = nil, null = true)
              columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
            end

            column :key, :string


          attr_asymmetric_store :key
        end

      }.to raise_error(ActiveRecord::ActiveRecordError, /attr_asymmetric_store records must belong to a DoorMat::Actor/)
    end
    it 'must be a string or text field' do
      allow(ActiveRecord::Base).to receive(:table_exists?).and_return(true)

      expect {
        class SomeSharedKeyB < ActiveRecord::Base
          include DoorMat::AttrAsymmetricStore

          def self.columns()
            @columns ||= [];
          end

          def self.column(name, sql_type = nil, default = nil, null = true)
            columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
          end

          column :actor_id, :int
          column :key, :int

          belongs_to :actor, class_name: 'DoorMat::Actor'
          attr_asymmetric_store :key

        end
      }.to raise_error(ActiveRecord::ActiveRecordError, /attr_asymmetric_store only support text and string column types/)
    end
    it "Encrypt and decrypt data when current session is valid" do

      alice = TestHelper::create_signed_up_actor_with_confirmed_email_address("alice@example.com", 'pwd_alice_1')
      bob, _ = TestHelper::create_signed_in_actor_with_confirmed_email_address("bob@example.com", 'pwd_bob_1')

      random_key = DoorMat::Crypto::SymmetricStore.random_key

      original_document = "fyi document"
      original_exp_date = 2.days.from_now.strftime("%Y%m%d")
      document, exp_date = DoorMat::Crypto.encrypt_shared([original_document, original_exp_date], random_key)
      shared_data = SharedData.new
      shared_data.document = document
      shared_data.expiration_date = exp_date

      shared_key_alice = SharedKey.new
      shared_key_alice.actor = alice
      shared_key_alice.shared_data = shared_data
      shared_key_alice.key = random_key

      shared_key_bob = SharedKey.new
      shared_key_bob.actor = bob
      shared_key_bob.shared_data = shared_data
      shared_key_bob.key = random_key

      shared_key_alice.save!
      shared_key_bob.save!

      expect(SharedKey.all.first.key).not_to eq(SharedKey.all.last.key)

      Session.clear_current_session
      alice, _ = TestHelper::sign_in_existing_actor("alice@example.com", 'pwd_alice_1')

      shared_key = alice.shared_keys.first
      expect(shared_key.key).to eq(random_key)
      document, exp_date = DoorMat::Crypto.decrypt_shared([shared_key.shared_data.document, shared_key.shared_data.expiration_date], shared_key.key)
      expect(original_document).to eq(document)
      expect(original_exp_date).to eq(exp_date)

      Session.clear_current_session
      bob, _ = TestHelper::sign_in_existing_actor("bob@example.com", 'pwd_bob_1')
      new_password = "new_password!"
      DoorMat::Process::ActorPasswordChange.with(bob, new_password, 'pwd_bob_1')

      Session.clear_current_session

      bob, _ = TestHelper::sign_in_existing_actor("bob@example.com", new_password)
      shared_key = bob.shared_keys.first
      expect(shared_key.key).to eq(random_key)
      document, exp_date = DoorMat::Crypto.decrypt_shared([shared_key.shared_data.document, shared_key.shared_data.expiration_date], shared_key.key)
      expect(original_document).to eq(document)
      expect(original_exp_date).to eq(exp_date)

      expect(bob.id).not_to eq(alice.id)

    end


    it "leaves the attribute as is if the actor is not set" do
      alice = TestHelper::create_signed_up_actor_with_confirmed_email_address("alice@example.com")

      plain_text_message = 'Anybody can read this'

      first_shared_key = SharedKey.new
      first_shared_key.key = plain_text_message
      first_shared_key.save
      last_shared_key = SharedKey.new
      last_shared_key.actor = alice
      last_shared_key.key = plain_text_message
      last_shared_key.save

      shared_key_w_no_actor = nil
      shared_key_w_actor = nil
      DoorMat::Crypto.skip_crypto_callback { shared_key_w_no_actor = SharedKey.first }
      DoorMat::Crypto.skip_crypto_callback { shared_key_w_actor = SharedKey.last }

      expect(shared_key_w_no_actor.key).to eq(plain_text_message)
      expect(shared_key_w_no_actor.key).not_to eq(shared_key_w_actor.key)
      expect(shared_key_w_no_actor.id).not_to eq(shared_key_w_actor.id)
    end

    it "leaves the attribute as is if blank" do
      alice = TestHelper::create_signed_up_actor_with_confirmed_email_address("alice@example.com")

      blank_text_message = ''

      first_shared_key = SharedKey.new
      first_shared_key.key = blank_text_message
      first_shared_key.save
      last_shared_key = SharedKey.new
      last_shared_key.actor = alice
      last_shared_key.key = blank_text_message
      last_shared_key.save

      shared_key_w_no_actor = nil
      shared_key_w_actor = nil
      DoorMat::Crypto.skip_crypto_callback { shared_key_w_no_actor = SharedKey.first }
      DoorMat::Crypto.skip_crypto_callback { shared_key_w_actor = SharedKey.last }

      expect(shared_key_w_no_actor.key.blank?).to be true
      expect(shared_key_w_actor.key.blank?).to be true
      expect(shared_key_w_no_actor.id).not_to eq(shared_key_w_actor.id)
    end


  end
end
