require 'ffcrm_mailchimp/mailchimp_list'

class CustomFieldMailchimpList < CustomField

  # Renders the selected groups for this list
  #------------------------------------------------------------------------------
  def render(group_ids)
    group_ids && list.groups.select{ |group| group_ids.include?(group.id) }.map(&:name).join(', ')
  end

  # Return all available mailchimp lists. Used in admin screen
  #------------------------------------------------------------------------------
  def collection
    FfcrmMailchimp::MailchimpList.all
  end

  # Returns the mailchimp list associated with this instance
  #------------------------------------------------------------------------------
  def list
    FfcrmMailchimp::MailchimpList.get(list_id)
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

end
