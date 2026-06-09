import Foundation
import MapKit
import CoreLocation

/// Pre-samples an `MKPolyline` so the live-session train can be placed at any
/// fractional progress (0...1) along its real arc length, instead of using a
/// straight-line lerp. Returns coordinate + initial bearing of the current
/// segment so the train icon can rotate to point "down the rails".
struct PolylineSamples {
    private struct Segment {
        let start: CLLocationCoordinate2D
        let end: CLLocationCoordinate2D
        let length: CLLocationDistance
        let bearing: CLLocationDirection
        let cumulative: CLLocationDistance
    }

    private let segments: [Segment]
    let totalLength: CLLocationDistance

    init(polyline: MKPolyline) {
        let count = polyline.pointCount
        guard count >= 2 else {
            self.segments = []
            self.totalLength = 0
            return
        }
        var coords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: count
        )
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))

        var segs: [Segment] = []
        segs.reserveCapacity(count - 1)
        var cumulative: CLLocationDistance = 0
        for i in 0..<(count - 1) {
            let a = coords[i]
            let b = coords[i + 1]
            let length = CLLocation(latitude: a.latitude, longitude: a.longitude)
                .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
            let bearing = GreatCircle.bearing(from: a, to: b)
            segs.append(Segment(
                start: a,
                end: b,
                length: length,
                bearing: bearing,
                cumulative: cumulative
            ))
            cumulative += length
        }
        self.segments = segs
        self.totalLength = cumulative
    }

    var isEmpty: Bool { segments.isEmpty || totalLength <= 0 }

    /// Returns the coordinate at `fraction ∈ [0, 1]` of the polyline's arc
    /// length, plus the bearing (degrees, 0 = north) of the segment the point
    /// currently lies on. Bearing of the last segment is reused at fraction 1.
    func point(at fraction: Double) -> (coordinate: CLLocationCoordinate2D, bearing: CLLocationDirection)? {
        guard !isEmpty, let last = segments.last else { return nil }
        let f = min(max(fraction, 0), 1)
        if f >= 1.0 - .ulpOfOne {
            return (last.end, last.bearing)
        }
        let target = f * totalLength
        // Binary search for the segment whose cumulative range contains `target`.
        var lo = 0, hi = segments.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            let s = segments[mid]
            if target < s.cumulative {
                hi = mid - 1
            } else if target >= s.cumulative + s.length {
                lo = mid + 1
            } else {
                lo = mid
                break
            }
        }
        let seg = segments[max(0, min(lo, segments.count - 1))]
        let local: Double
        if seg.length > 0 {
            local = (target - seg.cumulative) / seg.length
        } else {
            local = 0
        }
        let lat = seg.start.latitude + (seg.end.latitude - seg.start.latitude) * local
        let lon = seg.start.longitude + (seg.end.longitude - seg.start.longitude) * local
        return (CLLocationCoordinate2D(latitude: lat, longitude: lon), seg.bearing)
    }
}
