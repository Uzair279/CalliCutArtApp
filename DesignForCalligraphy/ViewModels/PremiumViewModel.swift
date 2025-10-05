import SwiftUI
import StoreKit

class SubscriptionViewModel: ObservableObject {
    @Published
       private(set) var products: [Product] = []
    @Published var selectedProduct: Product?
    @Published var isProductPurchased: Bool = false
    @Published var gifURL: URL? = nil
    private var transactionUpdateTask: Task<Void, Never>? = nil
    @Published
       private(set) var purchasedProductIDs = Set<String>()
    var foundActiveSubscription = false
    init() {
        transactionUpdateTask = observeTransactionUpdates()
        self.downloadGif()
        Task {
            await checkPurchaseStatus()
        }
    }
    func downloadGif() {
        ensureGIFExists { result in
            switch result {
            case .success(let localPath):
                DispatchQueue.main.async {
                    self.gifURL = localPath
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await result in Transaction.updates {
                print("transaction updated observed")
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                await checkPurchaseStatus()
                await transaction.finish()
            }
        }
    }
    
    @MainActor
    func updatePurchaseStatus(isPurchased: Bool) {
        self.isProductPurchased = isPurchased
        self.saveProStatusToCoreData(isPurchased)
    }

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
                await updatePurchaseStatus(isPurchased: true)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
                await updatePurchaseStatus(isPurchased: false)
            }
        }
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
                    if !self.products.isEmpty {
                        self.selectedProduct = sorted[1]
                    }
                }
            } catch {
                print("Failed to load products: \(error)")
            }
        }
    }

    func select(product: Product) {
        selectedProduct = product
    }

    func purchaseSelected(compeletion: @escaping () -> Void) {
        guard let product = selectedProduct else { return }
        Task {
            do {
                let result = try await product.purchase()
                switch result {
                case .success(_):
                    saveProStatusToCoreData(true)
                    await checkPurchaseStatus()
                    compeletion()
                case .userCancelled:
                    saveProStatusToCoreData(false)
                    compeletion()
                case .pending:
                    print(" Purchase pending")
                    compeletion()
                default:
                    saveProStatusToCoreData(false)
                    compeletion()
                }
            } catch {
                saveProStatusToCoreData(false)
                compeletion()
            }
        }
    }


    func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                await checkPurchaseStatus()
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
