# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :email, :class => DoorMat::Email do

    ignore do
      email "me@example.com"
    end

    address_hash "B4DnTtSed3O2oJ134yu8sxESi5+jPj5RWDoBM+vWy8Q="
    address "me@example.com"
    status :confirmed
  end
end
