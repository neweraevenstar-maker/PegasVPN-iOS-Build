import SwiftUI
import StoreKit

struct VPNSubscriptionView: View {
    @StateObject private var store = VPNSubscriptionStore.shared

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

                ForEach(store.products, id: \.id) { product in
                    Button {
                        Task { await store.purchase(product) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.displayName)
                                    .font(.headline)
                                Text(product.description)
                                    .font(.caption)
                            }
                            Spacer()
                            Text(product.displayPrice)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(store.isLoading)
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

                Button("Restore Purchases") {
                    Task { await store.restorePurchases() }
                }

                Text("Subscriptions renew automatically until cancelled. Manage or cancel in your Apple Account settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .navigationTitle("Subscription")
        .task {
            await store.loadProducts()
            await store.loadAccessStatus()
        }
    }
}
