# PegasVPN — missing App Store Connect listing fields

This file complements APP_STORE_PREP.md. Existing English/Russian descriptions, name, subtitle and screenshot plan remain unchanged. **Not approved for publication** until App Store review checks are complete.

## English (en-US)
**Keywords (comma-separated, <=100 characters):**
wireguard,privacy,network,secure connection,tunnel,connection,security

**Promotional text (<=170 characters):**
Connect with a tap using WireGuard. Manage your VPN connection, account and subscription in one place.

**What's New (initial release, optional):**
First release of PegasVPN for iPhone with WireGuard connectivity, account sign-in and subscription management.

## Russian (ru-RU)
**Ключевые слова (через запятую, <=100 символов):**
вайргард,защита,сеть,соединение,безопасность,туннель,приватность

**Рекламный текст (<=170 символов):**
Подключайтесь к VPN одним нажатием. Управляйте соединением WireGuard, аккаунтом и подпиской в одном приложении.

**Что нового (для первой версии, необязательно):**
Первый выпуск PegasVPN для iPhone: подключение WireGuard, вход в аккаунт и управление подпиской.

## Screenshot copy — captions only, not screenshots
1. One tap to connect / Подключение одним нажатием
2. See your connection status / Статус соединения
3. Sign in with Apple or email / Вход через Apple или почту
4. Manage your subscription / Управление подпиской
5. Configure network exclusions / Настройка исключений сети

**Screenshot acceptance:** capture from the final installed iOS app at a supported App Store Connect screenshot size; display actual working UI and actual StoreKit product details. Never fabricate a connected state, country, price, or trial eligibility. No finished screenshots are claimed here.

## App Review notes (draft)
PegasVPN uses NetworkExtension Packet Tunnel with WireGuard. The VPN permission is requested when a connection is configured. Authentication supports Sign in with Apple, six-digit email OTP, and guest mode. Subscription purchase requires an authenticated account. The app offers Restore Purchases and in-app account deletion. VPN traffic and account-data disclosure is presented before use. Subscription availability and pricing are loaded from StoreKit; server access is checked before connecting. Provide a working reviewer account or review procedure only after deployment is verified. Do not submit invented credentials.
