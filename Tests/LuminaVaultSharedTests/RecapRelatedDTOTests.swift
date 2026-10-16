import Foundation
import Testing
@testable import LuminaVaultShared

struct RecapRelatedDTOTests {
    @Test("an older upload response decodes without a memory id")
    func uploadWithoutMemoryID() throws {
        let json = #"{"path":"notes/a.md","size":3,"contentType":"text/markdown","sha256":"x"}"#
        let decoded = try JSONDecoder().decode(VaultUploadResponse.self, from: Data(json.utf8))
        #expect(decoded.memoryId == nil)
    }

    @Test("an unknown highlight kind decodes instead of failing the recap")
    func unknownHighlightKind() throws {
        let json = #"{"kind":"streak","refId":"a","title":"t","date":0}"#
        let decoded = try JSONDecoder().decode(RecapHighlightDTO.self, from: Data(json.utf8))
        #expect(decoded.kind == .unknown)
    }

    @Test("recap and related round-trip")
    func roundTrip() throws {
        let recap = MeRecapResponse(
            range: .week,
            start: "2026-10-09",
            end: "2026-10-15",
            timezone: "Europe/Lisbon",
            totals: RecapTotalsDTO(captures: 4, learned: 2, asked: 7, reviewed: 1, activeDays: 3, streakDays: 2),
            previousTotals: RecapTotalsDTO(),
            daily: [RecapDayDTO(date: "2026-10-09", captures: 4)],
            kinds: RecapKindsDTO(decision: 1, fact: 1),
            highlights: [RecapHighlightDTO(kind: .decision, refId: UUID().uuidString, title: "Ship Friday", date: Date(timeIntervalSince1970: 0))],
            shareText: "My last 7 days on LuminaVault: 4 captures, 2 things learned."
        )
        #expect(try JSONDecoder().decode(MeRecapResponse.self, from: JSONEncoder().encode(recap)) == recap)

        let related = MemoryRelatedResponse(
            memoryId: UUID(),
            items: [RelatedMemoryDTO(id: UUID(), snippet: "s", kind: .fact, createdAt: Date(timeIntervalSince1970: 0), similarity: 0.8)]
        )
        #expect(try JSONDecoder().decode(MemoryRelatedResponse.self, from: JSONEncoder().encode(related)) == related)
    }
}
