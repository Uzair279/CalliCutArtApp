import SwiftUI
struct HomeView: View {
    @StateObject var viewModel: CategoryViewModel
    @State var selectedCategoryID: String?
    @State var selectedSubcategoryID: String?
    @State var showLoader: Bool = false
    @Binding var svgURL: URL?
    @Binding var screenType: screen
    @State var showPremiumScreen: Bool = false
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Sidemenu(
                    categories: viewModel.categories,
                    selectedCategoryID: $selectedCategoryID,
                    showPremium: $showPremiumScreen
                )
                .frame(width: 230)
                .background(Color("screenBg"))
                
                SubSidemenu(
                    subcategories: viewModel.categories.first(where: { $0.title == selectedCategoryID })?.subcategories ?? [],
                    selectedSubcategoryID: $selectedSubcategoryID
                )
                .id(selectedCategoryID ?? "")
                .frame(width: 190)
                .background(Color.white)
                
                if let selectedCategoryID,
                   let selectedCategory = viewModel.categories.first(where: { $0.title == selectedCategoryID }),
                   let selectedSubcategoryID,
                   let selectedSubcategory = selectedCategory.subcategories?.first(where: { $0.id == selectedSubcategoryID }) {
                    
                    MainView(
                        itemCount: selectedSubcategory.itemCount ?? 0,
                        categoryID: selectedCategoryID,
                        subcategoryID: selectedSubcategoryID,
                        addNew: {
                            // Add new Action
                        },
                        grdiAction: { item in
                            let svgPath = generateSVGURL(for: selectedCategoryID, subcategoryID: selectedSubcategoryID, itemID: item)
                            let url = checkIfFileExists(fileURL: URL(string: svgPath) ?? URL(fileURLWithPath: ""))
                            
                            if let url {
                                self.svgURL = url
                                screenType = .canvas
                            } else {
                                showLoader = true
                                downloadSVG(from: svgPath) { result in
                                    switch result {
                                    case .success(let fileURL):
                                        self.svgURL = fileURL
                                        screenType = .canvas
                                    case .failure(let error):
                                        print("Download failed: \(error)")
                                    }
                                    showLoader = false
                                }
                            }
                        }
                    )
                } else {
                    Text("Select a subcategory")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }
            
            .onAppear {
                if let firstCategory = viewModel.categories.first {
                    selectedCategoryID = firstCategory.title
                    selectedSubcategoryID = firstCategory.subcategories?.first?.id
                }
            }
            
            .onChange(of: viewModel.categories.count) { _ in
                if let firstCategory = viewModel.categories.first {
                    selectedCategoryID = firstCategory.title
                    selectedSubcategoryID = firstCategory.subcategories?.first?.id
                }
            }
            
            .onChange(of: selectedCategoryID) { newCategoryID in
                if let newCategoryID = newCategoryID,
                   let newCategory = viewModel.categories.first(where: { $0.title == newCategoryID }) {
                    selectedSubcategoryID = newCategory.subcategories?.first?.id
                }
            }
            
            .sheet(isPresented: $showPremiumScreen) {
                SubscriptionView(showPremium: $showPremiumScreen)
                    .frame(width: 819, height: 622)
            }
            
            if showLoader {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
