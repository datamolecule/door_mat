require 'spec_helper'

module DoorMat
  describe Email do

    it 'creates a valid email from an email address' do
      address = 'user@example.com'

      email = DoorMat::Email.for(address)
      expect(email).to be_valid

      urlsafe_encoded_address = email.to_urlsafe_encoded
      expect(DoorMat::Email.decode_urlsafe(urlsafe_encoded_address)).to eq(address)
      expect(DoorMat::Email.address_hash(address)).to eq(DoorMat::Email.address_hash_from_encoded_address(urlsafe_encoded_address))
    end

    it 'returns an invalid url encoded address unchanged' do
      address = 'user@example.com'

      expect(DoorMat::Email.decode_urlsafe(address)).to eq(address)
    end

  end
end

