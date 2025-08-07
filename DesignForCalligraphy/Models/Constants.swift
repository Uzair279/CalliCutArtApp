import Foundation
import AppKit

let isAppfree : Bool = false
let appID = "11111111"
let contactEmail = "mailto:support@example.com"
let privacyPolicyLink = "https://yourdomain.com/privacyPolicy"
let termsOfUseLink = "https://yourdomain.com/terms"
let productIDs = ["com.newapp.weekly", "com.newapp.monthly", "com.newapp.yearly", "com.newapp.lifetime"]
var isProuctPro : Bool {
    if isAppfree {
        return true
    }
    else {
        return isUserPro()
    }
}
func isUserPro() -> Bool {
    let models = CoreDataManager.shared.fetchUserModels()
    return models.first?.isPro ?? false
}

func generatePNGURL(for categoryID: String, subcategoryID: String, itemID: String) -> String {
    let baseURL = "https://stepbystepcricut.s3.us-east-1.amazonaws.com/templates"
    return "\(baseURL)/\(categoryID)/\(subcategoryID)/png/\(itemID).png"
}
func generateSVGURL(for categoryID: String, subcategoryID: String, itemID: String) -> String {
    let baseURL = "https://stepbystepcricut.s3.us-east-1.amazonaws.com/templates"
    let cat = categoryID.lowercased()
    let subCat = subcategoryID.lowercased()
    return "\(baseURL)/\(cat)/svg/\(subCat)/design\(itemID).svg"
}


func downloadJSON(completion: @escaping (Result<URL, Error>) -> Void) {
    let jsonPath = "https://stepbystepcricut.s3.us-east-1.amazonaws.com/categories.json"
    guard let remoteURL = URL(string: jsonPath) else {
        completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
        return
    }
    let fileManager = FileManager.default
    let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
    let folderPath = libraryDir.appendingPathComponent("JSON")
    let destinationURL = folderPath.appendingPathComponent("categories.json")

    // Create the folder if it doesn't exist
    do {
        try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        completion(.failure(error))
        return
    }

    // Start the download
    let task = URLSession.shared.downloadTask(with: remoteURL) { tempURL, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let tempURL = tempURL else {
            completion(.failure(NSError(domain: "Download failed", code: 0, userInfo: nil)))
            return
        }

        do {
            // If file already exists, remove it before moving
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.moveItem(at: tempURL, to: destinationURL)
            DispatchQueue.main.async {
                completion(.success(destinationURL))
            }
        } catch {
            completion(.failure(error))
        }
    }

    task.resume()
    
}
func downloadGIF(completion: @escaping (Result<URL, Error>) -> Void) {
    let gifURL = "https://stepbystepcricut.s3.us-east-1.amazonaws.com/provideo/provid.gif"
    guard let remoteURL = URL(string: gifURL) else {
        completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
        return
    }

    let fileManager = FileManager.default
    let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
    let gifFolder = libraryDir.appendingPathComponent("GIFs")
    let localURL = gifFolder.appendingPathComponent("provid.gif")

    do {
        try fileManager.createDirectory(at: gifFolder, withIntermediateDirectories: true, attributes: nil)
    } catch {
        completion(.failure(error))
        return
    }

    URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let tempURL = tempURL else {
            completion(.failure(NSError(domain: "Download failed", code: 0, userInfo: nil)))
            return
        }

        do {
            if fileManager.fileExists(atPath: localURL.path) {
                try fileManager.removeItem(at: localURL)
            }
            try fileManager.moveItem(at: tempURL, to: localURL)
            DispatchQueue.main.async {
                completion(.success(localURL))
            }
        } catch {
            completion(.failure(error))
        }
    }.resume()
}
func ensureGIFExists(completion: @escaping (Result<URL, Error>) -> Void) {
    let fileManager = FileManager.default
    let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
    let gifFolder = libraryDir.appendingPathComponent("GIFs")
    let localURL = gifFolder.appendingPathComponent("provid.gif")

    if fileManager.fileExists(atPath: localURL.path) {
        completion(.success(localURL))
    } else {
        downloadGIF(completion: completion)
    }
}
func downloadSVG(from url: String, categoryID: String, subcategoryID: String, itemID: String, completion: @escaping (Result<URL, Error>) -> Void) {
    guard let remoteURL = URL(string: url) else {
        completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
        return
    }

    // Construct the destination path using your custom logic
    let fileManager = FileManager.default
    let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
    let folderPath = libraryDir.appendingPathComponent("SVGs/\(categoryID)/\(subcategoryID)")
    let destinationURL = folderPath.appendingPathComponent("svg_\(itemID).svg")

    // Create the folder if it doesn't exist
    do {
        try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        completion(.failure(error))
        return
    }

    // Start the download
    let task = URLSession.shared.downloadTask(with: remoteURL) { tempURL, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let tempURL = tempURL else {
            completion(.failure(NSError(domain: "Download failed", code: 0, userInfo: nil)))
            return
        }

        do {
            // If file already exists, remove it before moving
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.moveItem(at: tempURL, to: destinationURL)
            completion(.success(destinationURL))
        } catch {
            completion(.failure(error))
        }
    }

    task.resume()
}
func showAlert(title: String, message: String, style: NSAlert.Style = .informational) {
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
