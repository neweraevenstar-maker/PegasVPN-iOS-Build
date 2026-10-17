# PegasVPN customer operations — release draft

Operator: VIM VITAE LIMITED (Hong Kong). Support: info@vimvitae.net (mailbox exists; live monitoring and response SLA unverified).

## Support handling
- Never request OTPs, passwords, WireGuard private keys, Apple identity tokens or payment card numbers.
- Accept a case via email; record issue category, date, app version, and minimum required account reference. Redact network identifiers and secrets from diagnostic attachments.
- For a login problem: confirm account identity through the existing sign-in flow; resend a time-limited OTP; do not bypass verification.
- For connection problems: check account entitlement and current service status; offer a diagnostic export only with the user's consent.
- Escalate suspected privacy/security incidents to the operator; preserve only necessary evidence and follow applicable notification rules.

## Billing and refunds
- Prices and trial eligibility must come from Apple's purchase sheet, not hard-coded promises.
- Apple manages auto-renewing subscriptions; direct users to https://apps.apple.com/account/subscriptions for cancellation.
- Direct Apple purchase refund requests to https://reportaproblem.apple.com/; do not promise an outcome or imply account deletion cancels billing.
- For Restore Purchases, require the customer's verified account and use the app's Restore Purchases control. Never manually grant paid access without a verified entitlement.

## Deletion
- In-app Account > Delete account revokes the account's WireGuard access and removes live identity records according to backend implementation.
- Explain separately that Apple billing is not cancelled by account deletion.
- Paid purchase-recovery mapping and backup copies require the approved retention policy and data-subject request handling.
- For privacy requests, confirm identity through a safe channel and document the decision, action and applicable legal basis.

## Launch prerequisites
Confirm support inbox ownership, real response capacity, public URLs, approved legal documents, server retention and backup procedures. This file is an operational procedure draft, not evidence that a staffed support service is running.
