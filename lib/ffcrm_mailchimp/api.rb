require 'gibbon'
require 'gibbon/mailchimp_error'

module FfcrmMailchimp

  # A wrapper around Gibbon.
  # Does a bit of list caching too
  class Api

    class << self

      # Enumerate all the lists in Mailchimp for use in CustomFields
      # Returns array of hashes [ {id: '1123', name: 'List name'}, {id: ...} ]
      def all_lists
        Rails.cache.fetch( all_lists_cache_key ) do
          gibbon = Gibbon::Request.new()
          gibbon.lists.retrieve['lists'].collect do |list|
            list.select{|k,v| %w(id name).include?(k)}
          end
        end
      end

      # Subscribes a new or existing user and updates list/interest groups
      def subscribe(list_id, email, body = {}, groupings={})
        gibbon = Gibbon::Request.new()
        body = body.merge(status_if_new: "subscribed", status: "subscribed", interests: groupings_for_api(list_id, groupings))
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::Api: subscribing contact #{email} to list #{list_id}. Payload #{body}")
        begin
          gibbon.lists(list_id).members(email_digest(email)).upsert(body: body)
        rescue Gibbon::MailChimpError => e
          FfcrmMailchimp.logger.error("#{Time.now.to_fs(:db)} FfcrmMailchimp::Api: Gibbon::MailchimpError #{e.status_code} #{e.title} #{e.detail} #{e.body} ")
          raise e # throw it again to ensure that the job is tried again
        end
      end

      # Unsubscribe a user from the list entirely (marks them as unsubscribed in Mailchimp)
      def unsubscribe(list_id, email)
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::Api: unsubscribing #{email} from list #{list_id}")
        gibbon = Gibbon::Request.new()
        begin
          gibbon.lists(list_id).members(email_digest(email)).update(body: { status: "unsubscribed" })
        rescue Gibbon::MailChimpError => e
          if (e.status_code == 404)
            FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::Api: user #{email} not found on list #{list_id}. Ignoring.")
          else
            FfcrmMailchimp.logger.error("#{Time.now.to_fs(:db)} FfcrmMailchimp::Api: Gibbon::MailchimpError #{e.status_code} #{e.title} #{e.detail} #{e.body} ")
            raise e  # throw it again to ensure that the job is tried again
          end
        end
      end

      # Enumerate the categories and interest groups that users can subscribe to
      # [ {"list_id"=>"4a1df096f3", "id"=>"34b9452245", "title"=>"Interest group 1",
      #    "groups"=>[ {"id"=>"70b7107c8a", "name"=>"Option 1"}, {"id"=>"7c1719c788", "name"=>"Option 2"}, {"id"=>"8d856390f6", "name"=>"Option 3"}]
      #   }
      # ]
      def interest_groupings(list_id)
        raise RuntimeError, "Please provide a list_id" if list_id.blank?
        Rails.cache.fetch( interest_groupings_cache_key(list_id) ) do
          groups = []
          gibbon = Gibbon::Request.new()
          interest_categories = gibbon.lists(list_id).interest_categories.retrieve['categories']
          interest_categories.each do |interest_category|
            group = interest_category.select{|x| %w(list_id id title).include?(x)}
            interests = gibbon.lists(list_id).interest_categories(group['id']).interests.retrieve
            group['groups'] = interests['interests'].map{|category| category.select{|field| %w(id name).include?(field)}}
            groups << group
          end
          groups
        end
      end

      #
      # Get the Mailchimp data for a specific member
      # Returns a Hash object
      # { "email_address": "string",
      #   "status": "subscribed",
      #   "merge_fields": {
      #     "property1": null,
      #     "property2": null
      #   },
      #   "interests": {
      #     "70b7107c8a": true,
      #     "7c1719c788": false
      #   }
      # }
      def lookup_member_on_list(list_id, email_address)
        gibbon = Gibbon::Request.new()
        begin
          result = gibbon.lists(list_id).members(email_digest(email_address)).retrieve
        rescue Gibbon::MailChimpError => e
          FfcrmMailchimp.logger.error("#{Time.now.to_fs(:db)} FfcrmMailchimp::Api: Gibbon::MailchimpError #{e.status_code} #{e.title} #{e.detail} #{e.body} ")
          if (e.status_code == 404)
            result = {} # member not found on list
          else
            raise e
          end
        end
        result
      end

      def clear_cache
        all_lists.each do |list|
          FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::Api: Clearing cache: #{interest_groupings_cache_key(list['id'])}")
          Rails.cache.delete( interest_groupings_cache_key(list['id']) )
        end
        FfcrmMailchimp.logger.info("#{Time.now.to_fs(:db)} FfcrmMailchimp::Api: Clearing cache: #{all_lists_cache_key}")
        Rails.cache.delete( all_lists_cache_key )
      end

      private

      def all_lists_cache_key
        "ffcrm_mailchimp_lists"
      end

      def interest_groupings_cache_key(list_id)
        "ffcrm_mailchimp_groups_for_list_#{list_id}"
      end

      def email_digest(email)
        Digest::MD5.hexdigest(email.downcase)
      end

      # Return a list of interest category ids with a boolean indicating if the user is subscribed
      # Result: { "70b7107c8a => true", "7c1719c788" => false, "8d856390f6" => false }
      def groupings_for_api(list_id, groupings)
        # Convert nested group names into flattened list: 'Option 1', 'Option 2'
        selected_group_names = groupings.map do |grouping|
          grouping['groups']
        end.flatten.compact.uniq

        result = {}
        interest_groupings(list_id).each do |interest_category|
          interest_category['groups'].each do |group|
            result[group['id']] = selected_group_names.include?(group['name']) # 'true' or 'false'
          end
        end
        result
      end

    end

  end
end
