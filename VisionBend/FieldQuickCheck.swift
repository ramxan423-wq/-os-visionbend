import Foundation

/// A preflight feasibility signal, never a substitute for real shoe geometry or field bends.
enum FieldQuickCheck {
    enum Severity: Int, Comparable {
        case safe = 0, caution = 1, impossible = 2
        static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }
    }
    struct Finding: Equatable {
        let severity: Severity
        let text: String
    }
    struct Report {
        let severity: Severity
        let findings: [Finding]
        var canProceed: Bool { severity != .impossible }
    }

    static func evaluate(length: Double,
                         marks: [AdvancedFieldPatterns.Station],
                         minimumStraight: Double,
                         centerlineRadius: Double? = nil,
                         takeUp: Double? = nil,
                         targetStub: Double? = nil,
                         hasVerifiedReference: Bool = false) -> Report {
        var findings: [Finding] = []
        func add(_ severity: Severity, _ text: String) {
            findings.append(Finding(severity: severity, text: text))
        }
        guard length.isFinite, minimumStraight.isFinite,
              length > 0, minimumStraight >= 0,
              marks.allSatisfy({ $0.position.isFinite && $0.angle.isFinite }) else {
            return Report(severity: .impossible,
                          findings: [Finding(severity: .impossible, text: "Non-finite or invalid dimensions.")])
        }
        let ordered = marks.sorted { $0.position < $1.position }
        for mark in ordered {
            if mark.position < 0 || mark.position > length {
                add(.impossible, "A mark lies outside the available conduit.")
            }
            if mark.angle <= 0 || mark.angle > 90 {
                add(.impossible, "Bend angle must be greater than zero and at most 90 degrees.")
            }
        }
        if ordered.count > 1 {
            for (first, second) in zip(ordered, ordered.dropFirst()) {
                if second.position - first.position + 1e-9 < minimumStraight {
                    add(.impossible, "Adjacent marks violate minimum straight spacing.")
                    break
                }
            }
        }
        if let radius = centerlineRadius {
            if !radius.isFinite || radius <= 0 {
                add(.impossible, "The verified bend radius must be positive.")
            } else {
                for mark in ordered {
                    guard mark.angle > 0, mark.angle <= 90 else { continue }
                    let tangent = radius * tan(mark.angle * .pi / 360)
                    if mark.position < tangent || length - mark.position < tangent {
                        add(.caution, "Bend tangent may extend beyond an end of the conduit.")
                        break
                    }
                }
                for (left, right) in zip(ordered, ordered.dropFirst()) {
                    guard left.angle > 0, left.angle <= 90, right.angle > 0, right.angle <= 90 else { continue }
                    let minimum = radius * (tan(left.angle * .pi / 360) + tan(right.angle * .pi / 360))
                    if right.position - left.position + 1e-9 < minimum {
                        add(.caution, "Bend tangents may overlap. Check actual shoe clearance.")
                        break
                    }
                }
            }
        } else if !ordered.isEmpty {
            add(.caution, "The bender centerline radius is not confirmed.")
        }
        if let takeUp, let targetStub {
            if !takeUp.isFinite || !targetStub.isFinite || takeUp < 0 || targetStub <= takeUp {
                add(.impossible, "Stub length must exceed a nonnegative documented take-up.")
            }
        }
        if !hasVerifiedReference && !ordered.isEmpty {
            add(.caution, "Manufacturer reference marks and springback are not calibrated.")
        }
        if findings.isEmpty {
            add(.safe, "Geometry passes preliminary checks. Confirm with a test bend.")
        }
        return Report(severity: findings.map(\.severity).max() ?? .safe, findings: findings)
    }
}
