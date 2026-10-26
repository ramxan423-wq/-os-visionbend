import Foundation

struct DiameterEstimate {
    let millimeters: Double
    let uncertaintyMillimeters: Double
    let source: String
}

enum ConduitDiameterMath {
    /// Contour coordinates are normalized. For a horizontal conduit the diameter
    /// spans IMAGE HEIGHT (focal Y); for a vertical conduit IMAGE WIDTH (focal X).
    static func pixelProjection(separationNormalized: Double, horizontalConduit: Bool,
                                imageWidth: Double, imageHeight: Double,
                                focalX: Double, focalY: Double) -> (spanPixels: Double, focalPixels: Double)? {
        guard separationNormalized.isFinite, separationNormalized > 0,
              imageWidth.isFinite, imageHeight.isFinite, imageWidth > 0, imageHeight > 0,
              focalX.isFinite, focalY.isFinite, focalX > 0, focalY > 0 else { return nil }
        let span = separationNormalized * (horizontalConduit ? imageHeight : imageWidth)
        let focal = horizontalConduit ? focalY : focalX
        guard span.isFinite, span > 0 else { return nil }
        return (span, focal)
    }

    static func calibratedDiameter(conduitPixels: Double, referencePixels: Double, referenceMillimeters: Double, pixelUncertainty: Double = 2) -> DiameterEstimate? {
        guard conduitPixels.isFinite, referencePixels.isFinite, referenceMillimeters.isFinite, pixelUncertainty.isFinite,
              conduitPixels > 0, referencePixels > 0, referenceMillimeters > 0, pixelUncertainty >= 0 else { return nil }
        let diameter = conduitPixels * referenceMillimeters / referencePixels
        let relative = pixelUncertainty / conduitPixels + pixelUncertainty / referencePixels
        let uncertainty = diameter * relative
        guard diameter.isFinite, uncertainty.isFinite else { return nil }
        return DiameterEstimate(millimeters: diameter, uncertaintyMillimeters: uncertainty, source: "Image scale; assumes same plane and true conduit edge")
    }

    static func physicalDiameter(widthPixels: Double, depthMeters: Double, focalLengthPixels: Double, perpendicularityDegrees: Double = 0) -> DiameterEstimate? {
        guard widthPixels.isFinite, depthMeters.isFinite, focalLengthPixels.isFinite, perpendicularityDegrees.isFinite,
              widthPixels > 0, depthMeters > 0, focalLengthPixels > 0,
              abs(perpendicularityDegrees) < 30 else { return nil }
        let cosine = cos(perpendicularityDegrees * .pi / 180)
        let mm = 1000 * widthPixels * depthMeters / (focalLengthPixels * cosine)
        guard mm.isFinite, (mm * 0.15).isFinite else { return nil }
        return DiameterEstimate(millimeters: mm, uncertaintyMillimeters: mm * 0.15, source: "Pinhole camera estimate; 15% illustrative uncertainty, not a calibrated accuracy guarantee")
    }
}
