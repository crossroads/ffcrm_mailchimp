require 'ffcrm_mailchimp/list'
require 'ffcrm_mailchimp/list_subscription'

class CustomFieldMailchimpList < CustomField

  # Ensure serialization is activated when mailchimp fields are created/updated
  #------------------------------------------------------------------------------
  after_save { apply_serialization }

  # Ensure a list is always selected
  #------------------------------------------------------------------------------
  validate do
    errors.add(:list_id, "You must select a Mailchimp list.") if list_id.blank?
    errors.add(:list_id, "The class this field is created for MUST have an 'email' attribute.") unless klass.columns.select{|c| c.name == 'email'}.any?
  end

  # Renders the selected groups for this list
  #------------------------------------------------------------------------------
  def render(group_ids)
    group_ids && groups.select{ |group| group_ids.include?(group.id) }.map(&:name).join(', ')
  end

  # Return all available mailchimp lists. Used in admin screen
  #------------------------------------------------------------------------------
  def collection
    all_lists = FfcrmMailchimp::List.collection_for_select
    all_lists.reject!{ |name, list_id| existing_list_ids_for_klass.include?(list_id) }
    if list
      # for edits, make sure we include our existing list
      [[list.name, list.id]] + all_lists
    else
      all_lists
    end
  end

  # Gets all the list ids that are currently defined in any field_group belonging to klass
  # We use this to filter out the list on the admin screen so you can't use the list_id twice
  #------------------------------------------------------------------------------
  def existing_list_ids_for_klass
    FieldGroup.where( klass_name: klass_name ).
      map{ |fg| fg.fields }.flatten.
      select{ |f| f.as == 'mailchimp_list' }.
      map{ |f| f.settings['list_id'] }
  end

  # Returns the mailchimp list associated with this instance
  #------------------------------------------------------------------------------
  def list
    FfcrmMailchimp::List.find(list_id)
  end

  # The mailchimp list id associated with this instance
  #------------------------------------------------------------------------------
  def list_id
    settings['list_id']
  end

  # Save the mailchimp list id associated with this instance
  #------------------------------------------------------------------------------
  def list_id=(value)
    settings['list_id'] = value
  end

  # Return a hash of groups for this list
  def groups
    list.groups
  end

  # Serialize Mailchimp lists as Array
  #------------------------------------------------------------------------------
  def apply_serialization
    klass_name = self.field_group.try(:klass_name)
    return if klass_name.blank?
    klass = klass_name.constantize

    if !klass.serialized_attributes.keys.include?(self.name)
      klass.serialize(self.name.to_sym, Hash)
      Rails.logger.debug("FfcrmMailchimp: Serializing #{self.name} as Hash for #{klass}.")
    end

    #
    # We store the list and group data as an Array on the custom field
    # but it can be converted to a ListSubscription to do useful things.
    attr = self.name
    unless klass.instance_methods.include?(:"#{attr}=")
      klass.class_eval <<-WRITER, __FILE__, __LINE__ + 1
        # Override the mutator on the object class to ensure items are serialized correctly
        define_method "#{attr}=" do |value|
          data = if (value == nil)
              nil
            elsif value.is_a?(FfcrmMailchimp::ListSubscription)
              value.to_h
            else
              raise RuntimeError, "FfcrmMailchimp: #{attr}= must be passed a ListSubscription object or nil."
            end
          write_attribute( attr, data )
        end
      WRITER
    end
  end
end
