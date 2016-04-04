# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :session, :class => DoorMat::Session do

    ignore do
      email "me@example.com"
      password "k#dkvKfdj38g!"
    end

    token "03137b40-ea48-4780-ba6a-f6abf264cf44"
    hashed_token "_lQiFJ89fiUU_SpB0bwaQhBrZ73fWfPO2WulCMHecKY="
    encrypted_symmetric_actor_key "IGUxwZrCW7zSaOLuXS/TCg==--otZoYtoW8m7wJBz6--MWnVkaoVpAigI7lHWSHuh0vLGxwKr1s7y7hqhI2U6xSEf80XaDr8dt9PnSQ="
    password_authenticated_at DateTime.current

    @symmetric_actor_key
    @session_key

    after(:build) do |session, evaluator|
      session.stub(:email).and_return evaluator.email
      session.stub(:password).and_return evaluator.password
    end
  end
end
