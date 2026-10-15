import SwiftUI
import StoreKit

struct VPNSubscriptionView: View {
    var vpnManager: VPNManager? = nil
    @StateObject private var store = VPNSubscriptionStore.shared
    @AppStorage(VPNDisclosure.acceptedKey) private var disclosureAccepted = false
    @AppStorage("PegasVPN.accountMethod") private var accountMethod = "guest"
    @State private var showDisclosure = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("PegasVPN Premium")
                    .font(.largeTitle.bold())

                Text("Secure, private VPN access")
                    .foregroundStyle(.secondary)

                if let access = store.accessStatus {
                    if access.trial_active {
                        Label(
                            "Trial VPN access active",
                            systemImage: "calendar.badge.clock"
                        )
                        .foregroundStyle(.green)

                        if let end = access.trial_ends_at {
                            Text("Trial access until: \(String(end.prefix(10)))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else if !access.subscription_active {
                        Text("Trial access ended. Choose a subscription.")
                            .foregroundStyle(.orange)
                    }
                }

                if store.isSubscribed {
                    Label("Subscription active",
                          systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("Choose your subscription")
                        .font(.headline)
                }

                if accountMethod == "guest" {
                    Label(
                        "Sign in with Apple or email before subscribing. "
                        + "A verified account helps you restore purchases "
                        + "and protects your subscription across devices.",
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.leading)

                    if let vpnManager {
                        NavigationLink {
                            VPNAccountView(vpnManager: vpnManager)
                        } label: {
                            Label(
                                "Sign in to subscribe",
                                systemImage: "person.crop.circle"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                ForEach(store.products, id: \.id) { product in
                    Button {
                        if disclosureAccepted {
                            Task { await store.purchase(product) }
                        } else {
                            showDisclosure = true
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(product.displayName)
                                    .font(.headline)
                                Spacer()
                                Text(product.displayPrice)
                                    .fontWeight(.semibold)
                            }

                            Text("Billed every \(billingPeriod(product)). Auto-renews until cancelled.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let trial = freeTrialPeriod(product) {
                                Text("\(trial) free for eligible new subscribers, then \(product.displayPrice) every \(billingPeriod(product)).")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(
                        store.isLoading || store.isSubscribed
                        || accountMethod == "guest"
                    )
                }

                if store.products.isEmpty && !store.isLoading {
                    Text("Subscriptions are currently unavailable. Please try again later.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Retry loading subscriptions") {
                        Task { await store.loadProducts() }
                    }
                }

                if store.isLoading {
                    ProgressView()
                }

                if let error = store.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                if let message = store.restoreMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("Restore Purchases") {
                    Task { await store.restorePurchases() }
                }
                .disabled(store.isLoading || accountMethod == "guest")

                Link(
                    "Manage or cancel Apple subscriptions",
                    destination: URL(string: "https://apps.apple.com/account/subscriptions")!
                )

                Text("Payment is charged to your Apple Account after any eligible free trial. Subscriptions renew automatically at the price and interval shown above unless cancelled at least 24 hours before renewal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .navigationTitle("Subscription")
        .sheet(isPresented: $showDisclosure) {
            VPNDisclosureView()
        }
        .task {
            await store.loadProducts()
            await store.loadAccessStatus()
        }
    }

    private func billingPeriod(_ product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else {
            return "billing period"
        }
        return periodDescription(period)
    }

    private func freeTrialPeriod(_ product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else {
            return nil
        }
        return periodDescription(offer.period)
    }

    private func periodDescription(
        _ period: Product.SubscriptionPeriod
    ) -> String {
        let count = period.value
        let unit: String
        switch period.unit {
        case .day: unit = count == 1 ? "day" : "days"
        case .week: unit = count == 1 ? "week" : "weeks"
        case .month: unit = count == 1 ? "month" : "months"
        case .year: unit = count == 1 ? "year" : "years"
        @unknown default: unit = "periods"
        }
        return "\(count) \(unit)"
    }
}
