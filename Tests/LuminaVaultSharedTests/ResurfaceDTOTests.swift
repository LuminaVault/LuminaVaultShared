import Foundation
import Testing
@testable import LuminaVaultShared

struct ResurfaceDTOTests {
    @Test("an unknown resurface reason decodes instead of failing the queue")
    func unknownReason() throws {
        let id = UUID()
        let json = #"{"memoryId":"\#(id)","snippet":"s","createdAt":0,"reason":"trending","why":"w"}"#
        let item = try JSONDecoder().decode(ResurfaceItemDTO.self, from: Data(json.utf8))
        #expect(item.reason == .unknown)
        #expect(item.kind == nil)
    }

    @Test("older review responses and device requests still decode")
    func olderPayloads() throws {
        let id = UUID()
        let review = try JSONDecoder().decode(
            MemoryReviewResponse.self,
            from: Data(#"{"memoryId":"\#(id)","reviewedAt":0,"reviewCount":2}"#.utf8)
        )
        #expect(review.nextReviewAt == nil)
        #expect(review.resurfaceMuted == nil)
        let device = try JSONDecoder().decode(
            DeviceRegistrationRequest.self,
            from: Data(#"{"token":"t","platform":"ios"}"#.utf8)
        )
        #expect(device.bundleId == nil)
    }

    @Test("a review request round-trips")
    func reviewRequest() throws {
        let request = MemoryReviewRequest(action: .later)
        #expect(try JSONDecoder().decode(MemoryReviewRequest.self, from: JSONEncoder().encode(request)) == request)
    }
}
