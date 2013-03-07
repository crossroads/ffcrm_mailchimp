Setup
-----

1. Input your MailChimp API key and click “next”. We will go fetch the names of all the lists in your mailchimp account.
2. Add MailChimp integration to the lists you would like to integrate with FFCRM
3. That’s it! A new field will automatically be added to contacts so you can manage their MailChimp list subscriptions from FFCRM


### Important Notes


#### Deleting a list in MailChimp might not be enough

If you delete a list in MailChimp or disable its integration, that list will remain visible as a checkbox on FFCRM contacts and any existing data will remain untouched in FFCRM (the plugin doesn’t clean it out). To get rid of a list entirely clear all plugin settings and data in FFCRM, then reconfigure the plugin and finally, update your data again from MailChimp. 


#### You can mess with settings on the MailChimp side

You can fine tune the actions in MailChimp that will cause FFCRM to update by clicking “advanced” to edit MailChimp’s settings. 
If you remove and later re-add integration to a list, it will get the default settings so if you’d fine tuned them in MailChimp before you’d have to redo that.
We've not thought through all the implications of all the settings combinations you could choose in MailChimp so experiment at your own risk.

#### Contacts have to be valid

A MailChimp subscriber must have enough data to be valid in FFCRM or the FFCRM plugin will completely ignore it. By default, FFCRM requires a contact to have both a first name and a last name (this can be changed in FFCRM’s secret settings so ask your system administrator if you are not sure.) So, for example, if you add a subscriber to MailChimp without providing a first/last name, MailChimp will send the new subscriber data to FFCRM but FFCRM will ignore it (assuming you use FFCRM’s default settings).

#### We don't like duplicate email addresses
To stay sane, this plugin will not carry out an action if it will cause duplicate email addresses on different contacts in MailChimp (even though MailChimp itself allows this as long as the contacts are not on the same list).

* If you create/edit a contact in FCRM, the form will not pass validation if the primary email of that contact is the same as the primary email address of another contact AND both contacts have one or more MailChimp lists selected. This seemed like the best compromise as it allows you to have duplicate emails in FFCRM but NOT if that affects MailChimp.
* If MailChimp sends data to FFCRM (e.g. to subscribe a new user) the plugin will perform the same validation described above. If validation fails, the plugin will add a comment all affected contacts indicating the problem so someone can go resolve it.

### Update data from MailChimp
This will fetch all subscriber info for the lists that have integration enabled. It will create/update a contact in FFCRM for each (valid) one.
This is a simple, one-way update only. It only adds MailChimp data to FFCRM. It does not remove data from FFCRM or make any changes to MailChimp records. E.g. If James Smith is marked in FFCRM as subscribed to “Special Deals” but he is not subscribed in MailChimp (a case that can occur if you disable integration on a list), this update will not modify either FFCRM or MailChimp.

If your data is messed up you should first clear all settings and data, reconfigure your plugin and then update from MailChimp.

###Clear all settings and data###
This button starts by destroying any MailChimp subscriber info already in FFCRM and telling MailChimp we no longer want it to inform FFCRM of any subscriber changes. There is no “undo”.

This is great if you have changed MailChimp accounts or if you have deleted some MailChimp lists and/or generaly got your data way out of whack. You can start fresh, reconfigure the plugin and pull fresh dat from MailChimp.  

How it functions
----------------

###By default, the plugin will update FFCRM for the folowing MailChimp actions###

Note: This assumes you have not tweaked the advanced integration settings on the MailChimp side.

These actions can be perofrmed by a MailChimp subscriber, MailChimp Admin or MailChimp API

* Subscribes: will edit matching contact and log a history item or will create a new contact
* Unsubscribes: same as above
* Profiles Updates: same as above. Currently the plugin only synchronises FIrst Name, Last Name and email address.
* Cleaned Addresses: same as above. Note this does mean that MailChimp will remove the email address from your FFCRM contact.
* Email Changed: will automatically change the contact’s email address and will log a history item
* Campaign Sending: will just log a history item


### The plugin will update MailChimp for the following FFCRM actions performed on a contact###

Note: currently he plugin only synchronises First Name, Last Name and email address

* Subscribe: when a new contact is created or an existing one is edited and a MailChimp list is indicated
* Unsubscribe: Can happen when a contact is edited, deleted or merged (see below) 
* Profile Update: Can hapen when a contact is created or edited
* Merge two contacts: will delete one MailChimp contact and probably update another one (assuming it was changed in merge)

When you use FFCRM to subscribe someone to a MailChimp list, the person will not be sent a double opt-in email from MailChimp. If you want them to get one, add them via MailChimp and FFCRM will be updated when they confirm by clicking the link in the email

Note: If you change a contact in FFCRM and the plugin cannot update MailChimp for some reason (e.g. because you had deleted that MailChimp list without disabling its FFCRM integration) the plugin will undo the change to the contact  in FFCRM and will email you to inform you of the failure. So if I add “James Smith” to the “Daily Promotion” list but that list has been deleted from MailChimp then the plugin will later un-check the box for that list on James Smith and will email me to tell me what happened.


Limitations
-----------

* This plugin will only sync a contact’s main email address . You can’t, for example, have a contact subscribed to one list with their primary email address and another list with their alternative email address. 
* This plugin does syncs FFCRM contacts (not accounts or an other object).
* The plugin can only keep First Name, Last Name and Email Address in sync (not other custom fields)
* If you rename a list in MailChimp (but don’t change it’s ID) the integration will keep working. However, the name of the checkbox in FFCRM used for that list will still have the old name. If you want to fix that you need to reset everything and grab MailChimp data again.
* You can’t use this plugin to batch subscribe you FFCRM contacts to MailChimp. Partly because that is not something we need (we want MailChimp to be the final word in who is on a list) and partly because it’s dangerous (could get your MailChimp account flagged)
