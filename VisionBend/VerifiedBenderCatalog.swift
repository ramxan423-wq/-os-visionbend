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
        .init(id: "greenlee-555cx-emt-half", brand: "Greenlee", model: "555CX · 13934", conduit: "EMT", tradeSize: "1/2 in", deductInches: 7.5, radiusInches: 4.3125, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-emt-threequarter", brand: "Greenlee", model: "555CX · 13934", conduit: "EMT", tradeSize: "3/4 in", deductInches: 9, radiusInches: 5.5, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-emt-one", brand: "Greenlee", model: "555CX · 13934", conduit: "EMT", tradeSize: "1 in", deductInches: 11, radiusInches: 7, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-emt-onequarter", brand: "Greenlee", model: "555CX · 13934", conduit: "EMT", tradeSize: "1-1/4 in", deductInches: 13.625, radiusInches: 8.8125, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-emt-onehalf", brand: "Greenlee", model: "555CX · 13934", conduit: "EMT", tradeSize: "1-1/2 in", deductInches: 14.875, radiusInches: 8.375, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-emt-two", brand: "Greenlee", model: "555CX · 13934", conduit: "EMT", tradeSize: "2 in", deductInches: 16.375, radiusInches: 9.25, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-imc-half", brand: "Greenlee", model: "555CX · 28008 + IMC squeeze roller", conduit: "IMC", tradeSize: "1/2 in", deductInches: 7.5, radiusInches: 4.25, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-imc-threequarter", brand: "Greenlee", model: "555CX · 28008 + IMC squeeze roller", conduit: "IMC", tradeSize: "3/4 in", deductInches: 9, radiusInches: 5.4375, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-imc-one", brand: "Greenlee", model: "555CX · 28008 + IMC squeeze roller", conduit: "IMC", tradeSize: "1 in", deductInches: 11, radiusInches: 6.9375, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        .init(id: "greenlee-555cx-imc-onequarter", brand: "Greenlee", model: "555CX · 28008 + IMC squeeze roller", conduit: "IMC", tradeSize: "1-1/4 in", deductInches: 13.625, radiusInches: 8.75, sourceURL: "https://cdn.greenlee.com/resources/media?key=ef718feb-3f4e-434a-95f2-a90e3199e8df&languageCode=en&type=document", notes: "555 series single-shoe deduct table. Radius not verified for this exact shoe/size; 3D radius requires manual entry. Minimum stub = deduct + 2 in."),
        // Greenlee 555 series with 28008 rigid-only shoe group. Values are shoe- and size-specific.
        // Radius: official Greenlee 28008 product specification. Deduct: 555 series operator manual rigid-only shoe table.
        .init(id: "greenlee-555cx-28008-rigid-half", brand: "Greenlee", model: "555CX · 28008 rigid shoe", conduit: "RIGID", tradeSize: "1/2 in", deductInches: 7.5, radiusInches: 4.25, sourceURL: "https://www.greenlee.com/us/en/rigid-shoe-group-1-2---2-28008", notes: "Rigid-only 28008 shoe; verify hook reference and 555 series manual. Minimum stub: deduct + 2 in."),
        .init(id: "greenlee-555cx-28008-rigid-threequarter", brand: "Greenlee", model: "555CX · 28008 rigid shoe", conduit: "RIGID", tradeSize: "3/4 in", deductInches: 9, radiusInches: 5.4375, sourceURL: "https://www.greenlee.com/us/en/rigid-shoe-group-1-2---2-28008", notes: "Rigid-only 28008 shoe; verify hook reference and 555 series manual. Minimum stub: deduct + 2 in."),
        .init(id: "greenlee-555cx-28008-rigid-one", brand: "Greenlee", model: "555CX · 28008 rigid shoe", conduit: "RIGID", tradeSize: "1 in", deductInches: 11, radiusInches: 6.9375, sourceURL: "https://www.greenlee.com/us/en/rigid-shoe-group-1-2---2-28008", notes: "Rigid-only 28008 shoe; verify hook reference and 555 series manual. Minimum stub: deduct + 2 in."),
        .init(id: "greenlee-555cx-28008-rigid-onequarter", brand: "Greenlee", model: "555CX · 28008 rigid shoe", conduit: "RIGID", tradeSize: "1-1/4 in", deductInches: 13.625, radiusInches: 8.75, sourceURL: "https://www.greenlee.com/us/en/rigid-shoe-group-1-2---2-28008", notes: "Rigid-only 28008 shoe; verify hook reference and 555 series manual. Minimum stub: deduct + 2 in."),
        .init(id: "greenlee-555cx-28008-rigid-onehalf", brand: "Greenlee", model: "555CX · 28008 rigid shoe", conduit: "RIGID", tradeSize: "1-1/2 in", deductInches: 14.875, radiusInches: 8.25, sourceURL: "https://www.greenlee.com/us/en/rigid-shoe-group-1-2---2-28008", notes: "Rigid-only 28008 shoe; verify hook reference and 555 series manual. Minimum stub: deduct + 2 in."),
        .init(id: "greenlee-555cx-28008-rigid-two", brand: "Greenlee", model: "555CX · 28008 rigid shoe", conduit: "RIGID", tradeSize: "2 in", deductInches: 16.125, radiusInches: 9, sourceURL: "https://www.greenlee.com/us/en/rigid-shoe-group-1-2---2-28008", notes: "Rigid-only 28008 shoe; verify hook reference and 555 series manual. Minimum stub: deduct + 2 in."),
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
