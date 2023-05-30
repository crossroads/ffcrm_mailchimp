# Required to ensure settings column in custom fields can be set properly during tests.
Rails.application.config.after_initialize do
  ActiveRecord::Base.yaml_column_permitted_classes += [
    ActiveSupport::HashWithIndifferentAccess
  ]
end