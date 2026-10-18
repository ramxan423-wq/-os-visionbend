import Foundation
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var errorMessage: String?
    // Add the approved App Store Connect identifiers before offering subscriptions.
    private let identifiers: [String] = []

    func load() async {
        guard !identifiers.isEmpty else {
            errorMessage = "Configure subscription products in App Store Connect first."
            return
        }
        do {
            products = try await Product.products(for: identifiers)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            if case .success(.verified(let transaction)) = result {
                await transaction.finish()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do { try await AppStore.sync() }
        catch { errorMessage = error.localizedDescription }
    }
}
