import Foundation
import Testing
@testable import LuminaVaultShared

struct LearnedDigestDTOTests {
    @Test("a digest round-trips and reports emptiness")
    func roundTrip() throws {
        let digest = LearnedDigestResponse(
            since: Date(timeIntervalSince1970: 0),
            until: Date(timeIntervalSince1970: 604_800),
            soulChanges: [LearnedSoulChangeDTO(
                id: UUID(),
                title: "Prefers short answers",
                summary: "s",
                createdAt: Date(timeIntervalSince1970: 1)
            )],
            memories: [LearnedMemoryDTO(
                id: UUID(),
                snippet: "Aisle seats",
                kind: "preference",
                reviewState: "pending",
                createdAt: Date(timeIntervalSince1970: 2)
            )]
        )
        #expect(try JSONDecoder().decode(LearnedDigestResponse.self, from: JSONEncoder().encode(digest)) == digest)
        #expect(!digest.isEmpty)
        #expect(LearnedDigestResponse(since: Date(), until: Date(), soulChanges: [], memories: []).isEmpty)
    }
}
