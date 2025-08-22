import Foundation
import AppKit
import PDFKit

struct FilenameResponse: Codable {
    let suggestedFilename: String
    let reasoning: String
    let confidence: Int
    
    enum CodingKeys: String, CodingKey {
        case suggestedFilename = "suggested_filename"
        case reasoning
        case confidence
    }
}

struct LMStudioResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

struct LMStudioModelsResponse: Codable {
    let data: [Model]
    
    struct Model: Codable {
        let id: String
    }
}

class LMStudioClient {
    private let baseURL: String
    private let session: URLSession
    private var currentModel: String?
    
    init(host: String = "127.0.0.1", port: Int = 1234) {
        self.baseURL = "http://\(host):\(port)"
        self.session = URLSession.shared
    }
    
    func testConnection() async -> Bool {
        guard let url = URL(string: "\(baseURL)/v1/models") else { return false }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return false }
            
            let modelsResponse = try JSONDecoder().decode(LMStudioModelsResponse.self, from: data)
            if let firstModel = modelsResponse.data.first {
                currentModel = firstModel.id
                return true
            }
        } catch {
            print("❌ Connection test failed: \(error)")
        }
        
        return false
    }
    
    func suggestFilename(for filePath: String, fileType: FileType) async -> FilenameResponse? {
        guard let model = currentModel else { return nil }
        
        switch fileType {
        case .image:
            return await suggestFilenameForImage(filePath, model: model)
        case .pdf:
            return await suggestFilenameForPDF(filePath, model: model)
        }
    }
    
    private func suggestFilenameForImage(_ imagePath: String, model: String) async -> FilenameResponse? {
        guard let imageData = loadImageData(from: imagePath) else { return nil }
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else { return nil }
        
        let prompt = """
        Analyze this image and suggest a descriptive filename that would be appropriate for saving it on a Mac.

        Requirements:
        - The filename should describe what you see in the image
        - Use descriptive but concise language
        - Only use letters, numbers, spaces, hyphens, and underscores
        - Do not include the file extension
        - Keep it under 50 characters
        - Make it meaningful and searchable

        Please respond with valid JSON matching this schema:
        {
            "suggested_filename": "string - the filename without extension",
            "reasoning": "string - brief explanation of the choice", 
            "confidence": "integer - confidence from 1-5"
        }
        """
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(imageData)"
                            ]
                        ]
                    ]
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 300
        ]
        
        return await makeRequest(url: url, payload: payload)
    }
    
    private func suggestFilenameForPDF(_ pdfPath: String, model: String) async -> FilenameResponse? {
        guard let pdfContent = extractPDFContent(from: pdfPath) else {
            return FilenameResponse(
                suggestedFilename: "document",
                reasoning: "Could not extract PDF content",
                confidence: 1
            )
        }
        
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else { return nil }
        
        let prompt = """
        Analyze this PDF document content and suggest a descriptive filename that would be appropriate for saving it on a Mac.

        PDF Content:
        \(pdfContent)

        Requirements:
        - The filename should describe the main topic/subject of the document
        - Use descriptive but concise language
        - Only use letters, numbers, spaces, hyphens, and underscores
        - Do not include the file extension
        - Keep it under 50 characters
        - Make it meaningful and searchable
        - Consider the document type (report, manual, invoice, etc.)

        Please respond with valid JSON matching this schema:
        {
            "suggested_filename": "string - the filename without extension",
            "reasoning": "string - brief explanation of the choice", 
            "confidence": "integer - confidence from 1-5"
        }
        """
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 300
        ]
        
        return await makeRequest(url: url, payload: payload)
    }
    
    private func makeRequest(url: URL, payload: [String: Any]) async -> FilenameResponse? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }
            
            let lmResponse = try JSONDecoder().decode(LMStudioResponse.self, from: data)
            let content = lmResponse.choices.first?.message.content ?? ""
            
            return parseFilenameResponse(from: content)
        } catch {
            print("❌ Request failed: \(error)")
            return nil
        }
    }
    
    private func parseFilenameResponse(from content: String) -> FilenameResponse? {
        // Try to extract JSON from the response
        if let jsonStart = content.range(of: "{"),
           let jsonEnd = content.range(of: "}", range: jsonStart.upperBound..<content.endIndex) {
            let jsonString = String(content[jsonStart.lowerBound...jsonEnd.upperBound])
            
            if let jsonData = jsonString.data(using: .utf8),
               let response = try? JSONDecoder().decode(FilenameResponse.self, from: jsonData) {
                return FilenameResponse(
                    suggestedFilename: sanitizeFilename(response.suggestedFilename),
                    reasoning: response.reasoning,
                    confidence: response.confidence
                )
            }
        }
        
        // Fallback: try to extract filename from text
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            if line.lowercased().contains("filename") || line.lowercased().contains("name") {
                let words = line.components(separatedBy: .punctuationCharacters.union(.whitespaces))
                    .filter { !$0.isEmpty }
                if words.count > 1 {
                    let filename = Array(words[1...min(3, words.count-1)]).joined(separator: "_")
                    return FilenameResponse(
                        suggestedFilename: sanitizeFilename(filename),
                        reasoning: "Extracted from AI response",
                        confidence: 3
                    )
                }
            }
        }
        
        return nil
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        var sanitized = filename
        
        // Remove invalid characters
        sanitized = sanitized.replacingOccurrences(of: "[<>:\"/\\|?*]", with: "", options: .regularExpression)
        
        // Replace spaces with underscores
        sanitized = sanitized.replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
        
        // Remove leading/trailing dots and spaces
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        
        // Limit length
        if sanitized.count > 50 {
            sanitized = String(sanitized.prefix(50))
        }
        
        // Ensure it's not empty
        if sanitized.isEmpty {
            sanitized = "renamed_file"
        }
        
        return sanitized
    }
    
    private func loadImageData(from path: String) -> String? {
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        guard let tiffData = image.tiffRepresentation else { return nil }
        guard let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [:]) else { return nil }
        
        return jpegData.base64EncodedString()
    }
    
    private func extractPDFContent(from path: String) -> String? {
        guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: path)) else { return nil }
        
        var content = ""
        let pageCount = min(3, pdfDocument.pageCount) // Read first 3 pages max
        
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                content += pageText + "\n"
            }
        }
        
        // Limit content length
        if content.count > 2000 {
            content = String(content.prefix(2000)) + "..."
        }
        
        return content.isEmpty ? nil : content
    }
}

enum FileType {
    case image
    case pdf
    
    static func from(extension ext: String) -> FileType? {
        let lowercased = ext.lowercased()
        if ["jpg", "jpeg", "png", "gif", "bmp", "tiff"].contains(lowercased) {
            return .image
        } else if lowercased == "pdf" {
            return .pdf
        }
        return nil
    }
}
