require 'ffcrm_mailchimp/list'

class MailchimpListInput < SimpleForm::Inputs::CollectionCheckBoxesInput

  # Generate a checkbox list of groups
  #------------------------------------------------------------------------------
  def input
    @builder.send("collection_check_boxes", attribute_name, collection, :name, :name, input_options, input_html_options)
  end

  private

  # SimpleForm uses this to populate the checkboxes
  # [ ['id', 'name'], ['id', 'name'] ]
  #------------------------------------------------------------------------------
  def collection
    cf.list.groups
  end

  # Pre-check group ids that have been previously saved
  def input_options
    super.merge( { checked: value } )
  end

  # selected group ids
  def value
    list_of_groups = []
    list_of_groups = object.send(attribute_name)["groups"].present? ? object.send(attribute_name)["groups"] : []
  end

  # Provides a reference to the custom field instance
  def cf
    @cf ||= CustomFieldMailchimpList.find_by_name(attribute_name)
  end

end
