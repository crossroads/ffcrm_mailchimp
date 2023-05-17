FfcrmMailchimp CHANGELOG

2023-05-16

- Created changelog
- Major refactoring to replace Mailchimp API v2 with v3 (not backwards)
- Changed api_key to webhook_key to make clear they should be separate
- Switched FfcrmMailchimp::Logger to output to log/ffcrm_mailchimp.log
- Added error handling for Mailchimp API responses. Write errors to log
