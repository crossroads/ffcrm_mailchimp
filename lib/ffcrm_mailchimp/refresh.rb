require 'ffcrm_mailchimp/list'

module FfcrmMailchimp

  class Refresh

    class << self

      #
      # Refresh data from Mailchimp for the given email_addresses
      # For all the 'mailchimp list' custom fields, grab the list
      # subscriptions from mailchimp and update CRM
      def refresh_from_mailchimp(email_addresses = [])
        FfcrmMailchimp.config.mailchimp_list_fields.each do |f|
          if ( list = FfcrmMailchimp::List.find( f.list_id ) )
            email_addresses.each do |email_address|
              member = FfcrmMailchimp::Api.lookup_member_on_list(list.id, email_address)
              subscribe_contact(member) unless member['email_address'].blank? # record found in mailchimp
            end
          end
        end
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
        FfcrmMailchimp.config.mailchimp_list_fields.collect{ |f| [f.klass, f.name] }.each do |klass, attr|
          klass.update_all( attr => nil )
        end
      end

      private

      # Adapts a Mailchimp list member API response into something suitable for InboundSync
      def subscribe_contact(member)
        params = FfcrmMailchimp::WebhookParams.new_from_api(member).to_h
        params.merge!( type: 'subscribe' )
        Rails.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp: subscribing #{member["email_address"]} to list #{member["list_id"]}")
        InboundSync.process(params)
      end

    end

  end

end
