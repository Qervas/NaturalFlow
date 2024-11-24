enum Language: String, Codable, CaseIterable {
    case english
    case swedish
    case german
    case french

    // Add a custom encoder/decoder if needed
    private enum CodingKeys: String, CodingKey {
        case rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Language(rawValue: rawValue) ?? .swedish
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
