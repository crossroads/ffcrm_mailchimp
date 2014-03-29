# FFCRM Mailchimp

## About

FFCRM Mailchimp is designed to work with the popular open source [Fat Free CRM](http://www.fatfreecrm.com).

FFCRM Mailchimp is Charityware.  You can use and copy it as much as you like, but you are
encouraged to make a donation for those in need via the Crossroads Foundation (the organisation who built this plugin). See [http://www.crossroads.org.hk/](http://www.crossroads.org.hk/)

This plugin enables Fat Free CRM to listen for MailChimp subscribes, unsubscribes, profile updates, email changed events performed by a MailChimp subscriber, MailChimp Admin or the MailChimp API and update contact records accordingly. Additionally, in FFCRM, contact creates, updates, deletes and merges are also communicated back to Mailchimp.


## Installation

Add the ffcrm_mailchimp gem (and the ffcrm_endpoint dependency) to your Gemfile.

```
gem 'ffcrm_endpoint'
gem 'ffcrm_mailchimp', github: 'crossroads/ffcrm_mailchimp'
```

## Setup

This plugin depends on delayed job. You will need to run the following commands to set it up:

```
bundle install
rails generate delayed_job:active_record
rake db:migrate
```

Start your rails server and goto the Admin -> Mailchimp tab.

1. Input your MailChimp API key and select a default user who will be attributed with the changes the plugin makes. We suggest you create your own dedicated Mailchimp user for this. Save the form.
2. Now goto the Admin -> Custom Fields tab
3. On the contacts tab, create a new custom field with type 'Mailchimp'. A list dropdown will appear with the mailchimp lists associated with the mailchimp API key you just entered. Choose one list.
4. If you have other lists, you can go ahead and create more custom fields.
5. Restart your server to propagate custom field changes to all instances. (a FFCRM requirement)
 
On mailchimp:

1. Login to your mailchimp account and add a webhook for each list you wish to sync.
2. You can find the inbound webhook url to use on the Admin -> Mailchimp tab underneath the form. It is of the form: https://www.example.com/endpoints/mailchimp_endpoint?api_key=mailchimp-api-key

Obviously, your webhook address needs to be a publicly accessible url. Mailchimp won't know where to go if you use localhost! However, if you'd like to try out this plugin on your local machine, I've found the ngrok proxy service invaluable. Just make sure you understand what is / does before using it!

Final step: ensure delayed_job is running and you're good to go. Start creating/editing contacts and Mailchimp should be updated automatically and vice-versa.

## Admin buttons

### Reload caches

This button will clear any mailchimp list/group caches that are stored. This is useful if you know you've changed the name of a list or added an interest group and you'd like to update FFCRM. Pressing this button is non-destructive - you won't delete anything important!

### Update data from MailChimp

This button will force all list subscription data in FFCRM to be removed and updated from Mailchimp. Use it to get your FFCRM instance up to date with Mailchimp. It will create/update contacts in FFCRM as necessary.

This is a simple, one-way update only. It only adds MailChimp data to FFCRM. It does not make any changes to MailChimp records. E.g. If James Smith is marked in FFCRM as subscribed to “Special Deals” but he is not subscribed in MailChimp (a case that can occur if you disable integration on a list), this button will remove the “Special Deals” subscription in FFCRM.

### Clear all mailchimp data in CRM

This button completely removes any MailChimp subscriber info in FFCRM. There is no “undo”.

This is useful if you have changed MailChimp accounts or if you have deleted some MailChimp lists and/or generaly got your data way out of whack. You can start fresh, reconfigure the plugin and pull fresh data from MailChimp.

### Clear all settings and data

In addition to removing any Mailchimp list data stored in FFCRM, it will also delete all the Mailchimp custom fields and data. It acts just like a 'factory reset' button. Use carefully.


## Important Notes / Caveats

### Deleting a list in MailChimp isn't enough

If you delete a list in MailChimp or disable its integration, that list will remain visible as a checkbox on FFCRM contacts and any existing data will remain untouched in FFCRM (the plugin doesn’t clean it out). To get rid of a list entirely clear all plugin settings and data in FFCRM, then reconfigure the plugin and finally, update your data again from MailChimp.

### Contacts have to be valid

A MailChimp subscriber must have enough data to be valid in FFCRM or the FFCRM plugin will completely ignore it. By default, FFCRM requires a contact to have both a first name and a last name (this can be changed in FFCRM’s secret settings so ask your system administrator if you are not sure.) So, for example, if you add a subscriber to MailChimp without providing a first/last name, MailChimp will send the new subscriber data to FFCRM but FFCRM will ignore it (assuming you use FFCRM’s default settings).

### Duplicate email addresses are not good

If two contacts have the same email address in FFCRM, this plugin will pick the first one.


## How it functions

By default, the plugin will update FFCRM for the folowing MailChimp API actions:

* Subscribes: will edit matching contact and log a history item or will create a new contact
* Unsubscribes: same as above
* Profile updates: same as above. Currently the plugin only synchronises First Name, Last Name and email address.
* Email change: will automatically change the contact’s email address and will log a history item

The plugin will update MailChimp for the following FFCRM actions performed on a contact:

Note: currently the plugin only synchronises First Name, Last Name and email address

* Subscribe: when a new contact is created or an existing one is edited and a MailChimp list is indicated
* Unsubscribe: Can happen when a contact is edited, deleted or merged (see below)
* Profile Update: Can happen when a contact is created or edited
* Merge two contacts: will delete one MailChimp contact and update list subscription information for the merged one. A FFCRM merge is really two separate actions: a delete of one contact and an update of another.

When you use FFCRM to subscribe someone to a MailChimp list, the person will not be sent a double opt-in email from MailChimp. If you want them to get one, add them via MailChimp and FFCRM will be updated when they confirm by clicking the link in the email.

## Limitations

* This plugin will only sync a contact’s main email address . You can’t, for example, have a contact subscribed to one list with their primary email address and another list with their alternative email address.
* This plugin only syncs FFCRM contacts (not accounts or other objects).
* The plugin can only keep First Name, Last Name and Email Address in sync (not other custom fields)
* If you rename a list in MailChimp (but don’t change it’s ID) the integration will keep working. However, the name of the checkbox in FFCRM used for that list will still have the old name. If you want to fix that you need to reset everything and grab MailChimp data again.
* You can’t use this plugin to batch subscribe you FFCRM contacts to MailChimp. Partly because that is not something we need (we want MailChimp to be the final word in who is on a list) and partly because it’s dangerous (could get your MailChimp account flagged)


## Todo

* Add support for cleaned addresses
* Add support for creating a 'campaign sent' note on the contact.
* Resolve the case where there are two contacts in FFCRM with the same email address - form should not pass validation if a mailchimp list is checked and there is a duplicate email address. This seems like the best compromise as it allows you to have contacts with duplicate emails in FFCRM but NOT if that affects MailChimp.
