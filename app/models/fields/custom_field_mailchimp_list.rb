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
  # {"list_id"=>"9285aa3b18", "source"=>"webhook",
  #  "groupings"=>[{"id"=>"8661", "groups"=>["Option 1"]}, {"id"=>"8669", "groups"=>["Option 5"]}]}
  # becomes "Option 1, Option 2"
  def render(value)
    subgroups = []
    groupings = (value || {})[:groupings]
    subgroups << (groupings || []).map{ |gp| gp['groups'] }
    subgroups = subgroups.flatten
    out = "".html_safe
    if value[:list_id].present?
      if config.subgroups_only? and subgroups.any?
        out << subgroups.join(', ')
      else
        out << "#{list.name}"
      end
    end
    out
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

    serialized_attributes = klass.column_names.select{|col| klass.type_for_attribute(col).class == ::ActiveRecord::Type::Serialized }
    if !serialized_attributes.include?(self.name)
      Rails.logger.debug("#{Time.now.to_fs(:db)} FfcrmMailchimp: Serializing #{self.name} as Hash for #{klass}.")
      klass.serialize(self.name, Hash)
    end
  end

  private

  #
  # Turn "groupings"=>[{"id"=>"8661", "groups"=>["Option 1"]}, {"id"=>"8669", "groups"=>["Option 5"]}]
  # into "Group name 1: Option 1; Group name 2: Option 5"
  def grouping_text(grouping)
    out = ""
    group_id = grouping["id"]
    out << group_name_from_group_id(group_id)
    out << ": #{grouping["groups"].join(', ')}" if grouping["groups"].any?
    out
  end

  def group_name_from_group_id(id)
    groups.select{|g| g.id.to_s == id.to_s}.first.try(:name) || ''
  end

  def config
    FfcrmMailchimp.config
  end

end
