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

  # Serialize mailchimp lists as Hash
  #------------------------------------------------------------------------------
  def apply_serialization
    klass_name = self.field_group.try(:klass_name)
    return if klass_name.blank?
    klass = klass_name.constantize

    if !klass.serialized_attributes.keys.include?(self.name)
      klass.serialize(self.name.to_sym, Hash)
      Rails.logger.debug("FfcrmMailchimp: Serializing #{self.name} as Array for #{klass}.")
    end

    #
    # Override the mutator on the object class to ensure items are serialized correctly
    attr = self.name
    unless klass.instance_methods.include?(:"#{attr}=")
      klass.class_eval <<-WRITER, __FILE__, __LINE__ + 1
        define_method "list_with_group" do |val|
          {"list_id" => "#{list_id}", "groups" => val} if val.present?
        end
        define_method "#{attr}=" do |value|
          write_attribute( attr, list_with_group(value.reject(&:blank?)) )
        end
      WRITER
    end
  end
end
