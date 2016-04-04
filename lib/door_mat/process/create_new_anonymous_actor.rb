module DoorMat
  module Process
    class CreateNewAnonymousActor

      def self.owned_by(owner)
        password = DoorMat::Crypto::SymmetricStore.random_key
        anonymous_actor = Actor.create_with(password)
        return nil if anonymous_actor.blank?

        sub_session = DoorMat::Session.new_sub_session_for_actor(anonymous_actor, password)
        anonymous_actor.setup_public_key_pairs(sub_session)

        owner.with_lock do
          anonymous_actor.save!

          if DoorMat::Session.current_session.append_sub_session(sub_session)
            membership = DoorMat::Membership.new
            membership.member = owner
            membership.member_of = anonymous_actor
            membership.sponsor = DoorMat::Membership.sponsors[:sponsor_true]
            membership.owner = DoorMat::Membership.owners[:owner_true]
            membership.permission = DoorMat::Membership.permissions[:no_permission]
            membership.key = password
            membership.save!
          end
        end

        anonymous_actor
      rescue Exception => e
        DoorMat.configuration.logger.error "ERROR: CreateNewAnonymousActor failed to with error - #{e}"
        nil
      end

    end
  end
end
