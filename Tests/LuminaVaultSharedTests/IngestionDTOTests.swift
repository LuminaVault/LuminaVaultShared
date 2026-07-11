import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Multimodal ingestion contracts")
struct IngestionDTOTests {
    @Test
    func `mixed batch request round trips`() throws {
        let request = IngestionCreateRequest(items: [
            .init(kind: .file, fileName: "brief.pdf", contentType: "application/pdf", sizeBytes: 42),
            .init(kind: .url, url: "https://example.com"),
        ])
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(IngestionCreateRequest.self, from: data)
        #expect(decoded.items.count == 2)
        #expect(decoded.items[0].kind == .file)
        #expect(decoded.items[1].kind == .url)
    }

    @Test
    func `credibility supports personal media without a numeric score`() throws {
        let value = IngestionCredibilityDTO(
            score: nil,
            confidence: 1,
            signals: ["user-owned original"],
            rationale: "Personal media is not publisher-scored.",
            version: "hermes-source-credibility-v1"
        )
        let decoded = try JSONDecoder().decode(
            IngestionCredibilityDTO.self,
            from: JSONEncoder().encode(value)
        )
        #expect(decoded == value)
    }
}
