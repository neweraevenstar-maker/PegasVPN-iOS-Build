import Foundation

enum VPNProvisioningValidationError: LocalizedError {
    case emptyConfiguration
    case oversizedConfiguration
    case invalidServer
    case expiredConfiguration

    var errorDescription: String? {
        switch self {
        case .emptyConfiguration:
            return "Empty VPN configuration"
        case .oversizedConfiguration:
            return "VPN configuration is too large"
        case .invalidServer:
            return "Invalid VPN server"
        case .expiredConfiguration:
            return "VPN configuration has expired"
        }
    }
}

enum VPNProvisioningValidation {
    static let maximumConfigurationBytes = 65536

    static func validate(
        configuration: String,
        expiry: VPNConfigurationExpiry? = nil
    ) throws {
        guard !configuration.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            throw VPNProvisioningValidationError.emptyConfiguration
        }

        guard configuration.utf8.count <= maximumConfigurationBytes else {
            throw VPNProvisioningValidationError.oversizedConfiguration
        }

        if expiry?.isExpired == true {
            throw VPNProvisioningValidationError.expiredConfiguration
        }

        try VPNConfigurationValidator.validate(configuration)
    }
}
