import Foundation

struct Offer: Codable, Equatable {
    let price: Double
    let pickup: Double
    let trip: Double
    var perKM: Double { price / (pickup + trip) }
}

enum OfferParser {
    // Fail closed: exactly one price and two km values, plus an offer action.
    static func parse(_ text: String) -> Offer? {
        let lower = text.lowercased()
        guard lower.contains("confirm") || lower.contains("accept") else { return nil }
        func values(_ pattern: String) -> [Double] {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
            let ns = text as NSString
            return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap {
                Double(ns.substring(with: $0.range(at: 1)).replacingOccurrences(of: ",", with: "."))
            }
        }
        // Currency and amount must be on the same OCR line. Using \s here
        // incorrectly reads "12,60 lei\n0,4 km" as a second price of 0.4.
        let before = values(#"\b(?:lei|ron)[\t \u00A0]*(\d+(?:[.,]\d{1,2})?)\b"#)
        let after = values(#"\b(\d+(?:[.,]\d{1,2})?)[\t \u00A0]*(?:lei|ron)\b"#)
        let prices = before + after
        let km = values(#"\b(\d+(?:[.,]\d+)?)\s*km\b"#)
        guard prices.count == 1, km.count == 2,
              prices[0] > 0, km[0] + km[1] > 0 else { return nil }
        return Offer(price: prices[0], pickup: km[0], trip: km[1])
    }
}

struct Snapshot: Codable {
    let timestamp: Date
    let offer: Offer?
    let message: String
}

enum SharedStore {
    static var file: URL? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "CursaAppGroup") as? String else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?.appendingPathComponent("current.json")
    }
    static func write(_ offer: Offer?, message: String) {
        guard let file, let data = try? JSONEncoder().encode(Snapshot(timestamp: Date(), offer: offer, message: message)) else { return }
        try? data.write(to: file, options: .atomic)
    }
    static func read() -> Snapshot? {
        guard let file, let data = try? Data(contentsOf: file) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
