import Foundation

struct VerifiedBender: Identifiable {
    let id: String
    let brand: String
    let model: String
    let conduit: String
    let tradeSize: String
    let deductInches: Double?
    let radiusInches: Double?
    let sourceURL: String
    let notes: String
}

enum VerifiedBenderCatalog {
    // Each entry is backed by the linked manufacturer's product page or manual.
    // Never substitute nominal conduit size for actual outside diameter.
    static let entries: [VerifiedBender] = [
        .init(id: "klein-51606", brand: "Klein Tools", model: "51606", conduit: "EMT", tradeSize: "1/2 in", deductInches: 5, radiusInches: 4.625, sourceURL: "https://www.kleintools.com/catalog/conduit-benders-and-parts/aluminum-conduit-bender-full-assembly-12-inch-emt-angle-setter", notes: "Manufacturer lists 5 in stub-up height and 4.625 in centerline radius."),
        .init(id: "greenlee-840ah", brand: "Greenlee", model: "840AH", conduit: "EMT", tradeSize: "1/2 in", deductInches: 5, radiusInches: 4.1875, sourceURL: "https://www.greenlee.com/br/en/benderhand-1-2-w-handle-840ah", notes: "Radius from official product listing; 5 in deduct from official Site-Rite hand-bender manual."),
        .init(id: "greenlee-840a", brand: "Greenlee", model: "840A", conduit: "EMT", tradeSize: "1/2 in", deductInches: 5, radiusInches: 4.1875, sourceURL: "https://www.greenlee.com/us/en/benderhand---1-2-emt-840a", notes: "Radius from official product listing; 5 in deduct from official Site-Rite hand-bender manual."),
        .init(id: "klein-56203", brand: "Klein Tools", model: "56203", conduit: "EMT", tradeSize: "1/2 in", deductInches: 5, radiusInches: 4, sourceURL: "https://www.kleintools.com/catalog/conduit-benders-and-parts/assembled-iron-conduit-bender-12-inch-emt", notes: "Manufacturer specifies 5 in stub-up height and 4 in centerline radius.")
    ]

    static func stubMarkInches(modelID: String, desiredStubInches: Double) -> Double? {
        guard let model = entries.first(where: { $0.id == modelID }),
              let deduct = model.deductInches,
              desiredStubInches.isFinite, desiredStubInches >= deduct else { return nil }
        return desiredStubInches - deduct
    }
}
