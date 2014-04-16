ActiveSupport.on_load(:fat_free_crm_contact) do

  require 'ffcrm_mailchimp'
  require 'ffcrm_mailchimp/list_subscription'

  class_eval do

    # If subgroup_only is checked, ensures list cannot be saved without at least one subgroup selected (if groups exist on the list)
    # ---------------------------------------------------------
    validate do
      if FfcrmMailchimp.config.subgroups_only?
        FfcrmMailchimp.config.mailchimp_list_fields.each do |field|
          subscription = FfcrmMailchimp::ListSubscription.new( self.send(field.name) )
          if subscription.has_list? and !subscription.has_at_least_one_group? and field.groups.any?
            self.errors.add(:base, "You must either select some mailing list groups for '#{field.label}' or uncheck the box to remove them from the list.")
          end
        end
      end
    end

  end

end
