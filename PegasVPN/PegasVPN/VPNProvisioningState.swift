import Foundation

enum VPNProvisioningState: Equatable {
    case idle
    case requesting
    case validating
    case ready
    case failed(String)
}
