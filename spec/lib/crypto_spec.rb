require 'spec_helper'

module DoorMat
  describe "DoorMat Crypto Module" do
    it "Compare strings securely" do
      expect(DoorMat::Crypto::secure_compare('','asdf')).to be false
      expect(DoorMat::Crypto::secure_compare('asdf','jkfa')).to be false
      expect(DoorMat::Crypto::secure_compare('asdf','asdfa')).to be false
      expect(DoorMat::Crypto::secure_compare('asdf','asd')).to be false
      expect(DoorMat::Crypto::secure_compare('asdf','')).to be false
      expect(DoorMat::Crypto::secure_compare('asdfa','asdf')).to be false
      expect(DoorMat::Crypto::secure_compare('asd','asdf')).to be false

      expect(DoorMat::Crypto::secure_compare('asdf','asdf')).to be true
      expect(DoorMat::Crypto::secure_compare('','')).to be true
    end

    it "Hashes passwords" do
      expect(DoorMat::Crypto::secure_compare(
                 DoorMat::Crypto::PasswordHash.pbkdf2_salt(),
                 DoorMat::Crypto::PasswordHash.pbkdf2_salt())).to be false

      static_password = "MXaREjXsHsVQIEcjjPQX"
      random_password = OpenSSL::Random.random_bytes(200).scan(/\w/).join("")[0,20]
      static_salt = "MzI=--MTAwMDA=--arpM8+sl0mdOt+44eJNygxPI6UpD2bGFruymWMZ7jQg="
      random_salt = DoorMat::Crypto::PasswordHash.pbkdf2_salt()

      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.pbkdf2_hash(static_password, static_salt),
          DoorMat::Crypto::PasswordHash.pbkdf2_hash(static_password, random_salt))).to be false
      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.pbkdf2_hash(static_password, static_salt),
          DoorMat::Crypto::PasswordHash.pbkdf2_hash(random_password, static_salt))).to be false
      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.pbkdf2_hash(static_password, static_salt),
          DoorMat::Crypto::PasswordHash.pbkdf2_hash(static_password, static_salt))).to be true
      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.pbkdf2_hash(random_password, random_salt),
          DoorMat::Crypto::PasswordHash.pbkdf2_hash(random_password, random_salt))).to be true


      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.bcrypt_salt(),
          DoorMat::Crypto::PasswordHash.bcrypt_salt())).to be false

      static_password = "L7CXudYmS1ewNOPGYlHc"
      random_password = OpenSSL::Random.random_bytes(200).scan(/\w/).join("")[0,20]
      static_salt = "$2a$12$XJsQd7Z7vcef.9ksiYBxS."
      random_salt = DoorMat::Crypto::PasswordHash.bcrypt_salt()

      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.bcrypt_hash(static_password, static_salt),
          DoorMat::Crypto::PasswordHash.bcrypt_hash(static_password, random_salt))).to be false
      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.bcrypt_hash(static_password, static_salt),
          DoorMat::Crypto::PasswordHash.bcrypt_hash(random_password, static_salt))).to be false
      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.bcrypt_hash(static_password, static_salt),
          DoorMat::Crypto::PasswordHash.bcrypt_hash(static_password, static_salt))).to be true
      expect(DoorMat::Crypto::secure_compare(
          DoorMat::Crypto::PasswordHash.bcrypt_hash(random_password, random_salt),
          DoorMat::Crypto::PasswordHash.bcrypt_hash(random_password, random_salt))).to be true

    end

    it "Does Symmetric encryption" do
      message = "Be the change you want to see in the world. -Apparently not by Mahatma Gandhi"
      # http://www.nytimes.com/2011/08/30/opinion/falser-words-were-never-spoken.html?_r=0

      static_key = "8FBav54BeCoD+np2bQeg6zYFSQum/Yq6ftoBLYwdrHM="
      static_ciphertext = "VVRGLTg=--QgtPjJI61mvsfaB6Txls7A==--Z1c9L9h6ttZi7GgI--Pn+8P7lWazaiNLiy4rf+bc5o7zlnnOruesUc6lE65UDvasYfEGINIdUzvzpN9Z8wBySqXqH5nndLCW3L3xLTreflpIdDcP0Fqp9rWP0="

      h = DoorMat::Crypto::SymmetricStore.encrypt(message)
      random_key = h[:key]
      random_ciphertext = h[:ciphertext]

      assert_equal(message, DoorMat::Crypto::SymmetricStore.decrypt(static_ciphertext, static_key),
                   "decrypted ciphertext match original message")
      assert_equal(message, DoorMat::Crypto::SymmetricStore.decrypt(random_ciphertext, random_key),
                   "decrypted ciphertext match original message")

      encoding, auth_tag, iv, encrypted_string = static_ciphertext.split('--')
      expect {
        bad_key = "8FBbv54BeCoD+np2bQeg6zYFSQum/Yq6ftoBLYwdrHM="
        DoorMat::Crypto::SymmetricStore.decrypt(static_ciphertext, bad_key)
      }.to raise_error(OpenSSL::Cipher::CipherError)
      expect {
        bad_auth_tag = [encoding, "qgtPjJI61mvsfaB6Txls7A==", iv, encrypted_string].join('--')
        DoorMat::Crypto::SymmetricStore.decrypt(bad_auth_tag, static_key)
      }.to raise_error(OpenSSL::Cipher::CipherError)
      expect {
        bad_iv = [encoding, auth_tag, "z1c9L9h6ttZi7GgI", encrypted_string].join('--')
        DoorMat::Crypto::SymmetricStore.decrypt(bad_iv, static_key)
      }.to raise_error(OpenSSL::Cipher::CipherError)
      expect {
        bad_encrypted_string = [encoding, auth_tag, iv, "pn+8P7lWazaiNLiy4rf+bc5o7zlnnOruesUc6lE65UDvasYfEGINIdUzvzpN9Z8wBySqXqH5nndLCW3L3xLTreflpIdDcP0Fqp9rWP0="].join('--')
        DoorMat::Crypto::SymmetricStore.decrypt(bad_encrypted_string, static_key)
      }.to raise_error(OpenSSL::Cipher::CipherError)

    end

    it "Does Asymmetric encryption" do
      h = DoorMat::Crypto::AsymmetricStore.generate_pem_encrypted_pkey_pair_and_key
      private_key = DoorMat::Crypto::AsymmetricStore.private_key_from_pem_encrypted_pkey_pair(h[:pem_encrypted_pkey], h[:key])
      public_key = DoorMat::Crypto::AsymmetricStore.public_key_from_pem_encrypted_pkey_pair(h[:pem_encrypted_pkey], h[:key])

      pem_public_key = DoorMat::Crypto::AsymmetricStore.pem_public_key_from_pem_encrypted_pkey_pair(h[:pem_encrypted_pkey], h[:key])
      expect(pem_public_key).to eq public_key.to_pem

      public_key = DoorMat::Crypto::AsymmetricStore.public_key_from_pem_public_key(pem_public_key)

      quote = 'The smallest feline is a masterpiece. -Leonardo da Vinci'
      ciphertext = DoorMat::Crypto::AsymmetricStore.encrypt(quote, public_key)
      expect(DoorMat::Crypto::AsymmetricStore.decrypt(ciphertext, private_key)).to eq quote

    end

    it "handles spurious exception in to_pem calls" do
      dummy = OpenSSL::PKey::RSA.generate(2048)
      allow(dummy).to receive(:to_pem) do
        allow(dummy).to receive(:to_pem).and_call_original
        raise OpenSSL::PKey::RSAError
      end
      allow(OpenSSL::PKey::RSA).to receive(:generate).and_return(dummy)
      expect(DoorMat.configuration.logger).to receive(:error)

      DoorMat::Crypto::AsymmetricStore.generate_pem_encrypted_pkey_pair_and_key
    end
  end
end
