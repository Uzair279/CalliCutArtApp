import SwiftUI
import SDWebImageSwiftUI
struct MainView: View {
    @ObservedObject var viewModel: CategoryViewModel
    let itemCount: Int
    let categoryID: String
    let subcategoryID: String
    let addNew: () -> Void
    let grdiAction: (String) -> Void
    let downloadAction: (String) -> Void
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    addNew()
                }) {
                    HStack {
                        Text("+ Create New")
                            .foregroundStyle(.white)
                            .font(.custom(Fonts.medium.rawValue, size: 16))
                    }
                    .frame(width: 142, height: 48)
                    .background(Color("purple"))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .opacity(0)
            }
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("purple"))
                .frame(height: 177)
                .overlay(
                    VStack(spacing: 12) {
                        Text("Explore More!")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        Text("Explore our gallery to find a selection of SVG crafted by our free members. They accessible for download by everyone.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                )
                .padding(.horizontal, 48)
            TabMenuView(
                categories: viewModel.categories,
                selectedCategoryID: $viewModel.selectedCategoryID
            )
            .offset(y: -60)


            GridView(itemCount: itemCount, categoryID: categoryID, subcategoryID: subcategoryID) { str in
                grdiAction(str)
            } downloadAction: { newStr in
                downloadAction(newStr)
            }
            .offset(y: -40)
            Spacer()
        }
        .padding(20)
        .background(Color("screenBg"))
    }
}


struct GridView: View {
    @EnvironmentObject var premiumVM : SubscriptionViewModel
    let itemCount: Int
    let categoryID: String
    let subcategoryID: String
    let action: (String) -> Void
    let downloadAction: (String) -> Void
    @State private var showSubscriptionSheet = false
    let columns = [
        GridItem(.adaptive(minimum: 148, maximum: 148), spacing: 27)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 32) {
                ForEach(0..<itemCount, id: \.self) { index in
                    Button(action: {
                        
                        if index > 2 && !isProuctPro {
                            if !premiumVM.isProductPurchased {
                                showSubscriptionSheet = true
                            }
                            else{
                                action("\(index)")
                            }
                        }
                        else {
                            action("\(index)")
                        }
                    }) {
                        ZStack (alignment: .center){
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                                .frame(width: 148, height: 199)
                                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                .clipped()
                            let pngURL = generatePNGURL(for: categoryID, subcategoryID: subcategoryID, itemID: index)
                            WebImage(url: URL(string: pngURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 148, height: 199)
                                    .background(Color.black.opacity(0.3))
                            }
                            
                            .frame(width: 148, height: 148)
                            if index > 2 && !isProuctPro {
                                if !premiumVM.isProductPurchased {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image("premiumIcon")
                                        .padding([.top, .trailing], 10)
                                }
                                Spacer()
                            }
                                }
                            }
                            VStack {
                                Spacer()
                                HStack(spacing: 10) {
                                    Spacer()
                                    Button(action:{
                                        downloadAction("\(index)")
                                    }) {
                                        Image("newDownload")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 35, height: 23)
                                    }
                                    
                                    .buttonStyle(.plain)
                                    Button(action:{
                                        action("\(index)")
                                    }) {
                                        Image("newEdit")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 35, height: 23)
                
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showSubscriptionSheet) {
                    // Present your SubscriptionView
                    SubscriptionView(showPremium: $showSubscriptionSheet)
                        .frame(width: 819, height: 622)
                }
    }

    private func generatePNGURL(for categoryID: String, subcategoryID: String, itemID: Int) -> String {
        let baseURL = "https://stepbystepcricut.s3.us-east-1.amazonaws.com/templates"
        let cat = categoryID.lowercased()
        let subCat = subcategoryID.lowercased()
        return "\(baseURL)/\(cat)/thumbnails/\(subCat)/thumbnail\(itemID).png"
    }
}



struct TabMenuView: View {
    let categories: [Category]
    @Binding var selectedCategoryID: String?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(categories) { category in
                let isFirst = categories.first == category
                let isLast = categories.last == category
                let isSelected = selectedCategoryID == category.title

                VStack(spacing: 6) {
                    Image(category.title ?? "")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(isSelected ? .white : .gray)

                    Text(category.title ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .white : .gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSelected ? Color("purple") : Color.white)
                .overlay(
                    isSelected ?
                        RoundedCornersShape(radius: 50, corners: cornerMask(isFirst: isFirst, isLast: isLast))
                            .stroke(Color("lightPurple"), lineWidth: 4)
                        : nil
                )
                .clipShape(
                    RoundedCornersShape(radius: 50, corners: cornerMask(isFirst: isFirst, isLast: isLast))
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCategoryID = category.title
                }

                if !isLast {
                    Divider()
                        .frame(width: 1)
                        .background(Color.gray)
                }
            }
        }
        .frame(width: 744, height: 95)
        .background(Color.white)
        .cornerRadius(50)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 0)
    }

    private func cornerMask(isFirst: Bool, isLast: Bool) -> CACornerMask {
        switch (isFirst, isLast) {
        case (true, false): return [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        case (false, true): return [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        default: return []
        }
    }
}


struct RoundedCornersShape: Shape {
    var radius: CGFloat
    var corners: CACornerMask   // Use Core Animation's mask instead of NSRectCorner

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tl = corners.contains(.layerMinXMinYCorner)
        let tr = corners.contains(.layerMaxXMinYCorner)
        let bl = corners.contains(.layerMinXMaxYCorner)
        let br = corners.contains(.layerMaxXMaxYCorner)

        let width = rect.width
        let height = rect.height

        // Start at bottom-left
        path.move(to: CGPoint(x: rect.minX + (bl ? radius : 0), y: rect.minY))

        // Bottom edge
        if br {
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addRelativeArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                                radius: radius,
                                startAngle: Angle(degrees: 270),
                                delta: Angle(degrees: 90))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        // Right edge
        if tr {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addRelativeArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                                radius: radius,
                                startAngle: Angle(degrees: 0),
                                delta: Angle(degrees: 90))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        // Top edge
        if tl {
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addRelativeArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                                radius: radius,
                                startAngle: Angle(degrees: 90),
                                delta: Angle(degrees: 90))
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        // Left edge
        if bl {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addRelativeArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                                radius: radius,
                                startAngle: Angle(degrees: 180),
                                delta: Angle(degrees: 90))
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }

        return path
    }
}
