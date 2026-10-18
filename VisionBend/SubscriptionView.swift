import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var store = StoreManager()

    var body: some View {
        List {
            Section("Subscriptions") {
                if store.products.isEmpty {
                    Text("No subscriptions available. Products must first be configured in App Store Connect.")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.products, id: \.id) { product in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.displayName).font(.headline)
                        Text(product.description).font(.caption)
                        Text(product.displayPrice)
                        Button("Subscribe") { Task { await store.purchase(product) } }
                    }
                }
            }
            Section {
                Button("Restore Purchases") { Task { await store.restore() } }
                if let error = store.errorMessage { Text(error).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Premium")
        .task { await store.load() }
    }
}
