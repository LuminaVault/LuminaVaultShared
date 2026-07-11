import Foundation
import Testing
@testable import LuminaVaultShared

struct KnowledgeGraphDTOTests {
    @Test("Knowledge graph responses preserve evidence and inference state")
    func roundTrip() throws {
        let memoryID = UUID()
        let evidence = KnowledgeEvidenceDTO(id: UUID(), memoryID: memoryID, quote: "Atlas changed after the review.")
        let from = KnowledgeNodeDTO(id: UUID(), kind: .claim, label: "Atlas changed", confidence: 1, evidence: [evidence])
        let to = KnowledgeNodeDTO(id: UUID(), kind: .event, label: "The review", confidence: 0.8, evidence: [evidence])
        let edge = KnowledgeEdgeDTO(
            id: UUID(), from: from.id, to: to.id, predicate: .derivedFrom,
            state: .asserted, confidence: 1, rationale: "Explicit source statement", evidence: [evidence]
        )
        let value = KnowledgeGraphResponse(nodes: [from, to], edges: [edge], generatedAt: Date(timeIntervalSince1970: 1_000))

        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(KnowledgeGraphResponse.self, from: data)

        #expect(decoded == value)
    }
}
