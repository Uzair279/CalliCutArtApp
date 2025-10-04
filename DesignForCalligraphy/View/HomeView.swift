import SwiftUI
struct HomeView: View {
    @StateObject var viewModel: CategoryViewModel
    @State var showLoader: Bool = false
    @Binding var svgURL: URL?
    @Binding var screenType: screen
    @State var showPremiumScreen: Bool = false
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
//                Sidemenu(
//                    categories: viewModel.categories,
//                    selectedCategoryID: $viewModel.selectedCategoryID,
//                    showPremium: $showPremiumScreen
//                )
//                .frame(width: 230)
//                .background(Color("screenBg"))
                
                SubSidemenu(
                    subcategories: viewModel.categories.first(where: { $0.title == viewModel.selectedCategoryID })?.subcategories ?? [],
                    selectedSubcategoryID: $viewModel.selectedSubcategoryID
                )
                .id(viewModel.selectedCategoryID ?? "")

                .id(viewModel.selectedCategoryID ?? "")
                .frame(width: 190)
                .background(Color.white)
                
                if let selectedCategoryID = viewModel.selectedCategoryID,
                   let selectedCategory = viewModel.categories.first(where: { $0.title == selectedCategoryID }),
                   let selectedSubcategoryID = viewModel.selectedSubcategoryID,
                   let selectedSubcategory = selectedCategory.subcategories?.first(where: { $0.id == selectedSubcategoryID }) {
                    
                    MainView(
                        viewModel: viewModel,
                        itemCount: selectedSubcategory.itemCount ?? 0,
                        categoryID: selectedCategoryID,
                        subcategoryID: selectedSubcategoryID,
                        addNew: {
                            // Add new Action
                        },
                        grdiAction: { item in
                            let svgDownloadURL = generateSVGURL(for: selectedCategoryID, subcategoryID: selectedSubcategoryID, itemID: item)
                            let localSVGURL = localSVGPath(categoryID: selectedCategoryID, subcategoryID: selectedSubcategoryID, itemID: item)

                            if checkIfFileExists(at: localSVGURL) {
                                self.svgURL = localSVGURL
                                screenType = .canvas
                            } else {
                                showLoader = true
                                downloadSVG(from: svgDownloadURL, categoryID: selectedCategoryID, subcategoryID: selectedSubcategoryID, itemID: item) { result in
                                    switch result {
                                    case .success(let fileURL):
                                        self.svgURL = fileURL
                                        screenType = .canvas
                                    case .failure(let error):
                                        print("Failed to download SVG: \(error.localizedDescription)")
                                    }
                                }

                            }

                        }, downloadAction: { newItem in
                            let svgDownloadURL = generateSVGURL(for: selectedCategoryID, subcategoryID: selectedSubcategoryID, itemID: newItem)
                            let localSVGURL = localSVGPath(categoryID: selectedCategoryID, subcategoryID: selectedSubcategoryID, itemID: newItem)

                            if checkIfFileExists(at: localSVGURL) {
                                promptUserForSaveLocation(defaultFileName: "Calligraphy_\(newItem).svg") { saveURL in
                                    guard let saveURL = saveURL else {
                                        print(" User cancelled save")
                                        return
                                    }
                                    
                                    do {
                                        let fileManager = FileManager.default
                                        if fileManager.fileExists(atPath: saveURL.path) {
                                            try fileManager.removeItem(at: saveURL)
                                        }
                                        try fileManager.moveItem(at: localSVGURL, to: saveURL)
                                        
                                    } catch {
                                        showAlert(title: "Error", message: "File not Exist or unable to save right now")
                                        print("Failed to save file: \(error.localizedDescription)")
                                    }
                                }
                                
                            } else {
                                promptUserForSaveLocation(defaultFileName: "calligraphy_\(newItem).svg") { saveURL in
                                       guard let saveURL = saveURL else {
                                           print("❌ User cancelled save")
                                           return
                                       }
                                showLoader = true
                                    downloadSVG(from: svgDownloadURL, categoryID: selectedCategoryID, subcategoryID: selectedSubcategoryID, itemID: newItem) { result in
                                        DispatchQueue.main.async {
                                            showLoader = false
                                        }
                                        switch result {
                                        case .success(let fileURL):
                                            do {
                                                let fileManager = FileManager.default
                                                if fileManager.fileExists(atPath: saveURL.path) {
                                                    try fileManager.removeItem(at: saveURL)
                                                }
                                                try fileManager.moveItem(at: fileURL, to: saveURL)
                                                
                                            } catch {
                                                showAlert(title: "Error", message: "File not Exist or unable to save right now")
                                                print("Failed to save file: \(error.localizedDescription)")
                                            }
                                            
                                            
                                        case .failure(let error):
                                            print("Failed to download SVG: \(error.localizedDescription)")
                                        }
                                    }
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
            
           

            .onChange(of: viewModel.categories.count) { _ in
                if let firstCategory = viewModel.categories.first {
                    viewModel.selectedCategoryID = firstCategory.title
                    viewModel.selectedSubcategoryID = firstCategory.subcategories?.first?.id
                }
            }

            .onChange(of: viewModel.selectedCategoryID) { newCategoryID in
                if let newCategoryID = newCategoryID,
                   let newCategory = viewModel.categories.first(where: { $0.title == newCategoryID }) {
                    viewModel.selectedSubcategoryID = newCategory.subcategories?.first?.id
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
    func promptUserForSaveLocation(defaultFileName: String = "image.svg",
                                   completion: @escaping (URL?) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.title = "Save SVG File"
        savePanel.nameFieldStringValue = defaultFileName
        savePanel.allowedContentTypes = [.svg] // Requires macOS 12+ (UniformTypeIdentifiers)
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                completion(url)
            } else {
                completion(nil)
            }
        }
    }

    func localSVGPath(categoryID: String, subcategoryID: String, itemID: String) -> URL {
        let fileManager = FileManager.default
        let baseDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let svgDir = baseDir.appendingPathComponent("SVGs/\(categoryID)/\(subcategoryID)")
        
        // Ensure the directory exists
        try? fileManager.createDirectory(at: svgDir, withIntermediateDirectories: true)
        
        return svgDir.appendingPathComponent("svg_\(itemID).svg")
    }
    func checkIfFileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }


}
