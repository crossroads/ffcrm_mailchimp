require 'ffcrm_mailchimp/list'

class CustomFieldMailchimpList < CustomField

  # Ensure serialization is activated when mailchimp fields are created/updated
  #------------------------------------------------------------------------------
  after_save { apply_serialization }

  # Renders the selected groups for this list
  #------------------------------------------------------------------------------
  def render(group_ids)
    group_ids && list.groups.select{ |group| group_ids.include?(group.id) }.map(&:name).join(', ')
  end

  # Return all available mailchimp lists. Used in admin screen
  #------------------------------------------------------------------------------
  def collection
    FfcrmMailchimp::List.all
  end

  # Returns the mailchimp list associated with this instance
  #------------------------------------------------------------------------------
  def list
    FfcrmMailchimp::List.get(list_id)
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

  # Serialize mailchimp lists as Array
  #------------------------------------------------------------------------------
  def apply_serialization
    klass_name = self.field_group.try(:klass_name)
    return if klass_name.blank?
    klass = klass_name.constantize

    if !klass.serialized_attributes.keys.include?(self.name)
      klass.serialize(self.name.to_sym, Array)
      Rails.logger.debug("FfcrmMailchimp: Serializing #{self.name} as Array for #{klass}.")
    end

    #
    # We store the list and group data as an Array on the custom field
    # E.g. ["group1", "group2", "list_1235432"]
    #
    # We define methods on the klass related to the custom field so, for example,
    # if a custom field is named 'cf_newsletter' then the following methods are defined:
    # contact.cf_newsletter=       - takes checkbox input and serializes into an array
    # contact.cf_newsletter_list   - returns the list if it is checked
    # contact.cf_newsletter_groups - returns the groups that have been checked
    attr = self.name
    unless klass.instance_methods.include?(:"#{attr}=")
      klass.class_eval <<-WRITER, __FILE__, __LINE__ + 1

        # Override the mutator on the object class to ensure items are serialized correctly
        # ["", "group1,group2,list_1235432"] becomes ["group1", "group2", "list_1235432"]
        define_method "#{attr}=" do |value|
          write_attribute( attr, value.join(',').split(',').reject(&:blank?) )
        end

        # Return the list if it is checked
        # ["group1", "group2", "list_1235432"] returns ["list_1235432"] or []
        define_method "#{attr}_list" do
          read_attribute(attr).select{|v| v.starts_with?('list_')}.compact
        end

        # Return the groups that are checked
        # ["group1", "group2", "list_1235432"] returns ["group1", "group2"]
        define_method "#{attr}_groups" do
          read_attribute(attr).reject{|v| v.starts_with?('list_')}.compact
        end

      WRITER
    end

  end
end
