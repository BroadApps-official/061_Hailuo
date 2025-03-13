import SwiftUI

struct Effect: Identifiable, Codable {
    let id: Int
    let title: String
    let preview: String
    let previewSmall: String

    enum CodingKeys: String, CodingKey {
        case id, title, preview
        case previewSmall = "preview_small"
    }
}


struct FilterResponse: Codable {
    let error: Bool
    let messages: [String]
    let data: [Effect]
}
