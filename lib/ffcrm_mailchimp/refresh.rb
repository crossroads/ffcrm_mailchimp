require 'ffcrm_mailchimp/list'
require 'ffcrm_mailchimp/member'

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
        config.mailchimp_list_fields.each do |f|
          if ( list = FfcrmMailchimp::List.find( f.list_id ) )
            list.members.each do |member|
              subscribe_contact( member )
            end
          end
        end
      end

      # Adapts a WebhookParams object into something suitable for InboundSync
      def subscribe_contact(member)
        options = member.to_webhook_params.to_h
        options.merge!( type: 'subscribe' )
        Rails.logger.info("#{Time.now.to_s(:db)} FfcrmMailchimp: subscribing #{member.email} to list #{member.list_id}")
        InboundSync.process(options)
      end

      def config
        FfcrmMailchimp.config
      end

    end

  end

end
