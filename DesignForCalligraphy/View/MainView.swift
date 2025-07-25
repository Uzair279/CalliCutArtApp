import SwiftUI

struct MainView: View {
    let itemCount: Int
    let categoryID: String
    let subcategoryID: String
    let addNew: () -> Void
    let grdiAction: (String) -> Void
    var body: some View {
        VStack {
            HStack {
                Text("Designs for Calligraphy")
                Spacer()
                Button(action: {
                    addNew()
                }) {
                    HStack {
                        Text("+ Create New")
                            .foregroundStyle(.white)
                            .font(.custom("Medium", size: 16))
                    }
                    .frame(width: 123, height: 42)
                    .background(Color("selectedColor"))
                    .cornerRadius(100)
                }
                .buttonStyle(.plain)
            }
            GridView(itemCount: itemCount, categoryID: categoryID, subcategoryID: subcategoryID) { str in
                grdiAction(str)
            }
            Spacer()
        }
        .padding(20)
        .background(Color("screenBg"))
    }
}


struct GridView: View {
    let itemCount: Int
    let categoryID: String
    let subcategoryID: String
    let action: (String) -> Void
    @State private var showSubscriptionSheet = false
    let columns = [
        GridItem(.adaptive(minimum: 148), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<itemCount, id: \.self) { index in
                    Button(action: {
                        if index > 2 && !isAppfree {
                            showSubscriptionSheet = true
                        }
                        else {
                            action("\(index)")
                        }
                    }) {
                        ZStack (alignment: .topTrailing){
                            let pngURL = generatePNGURL(for: categoryID, subcategoryID: subcategoryID, itemID: index)
                            AsyncImage(url: URL(string: pngURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 148, height: 148)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            .clipped()
                            if index > 2 && !isAppfree {
                                Image("premiumIcon")
                                    .padding([.top, .trailing], 10)
                            }
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
