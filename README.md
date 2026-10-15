# PegasVPN — iOS application

Public source mirror containing only the SwiftUI iOS application,
Packet Tunnel extension and build configuration. **No production VPN
server source, secrets, Apple signing credentials or customer data.**

## Current source capabilities

- START/STOP WireGuard connection and VPN status
- Sign in with Apple or email OTP, plus guest account mode
- StoreKit 2 monthly/yearly subscription UI and Restore Purchases
- Verified sign-in required before a new paid subscription
- Per-installation random device UUID for distinct server VPN peers
- Local IPv4/CIDR network exclusions and account deletion

GitHub Actions can build an **unsigned IPA**. A successful build does
not prove VPN traffic, Apple payments, or device behavior. App Store
signing, TestFlight, Apple subscription products and the real-device
acceptance test remain pending Apple Developer approval.

**New country servers are deferred until Apple Developer approval.**
Only configured, tested locations may be advertised as available.

See [RELEASE_ROADMAP.md](RELEASE_ROADMAP.md) for the current source and
verification status and [APP_STORE_PREP.md](APP_STORE_PREP.md) for
provisional store metadata and legal-content blockers.
