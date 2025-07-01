import SwiftUI

struct HomeView: View {
    @StateObject var viewModel : CategoryViewModel
    @State private var selectedCategoryID: String?
    @State private var selectedSubcategoryID: String?
    @State var showLoader: Bool = false
    @Binding var svgURL : URL?
    @Binding var screenType : screen
    var body: some View {
     ZStack {
        HStack(spacing: 0){
            Sidemenu(
                categories: viewModel.categories,
                selectedCategoryID: $selectedCategoryID
            )
            .frame(width: 230)
            .background(Color("screenBg"))
            if let selectedCategoryID = selectedCategoryID,
               let selectedCategory = viewModel.categories.first(where: { $0.id == selectedCategoryID }),
               let subcategories = selectedCategory.subcategories {
                SubSidemenu(
                    subcategories: subcategories,
                    selectedSubcategoryID: $selectedSubcategoryID
                )
                .frame(width: 190)
                .background(Color.white)
                
            } else {
                Text("Select a category")
                    .frame(width: 190)
                    .foregroundColor(.gray)
            }
            if let selectedCategoryID = selectedCategoryID,
               let selectedSubcategoryID = selectedSubcategoryID,
               let selectedCategory = viewModel.categories.first(where: { $0.id == selectedCategoryID }),
               let selectedSubcategory = selectedCategory.subcategories?.first(where: { $0.id == selectedSubcategoryID }) {
                MainView(itemCount: selectedSubcategory.itemCount ?? 0, categoryID: selectedCategoryID, subcategoryID: selectedSubcategoryID, addNew: {
                    //Add new Action
                }, grdiAction: { item in
                    let svgURL = generateSVGURL(for: selectedCategory.id ?? "", subcategoryID: selectedSubcategory.id ?? "", itemID: item)
                   let url = checkIfFileExists(fileURL: URL(string: svgURL) ?? URL(fileURLWithPath: ""))
                    if let url {
                        self.svgURL = url
                        screenType = .canvas
                    }
                    else {
                        print("Show Loader")
                        showLoader = true
                        downloadSVG(from: svgURL) { result in
                            switch result {
                            case .success(let fileURL):
                                print("SVG downloaded to: \(fileURL.path)")
                                self.svgURL = fileURL
                                showLoader = false
                                screenType = .canvas
                            case .failure(let error):
                                print("Failed to download SVG: \(error.localizedDescription)")
                                showLoader =  false
                            }
                        }
                    }
                    
                })
            } else {
                Text("Select a subcategory")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            // Set default selection on first load
            if let firstCategory = viewModel.categories.first {
                selectedCategoryID = firstCategory.id
                selectedSubcategoryID = firstCategory.subcategories?.first?.id
            }
        }
        .onChange(of: selectedCategoryID) { newCategoryID in
            // Automatically select the first subcategory when the category changes
            if let newCategoryID = newCategoryID,
               let newCategory = viewModel.categories.first(where: { $0.id == newCategoryID }) {
                selectedSubcategoryID = newCategory.subcategories?.first?.id
            }
        }
         if showLoader {
             ProgressView()
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
         }
      }
    }
}

