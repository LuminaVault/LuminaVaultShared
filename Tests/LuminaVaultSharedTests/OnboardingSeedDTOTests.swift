import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Onboarding seed contracts")
struct OnboardingSeedDTOTests {
    @Test("sources are the wire strings web and Android send")
    func sourceWireStrings() {
        #expect(OnboardingSeedSource.allCases.map(\.rawValue) == [
            "readwise",
            "raindrop",
            "obsidian",
            "bookmarks",
            "links",
        ])
    }

    @Test("a links request carries only its links")
    func linksRequestEncoding() throws {
        let data = try JSONEncoder().encode(OnboardingSeedRequest(source: .links, links: ["https://example.com/a"]))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["source"] as? String == "links")
        #expect(object["links"] as? [String] == ["https://example.com/a"])
        #expect(object["token"] == nil)
        #expect(object["bookmarksHTML"] == nil)
    }

    @Test("an unknown source is rejected, not defaulted")
    func unknownSourceFails() throws {
        let json = try #require(#"{"source":"notion"}"#.data(using: .utf8))
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OnboardingSeedRequest.self, from: json)
        }
    }

    @Test("status is ready at the threshold the server sends")
    func statusReadiness() throws {
        let json = #"{"imported":47,"indexed":12,"sampleTitles":["Pricing pages"],"readyThreshold":20}"#
        let status = try JSONDecoder().decode(OnboardingSeedStatusDTO.self, from: #require(json.data(using: .utf8)))
        #expect(status.isReady == false)
        #expect(OnboardingSeedStatusDTO(imported: 47, indexed: 20, sampleTitles: [], readyThreshold: 20).isReady)
    }

    @Test("suggested questions round-trip")
    func questionsRoundTrip() throws {
        let response = SuggestedQuestionsResponse(questions: [
            SuggestedQuestionDTO(question: "What did you save about pricing pages?", memoryIds: [UUID()]),
        ])
        let decoded = try JSONDecoder().decode(
            SuggestedQuestionsResponse.self,
            from: JSONEncoder().encode(response)
        )
        #expect(decoded == response)
    }
}
