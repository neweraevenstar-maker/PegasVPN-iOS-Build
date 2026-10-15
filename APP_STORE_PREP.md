# PegasVPN — App Store content prepared before Apple Developer approval

**Draft only. Do not submit before real iPhone/TestFlight verification.**
Owner: VIM VITAE LIMITED (Hong Kong). Bundle: `com.pegasvpn.app`.

## Proposed listing (English)

**Name:** PegasVPN  
**Subtitle:** Secure WireGuard VPN  
**Category:** Utilities

**Description:**

PegasVPN provides a simple way to connect to a WireGuard VPN from your
iPhone. Tap START to connect and STOP to disconnect.

- Simple VPN connection controls and connection status
- Secure WireGuard tunnel configuration
- Sign in with Apple or email
- Subscription management and Restore Purchases
- Local IPv4 network exclusion settings

Available VPN locations depend on active server capacity. Additional
countries will be introduced only after they are configured and tested.

**Subscription terms:** The app displays Apple's actual price and billing
period for each plan. Eligible new subscribers may receive a 7-day
introductory free trial; the subscription then renews automatically until
cancelled. Manage or cancel it in Apple Account > Subscriptions.

## Предлагаемое описание (русский)

**Название:** PegasVPN  
**Подзаголовок:** VPN на базе WireGuard

PegasVPN — приложение для подключения к VPN на iPhone. Нажмите START,
чтобы подключиться, и STOP, чтобы отключиться.

- Простое управление VPN-соединением
- Защищённый туннель WireGuard
- Вход через Apple или электронную почту
- Управление подпиской и восстановление покупок
- Локальные исключения IPv4-сетей

Список доступных стран зависит от подключённых и проверенных серверов.
Новые страны появятся после настройки инфраструктуры.

**Подписка:** Цена и период оплаты показываются в приложении на основе
данных Apple. Для подходящих новых подписчиков может быть доступен
7-дневный бесплатный пробный период. Затем подписка продлевается
автоматически до отмены в настройках Apple.

## Screenshot plan (real device screenshots, not mock product claims)

1. START / STOP and clear connection status
2. Active WireGuard VPN connection
3. Apple/email account sign-in
4. Real StoreKit subscription prices and eligible introductory trial
5. Account, Restore Purchases and network exclusion settings

## App Review preparation

- Explain VPN traffic routing and Network Extension use accurately.
- Provide a working review flow on an actual iPhone and test account
  details if required; do not invent review credentials.
- Ensure the subscription group contains the exact IDs:
  `com.pegasvpn.subscription.monthly` and
  `com.pegasvpn.subscription.yearly`.
- Base plan agreed: USD 1/month, USD 10/year; introductory trial 7 days.
  StoreKit is the source of truth for displayed local price and eligibility.
- Complete Apple Paid Apps Agreement, tax/banking information,
  app signing, TestFlight, privacy labels, terms and support URL.
- Review country-by-country VPN and payment restrictions before enabling
  Russia or China. Do not advertise unconfigured countries.
- Avoid unverified claims such as "zero logs", "100% anonymous",
  "fastest VPN", or guaranteed access to blocked services.

## Outstanding company facts / URLs

- Privacy policy URL: **not provided**
- Terms of service URL: **not provided**
- Support URL and email: **not confirmed**
- Actual production logs, backup and retention periods: **not audited**
- Signed app, TestFlight and Apple subscription purchase: **pending
  Apple Developer approval and device testing**

**Infrastructure decision:** no Netherlands/Sweden/Lithuania/Switzerland/
Russia or other new VPN server until Apple Developer Program approval.
