require 'ffcrm_mailchimp/list'

class MailchimpListInput < SimpleForm::Inputs::CollectionCheckBoxesInput

  # Generate a checkbox list of groups
  #------------------------------------------------------------------------------
  def input

    out = "<br/>".html_safe

    out << "<input id='#{attribute_name}[list_id]' name='#{attribute_name}[list_id]' type='checkbox' value='#{cf.list_id}'>".html_safe
    out << "#{cf.list.name} (subscribe to entire list)<br /><dd><ul>".html_safe

    out << @builder.collection_check_boxes(attribute_name, collection, :name, :name, input_options, input_html_options) do |b|
      name = "#{attribute_name}[groups][#{b.object.name}]"
      id = name.underscore
      '<li>'.html_safe + b.check_box( id: id, name: name ) + b.label + '</li>'.html_safe
    end

    out << '</ul></dd>'.html_safe

    out

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
    object.send(attribute_name)["groups"] || []
  end

  # Provides a reference to the custom field instance
  def cf
    @cf ||= CustomFieldMailchimpList.find_by_name(attribute_name)
  end

end
