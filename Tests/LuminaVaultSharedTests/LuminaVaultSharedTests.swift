import Foundation
import Testing
@testable import LuminaVaultShared

// MARK: - HER-37 DTO round-trip tests

@Suite("QueryStreamEvent codable round-trip")
struct QueryStreamEventCodableTests {
    private func roundTrip(_ event: QueryStreamEvent) throws -> QueryStreamEvent {
        let data = try JSONEncoder().encode(event)
        return try JSONDecoder().decode(QueryStreamEvent.self, from: data)
    }

    @Test func token() throws {
        #expect(try roundTrip(.token("hello")) == .token("hello"))
    }

    @Test func summary() throws {
        #expect(try roundTrip(.summary("done thinking")) == .summary("done thinking"))
    }

    @Test func followUps() throws {
        let event: QueryStreamEvent = .followUps(["Go deeper", "Save as memo"])
        #expect(try roundTrip(event) == event)
    }

    @Test func source() throws {
        let hit = QueryHitDTO(id: UUID(), content: "snippet", distance: 0.42, createdAt: nil)
        #expect(try roundTrip(.source(hit)) == .source(hit))
    }

    @Test func done() throws {
        #expect(try roundTrip(.done) == .done)
    }

    @Test func error() throws {
        #expect(try roundTrip(.error("boom")) == .error("boom"))
    }

    @Test func wireShapeIsTypePayloadDiscriminator() throws {
        let event: QueryStreamEvent = .token("hi")
        let json = try JSONEncoder().encode(event)
        let dict = try JSONSerialization.jsonObject(with: json) as? [String: Any]
        #expect(dict?["type"] as? String == "token")
        #expect(dict?["payload"] as? String == "hi")
    }

    @Test func followUpsUsesSnakeCaseWireKey() throws {
        let event: QueryStreamEvent = .followUps(["a"])
        let json = try JSONEncoder().encode(event)
        let dict = try JSONSerialization.jsonObject(with: json) as? [String: Any]
        #expect(dict?["type"] as? String == "follow_ups")
    }

    @Test func doneOmitsPayloadKey() throws {
        let json = try JSONEncoder().encode(QueryStreamEvent.done)
        let dict = try JSONSerialization.jsonObject(with: json) as? [String: Any]
        #expect(dict?["type"] as? String == "done")
        #expect(dict?.keys.contains("payload") == false)
    }
}

@Suite("Conversation DTOs codable round-trip")
struct ConversationDTOCodableTests {
    @Test func conversation() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let c = ConversationDTO(
            id: UUID(),
            title: "Sleep patterns",
            spaceId: UUID(),
            createdAt: now,
            updatedAt: now
        )
        let data = try JSONEncoder().encode(c)
        let decoded = try JSONDecoder().decode(ConversationDTO.self, from: data)
        #expect(decoded.id == c.id)
        #expect(decoded.title == c.title)
        #expect(decoded.spaceId == c.spaceId)
    }

    @Test func message() throws {
        let m = ConversationMessageDTO(
            id: UUID(),
            conversationId: UUID(),
            role: .assistant,
            content: "Based on 7 notes from your vault…",
            sourceMemoryIDs: [UUID(), UUID()],
            createdAt: Date()
        )
        let data = try JSONEncoder().encode(m)
        let decoded = try JSONDecoder().decode(ConversationMessageDTO.self, from: data)
        #expect(decoded.role == .assistant)
        #expect(decoded.sourceMemoryIDs.count == 2)
    }

    @Test func roleWireValues() {
        #expect(ConversationMessageRole.user.rawValue == "user")
        #expect(ConversationMessageRole.assistant.rawValue == "assistant")
        #expect(ConversationMessageRole.system.rawValue == "system")
    }
}

@Suite("Backward-compatible additive DTO fields")
struct AdditiveFieldsTests {
    @Test func queryResponseFollowUpsIsOptionalAndDefaultsNil() throws {
        let r = QueryResponse(summary: "s", hits: [])
        #expect(r.followUps == nil)
    }

    @Test func queryResponseDecodesWithoutFollowUpsKey() throws {
        let legacyJSON = #"{"summary":"s","hits":[]}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(QueryResponse.self, from: legacyJSON)
        #expect(decoded.summary == "s")
        #expect(decoded.followUps == nil)
    }

    @Test func insightDTODecodesWithoutPeriodKeys() throws {
        let legacyJSON = """
        {"id":"00000000-0000-0000-0000-000000000000","headline":"h","summary":"s","section":"patterns","createdAt":\(Date().timeIntervalSinceReferenceDate),"sourceMemoryIDs":[],"dismissed":false}
        """.data(using: .utf8)!
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .deferredToDate
        let insight = try dec.decode(InsightDTO.self, from: legacyJSON)
        #expect(insight.periodStart == nil)
        #expect(insight.periodEnd == nil)
    }

    @Test func insightSectionAddsThisMonth() {
        #expect(InsightSection.thisMonth.rawValue == "this_month")
        #expect(InsightSection.allCases.contains(.thisMonth))
    }
}
