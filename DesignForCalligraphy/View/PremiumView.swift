import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State var selectedPlanID = "Monthly"
    var body: some View {
        HStack(spacing: 0) {
            // Left Side Features
            ZStack {
                Image("girl")
                    .resizable()
                    .scaledToFill()
                
                FeaturesListView()
            }
            .frame(width: 409.5)

            // Right Side Subscription Options
            SubscriptionOptionsView(viewModel: viewModel, selectedPlanID: $selectedPlanID)
                .frame(width: 409.5)
        }
        .frame(width: 819, height: 622)
         .onAppear {
            viewModel.loadProducts()
        }
    }
}

struct FeaturesListView: View {
    let features = [
        "20,000+ Designs",
        "High Quality Exports",
        "Advanced Editing Tools",
        "Premium Fonts and Stickers",
        "Sublimation Graphics",
        "Unlimited SVGs"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            ForEach(features, id: \.self) { feature in
                FeatureRow(text: feature)
            }
            Spacer()
        }
        .padding(.leading, 40)
        .padding(.trailing, 20)
    }
}

struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image("hand")
                .resizable()
                .frame(width: 20, height: 20)
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
        }
    }
}

struct SubscriptionOptionsView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Binding var selectedPlanID: String
    let options: [SubscriptionOption] = [
        .init(title: "Weekly", price: "$68.63", label: "Basic"),
        .init(title: "Monthly", price: "$68.63", label: "Free trial"),
        .init(title: "Yearly", price: "$68.63", label: "35% Off"),
        .init(title: "Lifetime", price: "$68.63", label: "74% Off")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Unlock Limitless Features")
                .font(.title)
                .fontWeight(.bold)

            Text("Unlock the full power of your creativity")
                .foregroundColor(.gray)
                .font(.subheadline)
            if viewModel.products.isEmpty {
                ForEach(options) { option in
                    SubscriptionRow(option: option, isSelected: selectedPlanID == option.title)
                        .onTapGesture {
                            selectedPlanID = option.title
                        }
                }
            }
            else {
                ForEach(viewModel.products) { product in
                    SubscriptionRowForProduct(product: product, isSelected: viewModel.selectedProduct?.id == product.id)
                        .onTapGesture {
                            viewModel.select(product: product)
                        }
                }
            }
            if let selected = viewModel.selectedProduct {
                Text("Try Free for 3 days then \(selected.displayPrice)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            Button(action: {
                viewModel.purchaseSelected()
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("selectedColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
            .buttonStyle(.plain)
            ScrollView {
                Text("Subscription automatically renew unless canceled before the end of the current period. You won't be charged if you cancel during the trial period.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            HStack(spacing: 15) {
                if let url = URL(string: termsOfUseLink) {
                    Link("Terms of Use", destination: url)
                }
                Text("|")
                Text("Restore")
                    .onTapGesture {
                        viewModel.restorePurchases()
                    }
                Text("|")
                if let url = URL(string: privacyPolicyLink) {
                    Link("Privacy Policy", destination: url)
                }
            }
            .font(.caption2)
            .foregroundColor(.gray)
            .padding(.top, 4)
        }
        .padding()
    }
}
struct SubscriptionRowForProduct: View {
    let product: Product
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(isSelected ? "selectedCircle" : "circle")
                .resizable()
                .frame(width: 24, height: 24)

            VStack(alignment: .leading) {
                Text(product.displayName)
                    .fontWeight(.medium)
                Text(product.displayPrice)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()

            if let period = product.subscription?.subscriptionPeriod {
                let label = localizedSubscriptionPeriod(period)
                Text(label)
                    .font(.caption)
                    .padding(6)
                    .background(isSelected ? Color("orange"): Color("screenBg"))
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(isSelected ? Color("selectionLight") : .white)
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color("selectedColor") : Color("border"), lineWidth: 1)
        }
    }
    func localizedSubscriptionPeriod(_ period: Product.SubscriptionPeriod) -> String {
        let unit: String
        switch period.unit {
        case .day: unit = period.value == 1 ? "day" : "days"
        case .week: unit = period.value == 1 ? "week" : "weeks"
        case .month: unit = period.value == 1 ? "month" : "months"
        case .year: unit = period.value == 1 ? "year" : "years"
        @unknown default: unit = "period"
        }
        return "\(period.value) \(unit)"
    }

}
struct SubscriptionOption: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let label: String?
}

struct SubscriptionRow: View {
    let option: SubscriptionOption
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(isSelected ? "selectedCircle" : "circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading) {
                Text(option.title)
                    .fontWeight(.medium)
                Text(option.price)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()

            if let label = option.label {
                Text(label)
                    .font(.caption)
                    .padding(6)
                    .background(isSelected ? Color("orange"): Color("screenBg"))
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(isSelected ? Color("selectionLight") : .white)
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color("selectedColor") : Color("border"), lineWidth: 1)
        }
    }
}
class SubscriptionViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var selectedProduct: Product?

    func loadProducts() {
        Task {
            do {
                let storeProducts = try await Product.products(for: ["com.newapp.weekly", "com.newapp.monthly", "com.newapp.yearly", "com.newapp.lifetime"])
                await MainActor.run {
                    self.products = storeProducts
                    self.selectedProduct = storeProducts.first
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
                print("Purchase result: \(result)")
            } catch {
                print("Purchase failed: \(error)")
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
}
