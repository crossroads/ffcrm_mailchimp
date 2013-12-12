require 'ffcrm_mailchimp/list'

class MailchimpListInput < SimpleForm::Inputs::CollectionCheckBoxesInput

  # Generate a checkbox list of groups
  #------------------------------------------------------------------------------
  def input
    out = "<br/>".html_safe

    cf_klass_name = cf.klass.to_s
    id = "#{cf_klass_name.underscore}_#{attribute_name}_list_#{cf.list_id}"
    name = "#{cf_klass_name.underscore}[#{attribute_name}][]"
    out << "<input id='#{id}' name='#{name}' type='checkbox' value='list_#{cf.list_id}' #{list_checked? ? 'checked=\'checked\'' : ''} >".html_safe
    out << "<label for='#{id}'>#{cf.list.name} (subscribe to entire list)</label><br /><dd><ul>".html_safe

    out << @builder.collection_check_boxes(attribute_name, collection, :name, :name, input_options, input_html_options) do |b|
      '<li>'.html_safe + b.check_box + b.label + '</li>'.html_safe
    end

    out << '</ul></dd>'.html_safe
    out
  end

  private

  # SimpleForm uses this to populate the checkboxes for the groups
  # [ ['id', 'name'], ['id', 'name'] ]
  #------------------------------------------------------------------------------
  def collection
    cf.list.groups
  end

  # Provides a reference to the custom field instance
  def cf
    @cf ||= CustomFieldMailchimpList.find_by_name(attribute_name)
  end

  #
  # true if the list itself is already checked
  def list_checked?
    object.send("#{attribute_name}_list").any?
  end

end
