require 'active_support/hash_with_indifferent_access'

module CustomFieldHelper

  #
  # For specs that require fully working MailchimpList custom fields, use the following:
  #
  # before(:all) { setup_custom_field_record }
  # after(:all)  { teardown_custom_field_record }
  #
  # Also, ensure the list_id is used below
  #

  def custom_field_list_id
    "3e26bc072d"
  end

  def setup_custom_field_record
    field_group = FactoryBot.create(:field_group, klass_name: "Contact")
    settings = { list_id: custom_field_list_id }.with_indifferent_access
    FactoryBot.create(:field, field_group_id: field_group.id, type: "CustomFieldMailchimpList",
      label: "custom_field", name: "custom_field", as: "mailchimp_list", settings: settings)
    FfcrmMailchimp.config.mailchimp_list_fields.map(&:apply_serialization)
  end

  def teardown_custom_field_record
    FieldGroup.delete_all
    CustomFieldMailchimpList.delete_all
  end

end
