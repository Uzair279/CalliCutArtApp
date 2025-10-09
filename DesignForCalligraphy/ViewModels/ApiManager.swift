import Alamofire
import AppKit
class ApiManager {
    func generateSVGImage(prompt: String,
                          negativePrompt: String = "blurry, low resolution, distorted",
                          style: String? = nil,
                          image: NSImage? = nil,
                          imageType: String? = nil,
                          completion: @escaping (Result<GenerateImageResponse, Error>) -> Void) {
        
        let url = "https://api.svg.io/v1/generate-image"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer SVGIO_47DKNIOHMXPBYAAFFCVK1ZFGU9OTHMDL0KTO52UPYTQ00NEFZXTZXG0U1P",
            "Content-Type": "application/json"
        ]
        
        var base64String: String? = nil
        
        // ✅ Convert NSImage to base64 if provided
        if let image = image,
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            base64String = pngData.base64EncodedString()
        }
        
        let parameters = GenerateImageRequest(
            prompt: prompt,
            negativePrompt: negativePrompt,
            style: style,
            initialImage: base64String,
            initialImageType: image != nil ? "PNG" : nil
        )
        
        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: GenerateImageResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                    if let data = response.data,
                       let str = String(data: data, encoding: .utf8) {
                        print("❌ Server Error:", str)
                    }
                }
            }
    }
}
