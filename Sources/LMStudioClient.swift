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
    private(set) var currentModel: String?
    
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

            // Prefer qwen/qwen2.5-vl-7b if available
            if let preferredModel = modelsResponse.data.first(where: { $0.id.contains("qwen2.5-vl-7b") || $0.id.contains("qwen/qwen2.5-vl-7b") }) {
                currentModel = preferredModel.id
                return true
            }

            // Fallback to first available model
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
            
            let result = parseFilenameResponse(from: content)
            if result == nil {
                print("❌ Failed to parse JSON response. Raw content: \(content.prefix(200))...")
            }
            return result
        } catch {
            print("❌ Request failed: \(error)")
            if let data = request.httpBody,
               let requestString = String(data: data, encoding: .utf8) {
                print("Request body: \(requestString.prefix(200))...")
            }
            return nil
        }
    }
    
    private func parseFilenameResponse(from content: String) -> FilenameResponse? {
        // Try to extract JSON from the response using proper brace matching
        if let jsonString = extractJsonFromText(content) {
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    let response = try JSONDecoder().decode(FilenameResponse.self, from: jsonData)
                    return FilenameResponse(
                        suggestedFilename: sanitizeFilename(response.suggestedFilename),
                        reasoning: response.reasoning,
                        confidence: response.confidence
                    )
                } catch {
                    print("❌ JSON decode error: \(error)")
                    print("Attempted to parse: \(jsonString)")
                }
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

    private func extractJsonFromText(_ text: String) -> String? {
        // First, try to extract from markdown code blocks
        let patterns = [
            "```json\\s*([\\s\\S]*?)```",
            "```\\s*([\\s\\S]*?)```",
            "\\{[\\s\\S]*\\}"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let matchRange = match.range(at: match.numberOfRanges - 1)
                    if let swiftRange = Range(matchRange, in: text) {
                        let extractedText = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        // Ensure it starts with { for JSON validation
                        if extractedText.hasPrefix("{") {
                            return extractedText
                        }
                    }
                }
            }
        }

        // Fallback to original brace matching logic
        guard let startIndex = text.firstIndex(of: "{") else { return nil }

        var braceCount = 0
        var currentIndex = startIndex

        while currentIndex < text.endIndex {
            let char = text[currentIndex]
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount == 0 {
                    // Found matching closing brace
                    let jsonString = String(text[startIndex...currentIndex])
                    return jsonString
                }
            }
            currentIndex = text.index(after: currentIndex)
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
