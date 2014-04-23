require 'gibbon'
require 'ffcrm_mailchimp/config'

module FfcrmMailchimp

  #
  # Interact with MERGE variables in mailchimp.
  # Particularly, learn the mapping between tag name and field label (useful in Export API)
  class MergeVars

    def initialize(list_id)
      @list_id = list_id
    end

    #
    # field_label_for('EMAIL') => 'Email address'
    def field_label_for(name)
      merge_vars.select{ |mv| mv['tag'] == name}.first['name']
    end

    private

    def merge_vars
      @merge_vars ||= begin
        gibbon.lists.merge_vars(id: [@list_id])['data'].first['merge_vars']
      end
    end

    def gibbon
      @gibbon ||= Gibbon::API.new( FfcrmMailchimp::config.api_key )
    end

  end

end
