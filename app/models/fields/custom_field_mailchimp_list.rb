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
        # ["", "1525_group1,1525_group2,list_1235432"] becomes [{"list_id"=> "1235432",
        #   "groupings" => [{"group_id" => "1525", "groups"=>["group1","group2"]}]}]
        define_method "#{attr}=" do |value|
          groups, group_id, result = [], "", {}
          data = value.join(',').split(',').reject(&:blank?)
          result, groups, group_id = custom_field_data(data)
          result = result.merge("source"=> "ffcrm") unless(result["source"] == "webhook")
          result = result.merge({"groupings" => [{"group_id" => group_id,
            "groups"=>groups}]}) unless groups.blank?
          cf_data = result.blank? ? [] : [result]
          write_attribute( attr, cf_data)
        end

        define_method "custom_field_data" do |data|
          info, g_data, g_id, list_id = {}, [], "", ""
          data.map{|val|
            if val.starts_with?('list_')
              list_id = val.split('_')[1]
              info = info.merge("list_id"=> list_id) unless list_id.blank?
            elsif(val == "source_webhook")
              info = info.merge("source"=> "webhook")
            else
              g_data << val.split('_')[1]
              g_id = val.split('_')[0] if g_id.blank?
            end
          }
          return info, g_data, g_id
        end

        # Return the list if it is checked
        # ["group1", "group2", "list_1235432"] returns ["list_1235432"] or []
        define_method "#{attr}_list" do
          read_attribute(attr).first["list_id"] unless read_attribute(attr).first.blank?
        end

        # Return the groups that are checked
        # ["group1", "group2", "list_1235432"] returns ["group1", "group2"]
        define_method "#{attr}_groups" do
          read_attribute(attr).first["groupings"].first["groups"] if(read_attribute(attr).first.present? && read_attribute(attr).first["groupings"].present?)
        end

      WRITER
    end
  end
end