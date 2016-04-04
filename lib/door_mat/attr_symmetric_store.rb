module DoorMat
  module AttrSymmetricStore
    class AttrSymmetricStoreWrapper

      def initialize(attribute, actor_column)
        @attribute = attribute
        @actor_column = actor_column
      end

      def after_find(record)
        return if DoorMat::Crypto.current_skip_crypto_callback.skip?

        encrypted_attribute = record.send("#{@attribute}")
        actor = record.send("#{@actor_column}")
        clear_attribute = nil

        DoorMat::Session.current_session.autoload_sesion_for(actor)
        DoorMat::Session.current_session.with_session_for_actor(actor) do |session|
          clear_attribute = session.decrypt(encrypted_attribute)
        end

        if clear_attribute.nil?
          clear_attribute = '[ENCRYPTED]'
          record.readonly!
        end

        record.send("#{@attribute}=", clear_attribute)
        DoorMat.configuration.logger.debug "DEBUG: Decrypt #{@attribute}: #{encrypted_attribute} -> #{clear_attribute}" if Rails.env.development?
      end

      def around_save(record)
        return yield if DoorMat::Crypto.current_skip_crypto_callback.skip?

        raise ActiveRecord::Rollback, "Record is read-only" if record.readonly?

        clear_attribute = record.send("#{@attribute}")
        actor = record.send("#{@actor_column}")
        encrypted_attribute = nil

        DoorMat::Session.current_session.autoload_sesion_for(actor)
        DoorMat::Session.current_session.with_session_for_actor(actor) do |session|
          encrypted_attribute = session.encrypt(clear_attribute)
        end
        raise ActiveRecord::Rollback, "DoorMat::Session is not valid" if encrypted_attribute.nil?

        DoorMat.configuration.logger.debug "DEBUG: Encrypt #{@attribute}: #{clear_attribute} -> #{encrypted_attribute}" if Rails.env.development?
        record.send("#{@attribute}=", encrypted_attribute)
        yield
        record.send("#{@attribute}=", clear_attribute)
        DoorMat.configuration.logger.debug "DEBUG: Decrypt #{@attribute}: #{encrypted_attribute} -> #{clear_attribute}" if Rails.env.development?
      end

    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def attr_symmetric_store(*args, **options)
        return unless self.table_exists?

        actor_column = options.fetch(:actor_column, :actor).to_s
        unless self.attribute_names.include? "#{actor_column}_id"
          raise ActiveRecord::ActiveRecordError, "attr_symmetric_store records must belong to a DoorMat::Actor but could not find the actor column. Pass the actor_column: :actor_column_name option to specify it."
        end

        args.each do |arg|
          column_type = (self.columns_hash[arg.to_s].cast_type.respond_to?(:type) && self.columns_hash[arg.to_s].cast_type.type) || self.columns_hash[arg.to_s].cast_type.to_s
          if [:text, :string].include? column_type
            after_find DoorMat::AttrSymmetricStore::AttrSymmetricStoreWrapper.new(arg.to_s, actor_column)
            around_save DoorMat::AttrSymmetricStore::AttrSymmetricStoreWrapper.new(arg.to_s, actor_column)
          else
            raise ActiveRecord::ActiveRecordError, "attr_symmetric_store only support text and string column types."
          end
        end
      end

    end
  end
end
