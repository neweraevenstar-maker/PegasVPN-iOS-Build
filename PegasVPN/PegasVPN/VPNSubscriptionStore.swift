import Foundation
import Combine
import StoreKit

@MainActor
final class VPNSubscriptionStore: ObservableObject {
    static let shared = VPNSubscriptionStore()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isSubscribed = false
    @Published private(set) var accessStatus: VPNAccessStatus?

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let productIDs: Set<String> = [
        "com.pegasvpn.subscription.monthly",
        "com.pegasvpn.subscription.yearly"
    ]

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    do {
                        try await VPNBillingClient.verify(result)
                        await transaction.finish()
                        await self?.refreshStatus()
                    } catch {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
            await refreshStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        guard VPNDisclosure.isAccepted else {
            errorMessage = "Review VPN data disclosure before subscribing."
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let buyer = try await VPNBillingClient.accountToken()
            let result = try await product.purchase(
                options: [.appAccountToken(buyer)]
            )

            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "Purchase verification failed"
                    return
                }
                try await VPNBillingClient.verify(verification)
                await transaction.finish()
                await refreshStatus()
                await loadAccessStatus()
                errorMessage = nil

            case .pending:
                errorMessage = "Purchase is pending approval"

            case .userCancelled:
                break

            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadAccessStatus() async {
        do {
            accessStatus = try await VPNBillingClient.accessStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshStatus()
            await loadAccessStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshStatus() async {
        var active = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil
            else { continue }

            if let expiration = transaction.expirationDate,
               expiration > Date() {
                do {
                    try await VPNBillingClient.verify(result)
                    await transaction.finish()
                    active = true
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }

        isSubscribed = active
    }
}
