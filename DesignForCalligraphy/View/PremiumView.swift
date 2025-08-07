import SwiftUI
import StoreKit
import SDWebImageSwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var viewModel : SubscriptionViewModel
    @State var selectedPlanID = "Monthly"
    @Binding var showPremium : Bool
    var body: some View {
        HStack(spacing: 0) {
            // Left Side Features
            ZStack {
                if let gifURL = viewModel.gifURL {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 301, height: 671)
                        .clipped()
                } else {
                    Image("girl")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 301, height: 671)
                }
                FeaturesListView()
                Image("cross")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .offset(x: -120, y: -280)
                    .onTapGesture {
                        showPremium = false
                    }
            }
            .frame(width: 301)
            // Right Side Subscription Options
            SubscriptionOptionsView(viewModel: viewModel, selectedPlanID: $selectedPlanID)
                .frame(width: 518)
        }
        .onChange(of: viewModel.isProductPurchased) { newVal in
            if newVal {
                showPremium = false
            }
        }
        .frame(width: 819, height: 671)
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
        VStack(alignment: .leading, spacing: 40) {
            Spacer()
            Text("What will you get?")
                .foregroundColor(.white)
                .font(.custom(Fonts.bold.rawValue, size: 22))
            VStack(alignment: .leading, spacing: 30) {
                ForEach(features, id: \.self) { feature in
                    FeatureRow(text: feature)
                }
            }
            Spacer()
        }
        .padding(.leading, 30)
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
                .font(.custom(Fonts.medium.rawValue, size: 16))
        }
    }
}

struct SubscriptionOptionsView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Binding var selectedPlanID: String
    let options: [SubscriptionOption] = [
        .init(title: "Weekly", price: "$___", label: "Basic"),
        .init(title: "Monthly", price: "$___", label: "Free trial"),
        .init(title: "Yearly", price: "$___", label: "35% Off"),
        .init(title: "Lifetime", price: "$___", label: "74% Off")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("Unlock Limitless Features")
                .foregroundStyle(.black)
                .font(.custom(Fonts.bold.rawValue, size: 30))
            Text("Unlock the full power of your creativity")
                .foregroundStyle(Color("premiumgrey"))
                .font(.custom(Fonts.medium.rawValue, size: 18))
                .padding(.top, 5)
            if viewModel.products.isEmpty {
                VStack(spacing: 5) {
                    ForEach(options) { option in
                        SubscriptionRow(option: option, isSelected: selectedPlanID == option.title)
                            .onTapGesture {
                                selectedPlanID = option.title
                            }
                    }
                }
                .padding(.top, 30)
            }
            else {
                VStack(spacing: 5) {
                    ForEach(viewModel.products) { product in
                        SubscriptionRowForProduct(prodcutName: product.planName(from: productIDs),product: product, isSelected: viewModel.selectedProduct?.id == product.id, planType: product.planType(comparedTo: viewModel.products))
                            .onTapGesture {
                                viewModel.select(product: product)
                            }
                    }
                }
                .padding(.top, 30)
            }
           
            if let selected = viewModel.selectedProduct {
                if let trialText = selected.trialDescription {
                    Text(trialText)
                        .font(.custom(Fonts.medium.rawValue, size: 16))
                        .foregroundStyle(.black)
                        .padding(.top, 30)
                } else {
                    Text("No Commitment, Cancel Any Time")
                        .font(.custom(Fonts.medium.rawValue, size: 16))
                        .foregroundStyle(.black)
                        .padding(.top, 30)
                }
            }
            else {
                Text("No Commitment, Cancel Any Time")
                    .font(.custom(Fonts.medium.rawValue, size: 16))
                    .foregroundStyle(.black)
                    .padding(.top, 30)
            }

            Button(action: {
                if viewModel.products.isEmpty {
                    showAlert(title: "Error!", message: "There is some issue with the product please try again")
                }
                else {
                    viewModel.purchaseSelected()
                }
            }) {
                Text("Continue")
                    .font(.custom(Fonts.medium.rawValue, size: 16))
                    .frame(width: 458, height: 42)
                    .background(Color("selectedColor"))
                    .foregroundColor(.white)
                    .cornerRadius(100)
            }
            .padding(.top, 11)
            .buttonStyle(.plain)
            Text("Subscription automatically renew unless canceled before the end of the current period. You won't be charged if you cancel during the trial period.")
                .foregroundStyle(Color("premiumgrey"))
                .font(.custom(Fonts.regular.rawValue, size: 12))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 30)
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
            .padding(.top, 13)
            .foregroundStyle(Color("premiumgrey"))
            .font(.custom(Fonts.regular.rawValue, size: 12))
            
        }
    }
}
struct SubscriptionRowForProduct: View {
    let prodcutName: String
    let product: Product
    let isSelected: Bool
    let planType: String
    var body: some View {
        HStack(spacing: 0) {
            Image(isSelected ? "selectedCircle" : "circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding(.leading, 18)
            VStack(alignment: .leading, spacing: 10) {
                Text(product.displayName == "" ? prodcutName : product.displayName)
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.medium.rawValue, size: 18))
                Text(product.displayPrice)
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.bold.rawValue, size: 20))
            }
            .padding(.leading, 20)
            Spacer()
                Text(planType)
                    .font(.custom(Fonts.medium.rawValue, size: 16))
                    .padding(8)
                    .frame(width: 104, height: 42)
                    .background(isSelected ? Color("orange"): Color("screenBg"))
                    .foregroundColor(.black)
                    .cornerRadius(100)
                    .padding(.trailing, 18)
        }
        .frame(width: 478, height: 70)
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
        HStack(spacing: 0) {
            Image(isSelected ? "selectedCircle" : "circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding(.leading, 18)
            VStack(alignment: .leading, spacing: 10) {
                Text(option.title)
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.medium.rawValue, size: 18))
                    
                Text(option.price)
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.bold.rawValue, size: 20))
            }
            .padding(.leading, 20)
            Spacer()

            if let label = option.label {
                Text(label)
                    .padding(8)
                    .frame(width: 104, height: 42)
                    .background(isSelected ? Color("orange"): Color("screenBg"))
                    .foregroundColor(.black)
                    .font(.custom(Fonts.medium.rawValue, size: 16))
                    .cornerRadius(100)
                    .padding(.trailing, 18)
                    
            }
        }
        .frame(width: 478, height: 70)
        .background(isSelected ? Color("selectionLight") : .white)
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color("selectedColor") : Color("border"), lineWidth: 1)
        }
    }
}
