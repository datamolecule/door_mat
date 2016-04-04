module DoorMat
  class Membership < ActiveRecord::Base

    include DoorMat::AttrAsymmetricStore

    belongs_to :member,
               :inverse_of => :memberships,
               :foreign_key => :member_id,
               :class_name => 'DoorMat::Actor'
    belongs_to :member_of,
               :inverse_of => :members,
               :foreign_key => :member_of_id,
               :class_name => 'DoorMat::Actor'

    attr_asymmetric_store :key, actor_column: :member

    enum sponsor: [:sponsor_false, :sponsor_true]
    enum owner: [:owner_false, :owner_true]
    enum permission: [:no_permission, :list_permission, :read_permission, :write_permission]

    def share_with!(actor, ownership = :owner_true, permission = :no_permission )
      false unless self.owner_true?

      membership = DoorMat::Membership.new
      membership.member = actor
      membership.member_of = self.member_of
      membership.sponsor = DoorMat::Membership.sponsors[:sponsor_false]
      membership.owner = DoorMat::Membership.owners[ownership]
      membership.permission = DoorMat::Membership.permissions[permission]
      membership.key = self.key
      membership.save!
      true
    end

    def load_sub_session
      sub_session = DoorMat::Session.new_sub_session_for_actor(self.member_of, self.key)

      self.member.setup_public_key_pairs(sub_session)
    end

  end
end
