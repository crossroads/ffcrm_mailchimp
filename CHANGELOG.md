FfcrmMailchimp CHANGELOG

2023-05 v1.0.1

- Created changelog
- Major refactoring to replace Mailchimp API v2 with v3 (not backwards)
- Changed api_key to webhook_key to make clear they should be separate
- Switched FfcrmMailchimp::Logger to output to log/ffcrm_mailchimp.log
- Added error handling for Mailchimp API responses. Write errors to log
- Admin: cache buttons now only clear cache and don't repopulate it
- Admin: added ability to sync specific Mailchimp contacts into CRM (useful if they are out of sync)
- Flattened Member module into WebhookParams

2023-05 v2.0.0
- Major upgrade to Rails 6.1 / FatFreeCRM 0.20.1