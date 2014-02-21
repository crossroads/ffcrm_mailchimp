require 'ffcrm_mailchimp/list'
require 'ffcrm_mailchimp/list_subscription'

class MailchimpListInput < SimpleForm::Inputs::CollectionCheckBoxesInput

  # Generate a checkbox list of groups
  #------------------------------------------------------------------------------
  def input
    out = "<br/>".html_safe

    cf_klass_name = cf.klass.to_s
    id = "#{cf_klass_name.underscore}_#{attribute_name}_list_#{cf.list_id}"
    name = "#{cf_klass_name.underscore}[#{attribute_name}]"
    out << "<input id='#{id}' name='#{name}[list_id]' type='checkbox' value='#{cf.list_id}' #{list_checked? ? 'checked=\'checked\'' : ''} class = 'mailchimp_list_lists'>".html_safe
    out << "<label for='#{id}'>#{cf.list.name}</label>".html_safe
    out << "<br /><small>Updates Mailchimp list when you save</small>".html_safe

    if groups.any?
      out << "<dd><ul>".html_safe
      groups.each do |group|
        out << "<p>#{group.name}</p>".html_safe
        out << @builder.fields_for( attribute_name ) do |gf|
          gf.fields_for( :groups ) do |g|
            g.collection_check_boxes(group.id, group.group_names, :to_s, :to_s, input_options, input_html_options.merge(class: 'mailchimp_list_groups') ) do |b|
              '<li>'.html_safe + b.check_box( checked: group_checked(b) ) + b.label + '</li>'.html_safe
            end
          end
        end
      end
      out << '</ul></dd>'.html_safe
    end
    out << "<input type='hidden' name='#{cf_klass_name.underscore}[#{attribute_name}][source]' value='ffcrm' />".html_safe

    out
  end

  private

  # SimpleForm uses this to populate the checkboxes for the groups
  # [ Group.new( id: 8661, name: 'Group One', groups: ['One', 'Two']), }, Group.new( id: 1243, name: 'Group Two', groups: ['Three', 'Four'] ) ]
  #------------------------------------------------------------------------------
  def groups
    @cf_groups ||= cf.groups
  end

  # Provides a reference to the custom field instance
  def cf
    @cf ||= CustomFieldMailchimpList.find_by_name(attribute_name)
  end

  # Has the list been checked?
  def list_checked?
    list_subscription.has_list?
  end

  # Returns 'checked' if the group is checked
  def group_checked(obj)
    list_subscription.has_group?(obj.object) ? "checked" : nil
  end

  # Get the list subscription object for this attribute
  def list_subscription
    @list_subscription ||= FfcrmMailchimp::ListSubscription.new( object.send(attribute_name) )
  end

end
