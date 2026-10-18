import Foundation

struct DiameterEstimate {
    let millimeters: Double
    let uncertaintyMillimeters: Double
    let source: String
}

enum ConduitDiameterMath {
    static func calibratedDiameter(conduitPixels: Double, referencePixels: Double, referenceMillimeters: Double, pixelUncertainty: Double = 2) -> DiameterEstimate? {
        guard conduitPixels.isFinite, referencePixels.isFinite, referenceMillimeters.isFinite, pixelUncertainty.isFinite,
              conduitPixels > 0, referencePixels > 0, referenceMillimeters > 0, pixelUncertainty >= 0 else { return nil }
        let diameter = conduitPixels * referenceMillimeters / referencePixels
        let relative = pixelUncertainty / conduitPixels + pixelUncertainty / referencePixels
        return DiameterEstimate(millimeters: diameter, uncertaintyMillimeters: diameter * relative, source: "Image scale; assumes same plane and true conduit edge")
    }

    static func physicalDiameter(widthPixels: Double, depthMeters: Double, focalLengthPixels: Double, perpendicularityDegrees: Double = 0) -> DiameterEstimate? {
        guard widthPixels.isFinite, depthMeters.isFinite, focalLengthPixels.isFinite, perpendicularityDegrees.isFinite,
              widthPixels > 0, depthMeters > 0, focalLengthPixels > 0,
              abs(perpendicularityDegrees) < 30 else { return nil }
        let cosine = cos(perpendicularityDegrees * .pi / 180)
        let mm = 1000 * widthPixels * depthMeters / (focalLengthPixels * cosine)
        return DiameterEstimate(millimeters: mm, uncertaintyMillimeters: mm * 0.15, source: "Pinhole camera estimate; 15% illustrative uncertainty, not a calibrated accuracy guarantee")
    }
}
