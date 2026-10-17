# PegasVPN retention verification — 2026-10-16

This is a source-code inspection, **not a production-server audit**. No production configuration was changed. The following values must not be described as observed live retention.

| Record | Source-enforced duration / cleanup | Live verification |
|---|---|---|
| Email OTP | Expires after 10 minutes according to backend policy draft; expired rows deleted by `retention.purge()` when scheduled | OTP TTL and cleanup timer must be checked on server |
| Access sessions | Backend draft states 24-hour validity; expired rows deleted by scheduled purge; revoked sessions removed after 7 days | Token settings and timer unverified |
| Refresh tokens | Backend draft states up to 365 days; expired rows deleted by purge | Unverified |
| Rate-limit counters | Hourly counters older than 2 hourly windows removed; provisioning counters older than 24 hours removed | Timer unverified |
| App-owned `logs/*.log` | Proposed 7 days; only applied when `PEGASVPN_LOCAL_LOG_RETENTION_DAYS=7` and purge executes | Unverified |
| Apple notification records | Proposed 180 days; only applied when `PEGASVPN_NOTIFICATION_RETENTION_DAYS=180` and purge executes | Unverified |
| Deleted-account purchase recovery | Proposed minimum 30 days after deletion **and only once entitlement expired**; `PEGASVPN_PAID_RECOVERY_RETENTION_DAYS=30` | Unverified; requires owner/legal approval |
| WireGuard peer config backup | Source retains at most 10 local peer-config backups; **count is not time** | Live history unverified |
| SQLite/off-host backups | 30 days proposed in backend draft, no verified production enforcement | Unknown |
| Nginx, Uvicorn, journald, system logs | 7 days proposed, not enforced by `retention.py` | Unknown |
| Hosting and SMTP provider records | Provider-specific | Unknown |

## Read-only evidence required to finalize

1. Verify actual production service deployment version, environment variable names and whether retention and peer-sync timers are enabled. Do not copy secrets into tickets, chat or GitHub.
2. Inspect live SQLite schema and record-age distribution using read-only access; do not extract email addresses, tokens or user IPs.
3. Inspect Nginx, journald and app log retention policies, WireGuard backup locations, external backup lifecycles and email delivery-provider retention terms.
4. Confirm the proposed 7 / 180 / 30-day periods with the company owner and applicable legal requirements.
5. Only then update the public privacy notice to state **verified** retention and remove draft warnings. Verify live URLs and the monitored support inbox.

Sources: backend `retention.py`, `PRE_APPLE_RETENTION_POLICY_DRAFT.md`, `PRIVACY_DATA_INVENTORY.md` and `scripts/activate_pre_apple_services.sh`.

Apple App Review: https://developer.apple.com/app-store/review/guidelines/
Hong Kong PCPD: https://www.pcpd.org.hk/english/data_privacy_law/ordinance_at_a_Glance/ordinance.html
