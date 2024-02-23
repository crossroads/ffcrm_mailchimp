# it is possible this script will execute before jQuery so we wrap it in a setTimeout

defer = (method) ->
    if (window.jQuery)
        method()
    else
        window.setTimeout (-> defer(method)), 50

defer(() ->

  # when a list checkbox is unchecked, ensure group checkboxes are unchecked
  $(document).on 'click', 'input.mailchimp_list_lists', (event) ->
    $checkbox = $(this)
    unless $checkbox.is(':checked')
      $checkbox.closest('div.mailchimp_list').find('input.mailchimp_list_groups').attr('checked', false)

  # when a group checkbox is checked, ensure list checkbox is checked
  $(document).on 'click', 'input.mailchimp_list_groups', (event) ->
    $checkbox = $(this)
    if $checkbox.is(':checked')
      $checkbox.closest('div.mailchimp_list').find('input.mailchimp_list_lists').attr('checked', true)

)
