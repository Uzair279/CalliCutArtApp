import Alamofire
import AppKit

class ApiManager {
    
    static let shared = ApiManager()
    private init() {}
    
    func generateSVGImage(prompt: String,
                          negativePrompt: String = "blurry, low resolution, distorted",
                          style: String? = nil,
                          image: NSImage? = nil,
                          imageType: String? = nil,
                          completion: @escaping (Result<(svgURL: URL, pngURL: URL), Error>) -> Void) {
        
        let url = "https://api.svg.io/v1/generate-image"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer SVGIO_47DKNIOHMXPBYAAFFCVK1ZFGU9OTHMDL0KTO52UPYTQ00NEFZXTZXG0U1P",
            "Content-Type": "application/json"
        ]
        
        var base64String: String? = nil
        
        // Convert NSImage → PNG → Base64
        if let image = image,
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            base64String = pngData.base64EncodedString()
        }
        
        // Build Request Body
        let parameters = GenerateImageRequest(
            prompt: prompt,
            negativePrompt: negativePrompt,
            style: style,
            initialImage: base64String,
            initialImageType: image != nil ? "PNG" : nil
        )
        
        // Make API Call
        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: GenerateImageResponse.self) { response in
                switch response.result {
                case .success(let data):
                    guard let svgUrlString = data.data.first?.svgUrl,
                          let pngUrlString = data.data.first?.pngUrl,
                          let svgRemoteURL = URL(string: svgUrlString),
                          let pngRemoteURL = URL(string: pngUrlString) else {
                        completion(.failure(ApiError.invalidResponse))
                        return
                    }
                    
                    // Download both SVG and PNG
                    self.downloadAndSaveBoth(svgURL: svgRemoteURL, pngURL: pngRemoteURL) { result in
                        completion(result)
                    }
                    
                case .failure(let error):
                    if let data = response.data,
                       let str = String(data: data, encoding: .utf8) {
                        print("❌ Server Error:", str)
                    }
                    completion(.failure(error))
                }
            }
    }
    
    
    // MARK: - Download & Save Both SVG + PNG
    private func downloadAndSaveBoth(svgURL: URL, pngURL: URL,
                                     completion: @escaping (Result<(svgURL: URL, pngURL: URL), Error>) -> Void) {
        let group = DispatchGroup()
        var savedSVG: URL?
        var savedPNG: URL?
        var downloadError: Error?
        
        // Download SVG
        group.enter()
        AF.download(svgURL).responseData { response in
            if case .success(let data) = response.result {
                do {
                    let folderURL = try self.ensureAISvgsFolder()
                    let svgFile = folderURL.appendingPathComponent("image_\(UUID().uuidString).svg")
                    try data.write(to: svgFile)
                    savedSVG = svgFile
                } catch {
                    downloadError = error
                }
            } else if case .failure(let error) = response.result {
                downloadError = error
            }
            group.leave()
        }
        
        // Download PNG
        group.enter()
        AF.download(pngURL).responseData { response in
            if case .success(let data) = response.result {
                do {
                    let folderURL = try self.ensureAISvgsFolder()
                    let pngFile = folderURL.appendingPathComponent("image_\(UUID().uuidString).png")
                    try data.write(to: pngFile)
                    savedPNG = pngFile
                } catch {
                    downloadError = error
                }
            } else if case .failure(let error) = response.result {
                downloadError = error
            }
            group.leave()
        }
        
        // Notify when both are done
        group.notify(queue: .main) {
            if let error = downloadError {
                completion(.failure(error))
            } else if let svg = savedSVG, let png = savedPNG {
                print("✅ SVG Saved at:", svg.path)
                print("✅ PNG Saved at:", png.path)
                completion(.success((svg, png)))
            } else {
                completion(.failure(ApiError.invalidResponse))
            }
        }
    }
    
    
    // MARK: - Ensure Folder Exists
    private func ensureAISvgsFolder() throws -> URL {
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let folderURL = libraryURL.appendingPathComponent("AISvgs")
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL
    }
}
