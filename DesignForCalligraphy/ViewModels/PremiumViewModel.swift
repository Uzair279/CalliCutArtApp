import SwiftUI
import StoreKit

class SubscriptionViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var selectedProduct: Product?
    @Published var isProductPurchased: Bool = false
    init() {
        Task {
            await checkPurchaseStatus()
        }
    }
    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            // Check for your product identifiers
            
            if productIDs.contains(transaction.productID) {
                // ✅ User has an active entitlement
                await MainActor.run {
                    self.isProductPurchased = true
                }
                saveProStatusToCoreData(true)
                return
            }
        }
        await MainActor.run {
            self.isProductPurchased = false
        }
        saveProStatusToCoreData(false)
    }
    func loadProducts() {
        Task {
            do {
                let storeProducts = try await Product.products(for: productIDs)

                // Sort products in the same order as `productIDs`
                let sorted = productIDs.compactMap { id in
                    storeProducts.first(where: { $0.id == id })
                }

                await MainActor.run {
                    self.products = sorted
                    self.selectedProduct = sorted[1]
                }
            } catch {
                print("Failed to load products: \(error)")
            }
        }
    }

    func select(product: Product) {
        selectedProduct = product
    }

    func purchaseSelected() {
        guard let product = selectedProduct else { return }
        Task {
            do {
                let result = try await product.purchase()
                switch result {
                case .success(_):
                    saveProStatusToCoreData(true)
                    await checkPurchaseStatus()
                case .userCancelled:
                    saveProStatusToCoreData(false)
                case .pending:
                    print(" Purchase pending")
                default:
                    saveProStatusToCoreData(false)
                }
            } catch {
                saveProStatusToCoreData(false)
            }
        }
    }


    func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
            } catch {
                print("Restore failed: \(error)")
            }
        }
    }
    func saveProStatusToCoreData(_ isPro: Bool) {
        let model = UserSaveModel(isPro: isPro)
        
        // Check if a user already exists
        let existing = CoreDataManager.shared.fetchUserModels()
        
        if existing.isEmpty {
            CoreDataManager.shared.saveUserModel(model)
            print("Saved new user with isPro = \(isPro)")
        } else {
            CoreDataManager.shared.updateUserModel(
                matching: { _ in true }, // update first found user
                update: { $0.isPro = isPro }
            )
            print("Updated user with isPro = \(isPro)")
        }
    }

}
