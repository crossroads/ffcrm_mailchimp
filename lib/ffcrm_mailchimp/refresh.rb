require 'ffcrm_mailchimp/list'

module FfcrmMailchimp

  class Refresh

    class << self

      #
      # Refresh data from mailchimp. This will clear all list/group data
      # for all mailchimp lists inside CRM and reload the subscription data
      # from Mailchimp.
      def refresh_from_mailchimp!
        FfcrmMailchimp::List.reload_cache
        clear_crm_mailchimp_data!
        load_crm_with_mailchimp_data!
      end

      #
      # This will delete all custom fields and associated database columns
      # NOTE: this is INCREDIBLY DESTRUCTIVE and should only be used if you want to
      # hard reset your CRM instance back to a state before this plugin was installed.
      def destroy_custom_fields!
        CustomFieldMailchimpList.all.each do |field|
          field.klass.connection.remove_column(field.send(:table_name), field.name)
          field.klass.reset_column_information
        end
        CustomFieldMailchimpList.delete_all
      end

      #
      # Delete all the Mailchimp data inside CRM
      # Sets all Mailchimp List custom_field columns to null
      def clear_crm_mailchimp_data!
        config.mailchimp_list_fields.collect{ |f| [f.klass, f.name] }.each do |klass, attr|
          klass.update_all( attr => nil )
        end
      end

      private

      #
      # For all the 'mailchimp list' custom fields, grab the list
      # subscriptions from mailchimp and update CRM
      def load_crm_with_mailchimp_data!
        FfcrmMailchimp::Config.mailchimp_list_fields.each do |l|
          if ( list = FfcrmMailchimp::List.find( l.list_id ) )
            list.members do |webhook_param|
              subscribe_contact(list_id, webhook_param)
            end
          end
        end
      end

      # Adapts a WebhookParams object into something suitable for InboundSync
      def subscribe_contact(params)
        options = params.to_h.merge( type: 'subscribe' )
        Rails.logger.info("FfcrmMailchimp: subscribing #{params.email} to list #{params.list_id}")
        InboundSync.process(options)
      end

      def config
        FfcrmMailchimp.config
      end

    end

  end

end
