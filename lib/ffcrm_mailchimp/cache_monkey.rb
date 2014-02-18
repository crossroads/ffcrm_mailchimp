require 'gibbon'

module FfcrmMailchimp

  # This is a cache around the Gibbon api to ensure we don't hit the
  # mailchimp API every time for certain queries e.g. lists
  class CacheMonkey

    class << self

      # Clear all the caches
      # Ironically, this involves calling mailchimp to find all the list ids
      def clear
        Rails.cache.delete( lists_cache_key )
        lists['data'].each do |list|
          Rails.cache.delete( groups_cache_key( list['id'] ) )
        end
        Rails.cache.delete( lists_cache_key )
      end

      # Clears and fills the caches
      def prime
        clear
        lists
        lists['data'].each{ |list| groups(list['id']) }
      end

      # Gets all the lists from Mailchimp
      def lists
        Rails.cache.fetch( lists_cache_key ) do
          Rails.logger.info("FfcrmMailchimp: Cache miss fetching lists")
          gibbon.lists.list
        end
      end

      # Gets the groups for a particular list
      def groups(list_id)
        Rails.cache.fetch( groups_cache_key(list_id) ) do
          Rails.logger.info("FfcrmMailchimp: Cache miss fetching groups for list #{list_id}")
          gibbon.lists.interest_groupings(id: list_id)
        end
      end

      private

      def gibbon
        @gibbon ||= Gibbon::API.new( api_key )
      end

      def api_key
        FfcrmMailchimp.config.api_key
      end

      def lists_cache_key
        "cache_monkey_lists"
      end

      def groups_cache_key(list_id)
        "cache_monkey_groups_for_list_" << list_id
      end

    end

  end

end
