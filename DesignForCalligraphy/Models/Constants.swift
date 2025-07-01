import Foundation

func generatePNGURL(for categoryID: String, subcategoryID: String, itemID: String) -> String {
    let baseURL = "https://designs-files.s3.us-east-1.amazonaws.com/templates"
    return "\(baseURL)/\(categoryID)/\(subcategoryID)/png/\(itemID).png"
}
func generateSVGURL(for categoryID: String, subcategoryID: String, itemID: String) -> String {
    let baseURL = "https://designs-files.s3.us-east-1.amazonaws.com/templates"
    let formattedItemID = itemID.prefix(1).uppercased() + itemID.dropFirst()
    return "\(baseURL)/\(categoryID)/\(subcategoryID)/\(formattedItemID)_20-01.svg"
}



func downloadSVG(from url: String, completion: @escaping (Result<URL, Error>) -> Void) {
    guard let fileURL = URL(string: url) else {
        completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
        return
    }

    // Construct the destination path
    let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    let folderPath = libraryPath.appendingPathComponent("SVGs")
    
    // Create the folder if it doesn't exist
    do {
        try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        completion(.failure(error))
        return
    }
    
    let destinationURL = folderPath.appendingPathComponent(fileURL.lastPathComponent)

    // Start the download
    let task = URLSession.shared.downloadTask(with: fileURL) { tempURL, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let tempURL = tempURL else {
            completion(.failure(NSError(domain: "Download failed", code: 0, userInfo: nil)))
            return
        }

        do {
            // Move the file to the destination folder
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            completion(.success(destinationURL))
        } catch {
            completion(.failure(error))
        }
    }

    task.resume()
}
func checkIfFileExists(fileURL: URL) -> URL? {
    let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    let folderPath = libraryPath.appendingPathComponent("SVGs")
    
    let destinationURL = folderPath.appendingPathComponent(fileURL.lastPathComponent)
    // Use destinationURL.path instead of destinationURL.absoluteString
    if FileManager.default.fileExists(atPath: destinationURL.path) {
        return destinationURL
    }
    return nil
}
