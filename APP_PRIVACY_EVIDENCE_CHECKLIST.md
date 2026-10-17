# PegasVPN App Privacy — evidence checklist (not final Apple answers)

Do **not** mark data as 'not collected' or assert 'no logs' until production logging and retention are audited. Apple privacy declarations cover data collected by the app **and third-party SDKs / services**; collected data and tracking are separate questions.

| Data category to evaluate in App Store Connect | Observed in client/backend integration | What must be verified before submission |
| --- | --- | --- |
| Contact info — email address | Email OTP login accepts email | Backend storage, processors, retention, deletion and purpose |
| Identifiers — user ID | Apple identity, account token and guest account | Whether identifiers qualify as user IDs and whether linked to identity |
| Identifiers — device ID | Random installation identifier and WireGuard public key | Apple's definition, persistence and account linkage |
| Purchases | StoreKit signed transactions and backend verification | Stored transaction history and linking to account |
| Diagnostics | In-app diagnostic event log/export | Whether reports leave the device automatically, analytics/crash services |
| Usage data | Access/status and provisioning calls | Server access logs, analytics, event retention |
| Other data / network traffic | VPN tunnel processes selected traffic | Actual logging, destination and retention of VPN traffic and metadata |
| Location | VPN endpoint and network metadata can reveal approximate location | Whether IP geolocation is stored/used |
| Tracking | No tracking SDK established from this file | Audit dependencies, SDK manifests and all third-party data uses |

For every confirmed collected category, document: linked to user (yes/no), used for tracking (yes/no), purpose (app functionality, security, analytics, etc.), data controller/processor, collection mechanism, and retention/deletion. Obtain actual answers from production infrastructure and published privacy policy.

## Required public links
- Privacy Policy URL: missing, must be published and accessible without login
- Support URL: missing, must resolve to an actual support page
- Terms URL: missing, must be published for customer access
- Support email: info@vimvitae.net is a proposed company mailbox; verify it is monitored

## Existing verified behaviors from source
- User can request account deletion in the app.
- Account deletion removes VPN access but **does not** cancel Apple's subscription.
- StoreKit purchases are verified against the service backend.
- The app discloses VPN routing and possible connection metadata observation.

**Blocker:** Do not finalize Apple App Privacy questionnaire or publish final privacy promises until actual production data retention and third-party processing are verified.
