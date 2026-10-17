# StoreKit 2 — pre-enrollment implementation

Local Xcode StoreKit configuration: `PegasVPN/PegasVPN.storekit`.
Both subscription IDs match `VPNSubscriptionStore`:
- `com.pegasvpn.subscription.monthly` — USD 1 per month
- `com.pegasvpn.subscription.yearly` — USD 10 per year

One subscription group, seven-day introductory free trial on both plans. Apple eligibility is determined at the **group** level; this is not two separate trials. Xcode local pricing is illustrative; the app uses StoreKit's localized product prices.

The iOS app already supports verified purchase, explicit Restore Purchases, current entitlement refresh, and backend signed-transaction verification. Transaction updates now refresh backend access status, and returning to foreground reconciles again. The server `/access/status` remains the authority for VPN connectivity and revocation; local StoreKit status alone never grants a VPN tunnel.

To run locally on a Mac after XcodeGen generation: edit the PegasVPN scheme > Run > Options > StoreKit Configuration and select `PegasVPN.storekit`. This file is **not** a live App Store Connect product configuration. Local Xcode purchases cannot prove that production backend Apple verification works: local StoreKit test certificates/transactions may not be accepted by production verification.

Still requires Apple Developer approval: live subscription group/products and seven-day introductory offers in App Store Connect, paid agreements, signing, TestFlight and live Apple Server Notifications configuration. Production revocation and server deployment are separate tasks, not completed by this local file.

No production server was changed.
