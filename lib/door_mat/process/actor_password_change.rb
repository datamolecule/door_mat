module DoorMat
  module Process
    class ActorPasswordChange

      def self.after_password_reset(actor, new_password, recovery_key)
        Session.clear_current_session
        return false unless Session.current_session.recovery_key_restore(actor, recovery_key)
        with(actor, new_password, nil, false)
      end

      def self.with(actor, new_password, old_password='', save_session=true)
        actor.with_lock do

          unless old_password.nil?
            return false unless actor.authenticate(old_password)
          end

          session = DoorMat::Session.current_session
          if save_session
            session = DoorMat::Session.current_session.reload
            unless session.valid?
              return false
            end
          end

          actor.re_key_with(new_password)
          session.re_key_with(actor, new_password)

          pem_key = session.decrypt(actor.encrypted_pem_key)
          actor.encrypted_pem_key = session.encrypt(pem_key)

          actor.save!
          session.save! if save_session

          keys = Actor.reflections.keys.select {|item| Actor.reflections[item].klass.methods.include?(:attr_symmetric_store)}
          keys.each do |key|
            collection = actor.send(key)
            unless collection.blank?
              if collection.respond_to? :find_each
                collection.find_each do |record|
                  record.save!
                end
              else
                collection.save!
              end
            end
          end

          actor.keep_only_this_session! session

        end

        ActivityDownloadRecoveryKey.for(actor)
        true
      rescue ActiveRecord::RecordNotFound => e
        DoorMat.configuration.logger.warn "WARN: Failed to change actor password - #{e}"
        false
      rescue Exception => e
        DoorMat.configuration.logger.error "ERROR: Failed to change actor password - #{e}"
        raise e
      end

    end
  end
end
