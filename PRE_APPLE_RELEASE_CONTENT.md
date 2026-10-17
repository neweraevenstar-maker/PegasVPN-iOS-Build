# PegasVPN — pre-Apple release content checklist

Status: prepared for implementation, not approved for App Store submission.
Company: VIM VITAE LIMITED (Hong Kong).

## Already implemented — do not recreate
- SwiftUI VPN controls and WireGuard Packet Tunnel
- Apple/email/guest sign-in and account deletion source flows
- StoreKit 2 subscription paywall, restore and management links
- VPN disclosure before use/purchase
- One configured Germany location; local IPv4 exclusions

## Outstanding release content
1. Finalize actual Privacy Policy and Terms based on verified production data collection, log and backup retention. Do not claim zero logs without evidence.
2. Publish public privacy, terms and support URLs controlled by the company.
3. Replace provisional URLs and wording in the app and App Store listing.
4. Produce screenshots from the final real device build after Apple Developer approval; do not present mockups as device screenshots.
5. Apply approved PegasVPN visual style consistently where current implementation differs, without recreating existing features.

## Agreed subscription terms
Monthly: USD 1; yearly: USD 10. Eligible customers: seven-day introductory free trial, then auto-renewal. StoreKit localized product metadata is authoritative for displayed price, eligibility and billing period. No unconditional free-trial promise.

## Deployment boundaries
No new Hetzner servers; no production restarts; no server secrets in this public repository. Signing, live subscription products and TestFlight require Apple Developer enrollment.
