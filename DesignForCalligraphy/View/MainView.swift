import SwiftUI
import SDWebImageSwiftUI
struct MainView: View {
    let itemCount: Int
    let categoryID: String
    let subcategoryID: String
    let addNew: () -> Void
    let grdiAction: (String) -> Void
    let downloadAction: (String) -> Void
    var body: some View {
        VStack {
            HStack {
                Text("Designs for Calligraphy")
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.bold.rawValue, size: 20))
                Spacer()
                Button(action: {
                    addNew()
                }) {
                    HStack {
                        Text("+ Create New")
                            .foregroundStyle(.white)
                            .font(.custom(Fonts.medium.rawValue, size: 16))
                    }
                    .frame(width: 123, height: 42)
                    .background(Color("selectedColor"))
                    .cornerRadius(100)
                }
                .buttonStyle(.plain)
                .opacity(0)
            }
            GridView(itemCount: itemCount, categoryID: categoryID, subcategoryID: subcategoryID) { str in
                grdiAction(str)
            } downloadAction: { newStr in
                downloadAction(newStr)
            }
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
        GridItem(.adaptive(minimum: 148, maximum: 148), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
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
                                    .frame(width: 148, height: 148)
                                    .background(Color.black.opacity(0.3))
                            }
                            
                            .frame(width: 148, height: 148)
//                            if index > 2 && !isProuctPro {
//                                if !premiumVM.isProductPurchased {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image("premiumIcon")
                                        .padding([.top, .trailing], 10)
                                }
                                Spacer()
                            }
//                                }
//                            }
                            VStack {
                                Spacer()
                                HStack(spacing: 10) {
                                    Spacer()
                                    Button(action:{
                                        downloadAction("\(index)")
                                    }) {
                                        Image("download")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 35, height: 23)
                                    }
                                    
                                    .buttonStyle(.plain)
                                    Button(action:{
                                        action("\(index)")
                                    }) {
                                        Image("Edit")
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
