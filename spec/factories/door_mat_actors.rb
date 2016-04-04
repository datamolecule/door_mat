# require 'spec_helper'
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :actor, :class => DoorMat::Actor do

    ignore do
      password "k#dkvKfdj38g!"
      password_confirmation "k#dkvKfdj38g!"
    end

    key_salt "MzI=--MTAwMDA=--NIEv2dB/9LoA7pFFSkWB/XkdAYf0gxGV+duTLCZ1oxQ="
    password_salt "$2a$12$u3g9Rx9D/aq262st.A5pcu"
    password_hash "$2a$12$u3g9Rx9D/aq262st.A5pcuFnYN8UQTbUozXpETuk5rzCV1k5UGfhy"
    system_key "3oenvsVf61KOIxHoQrQa6mDgqWlYMaEL2sLe/iCgw0c="
    recovery_key ""

    # after(:build) do |actor, evaluator|
    #   allow(actor).to receive(:password).and_return evaluator.password
    #   allow(actor).to receive(:password_confirmation).and_return evaluator.password_confirmation
    # end
  end
end
