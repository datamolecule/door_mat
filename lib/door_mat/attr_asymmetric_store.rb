module DoorMat
  module AttrAsymmetricStore
    class AttrAsymmetricStoreWrapper

      def initialize(attribute, actor_column)
        @attribute = attribute
        @actor_column = actor_column
      end

      def after_find(record)
        return if DoorMat::Crypto.current_skip_crypto_callback.skip?

        # leave attribute as-is if blank or the actor is not set
        encrypted_attribute = record.send("#{@attribute}")
        actor = record.send("#{@actor_column}")
        return if encrypted_attribute.blank? || actor.blank?

        clear_attribute = nil

        DoorMat::Session.current_session.autoload_sesion_for(actor)
        DoorMat::Session.current_session.with_session_for_actor(actor) do |session|
          clear_attribute = actor.decrypt_shared_key(encrypted_attribute, session)
        end

        if clear_attribute.nil?
          clear_attribute = '[ENCRYPTED SHARED KEY]'
        end

        record.send("#{@attribute}=", clear_attribute)
        DoorMat.configuration.logger.debug "DEBUG: Decrypt #{@attribute}: #{encrypted_attribute} -> #{clear_attribute}" if Rails.env.development?
      end

      def around_save(record)
        return yield if DoorMat::Crypto.current_skip_crypto_callback.skip?

        clear_attribute = record.send("#{@attribute}")
        actor = record.send("#{@actor_column}")

        # leave attribute as-is if blank or the actor is not set
        if clear_attribute.blank? || actor.blank?
          yield
        else
          encrypted_attribute = actor.encrypt_shared_key(clear_attribute)

          DoorMat.configuration.logger.debug "DEBUG: Encrypt #{@attribute}: #{clear_attribute} -> #{encrypted_attribute}" if Rails.env.development?
          record.send("#{@attribute}=", encrypted_attribute)
          yield
          record.send("#{@attribute}=", clear_attribute)
          DoorMat.configuration.logger.debug "DEBUG: Decrypt #{@attribute}: #{encrypted_attribute} -> #{clear_attribute}" if Rails.env.development?
        end
      end

    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def attr_asymmetric_store(*args, **options)
        return unless self.table_exists?

        actor_column = options.fetch(:actor_column, :actor).to_s
        unless self.attribute_names.include? "#{actor_column}_id"
          raise ActiveRecord::ActiveRecordError, "attr_asymmetric_store records must belong to a DoorMat::Actor but could not find the actor column. Pass the actor_column: :actor_column_name option to specify it."
        end

        args.each do |arg|
          column_type = (self.columns_hash[arg.to_s].cast_type.respond_to?(:type) && self.columns_hash[arg.to_s].cast_type.type) || self.columns_hash[arg.to_s].cast_type.to_s
          if [:text, :string].include? column_type
            after_find DoorMat::AttrAsymmetricStore::AttrAsymmetricStoreWrapper.new(arg.to_s, actor_column)
            around_save DoorMat::AttrAsymmetricStore::AttrAsymmetricStoreWrapper.new(arg.to_s, actor_column)
          else
            raise ActiveRecord::ActiveRecordError, "attr_asymmetric_store only support text and string column types."
          end
        end
      end

    end
  end
end
