# App Store Connect — subscription display text

Complements STOREKIT_LOCAL_SETUP.md and APP_STORE_PREP.md. StoreKit is authoritative for localized price, billing period, and trial eligibility.

## Subscription group
Reference name: PegasVPN Premium
Display name: PegasVPN Premium
Description: Access the PegasVPN WireGuard VPN service.

## Monthly subscription
Product ID: `com.pegasvpn.subscription.monthly`
Reference name: PegasVPN Monthly
Display name (en): Monthly VPN
Description (en): PegasVPN access, billed monthly.
Display name (ru): VPN на месяц
Description (ru): Доступ к PegasVPN с ежемесячной оплатой.
Reference base price: USD 1/month, subject to App Store Connect pricing.

## Annual subscription
Product ID: `com.pegasvpn.subscription.yearly`
Reference name: PegasVPN Yearly
Display name (en): Yearly VPN
Description (en): PegasVPN access, billed yearly.
Display name (ru): VPN на год
Description (ru): Доступ к PegasVPN с ежегодной оплатой.
Reference base price: USD 10/year, subject to App Store Connect pricing.

## Introductory offer
Seven-day free trial for eligible new subscribers in the same subscription group, followed by the selected plan's auto-renewing price. Eligibility is determined by Apple; do not promise a new trial on plan switching.

## Purchase disclosure text
English: Your Apple Account will be charged at the displayed price after any eligible free trial. The subscription renews automatically unless cancelled at least 24 hours before the current period ends. Manage or cancel in Apple Account > Subscriptions. Deleting your PegasVPN account does not cancel an Apple subscription.

Russian: После доступного бесплатного периода Apple спишет указанную стоимость подписки. Подписка продлевается автоматически, если её не отменить не позднее чем за 24 часа до окончания текущего периода. Управлять подпиской можно в настройках учётной записи Apple. Удаление аккаунта PegasVPN не отменяет подписку Apple.

No live product has been created in App Store Connect by this document.
