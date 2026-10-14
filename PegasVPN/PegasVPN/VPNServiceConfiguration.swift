import Foundation

enum VPNServiceConfiguration {
    // Заполним после согласования с серверным API.
    static let provisioningEndpoint: URL? =
        URL(string: "https://api.vimvitae.net/vpn/provision")

    // Авторизация должна выдаваться сервером после
    // подтверждения пользователя/подписки.
    // Токены нельзя встраивать в исходный код приложения.
    static var isProvisioningConfigured: Bool {
        provisioningEndpoint != nil
    }
}
