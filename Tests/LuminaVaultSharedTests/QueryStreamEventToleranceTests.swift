import Foundation
import Testing
@testable import LuminaVaultShared

/// The chat SSE decoder used to decode `type` straight into a strict enum, so
/// an event type the build did not know threw — and `BaseHTTPClient.executeStream`
/// turns a decode throw into a dead stream, losing the whole chat turn rather
/// than one frame. These tests pin the tolerance that replaced it, because the
/// server needs to be able to add event types ahead of a client release.
struct QueryStreamEventToleranceTests {
    private static func decode(_ json: String) throws -> QueryStreamEvent {
        try JSONDecoder().decode(QueryStreamEvent.self, from: Data(json.utf8))
    }

    /// Uses a tag that is deliberately not a real event. An earlier version
    /// of this test used `hermes_run`, which stopped being unknown the moment
    /// 5.17.0 added it — a test asserting "unknown" must not name something
    /// the codebase is about to implement.
    @Test("An unknown event type decodes as unrecognized instead of throwing")
    func unknownTypeDoesNotThrow() throws {
        let decoded = try Self.decode(#"{"type":"not_a_real_event","payload":{"anything":1}}"#)
        #expect(decoded == .unrecognized("not_a_real_event"))
    }

    @Test("An unknown event type with no payload key also decodes")
    func unknownTypeWithoutPayload() throws {
        let decoded = try Self.decode(#"{"type":"some_future_event"}"#)
        #expect(decoded == .unrecognized("some_future_event"))
    }

    @Test("A malformed payload on a KNOWN type still throws")
    func knownTypeWithBadPayloadStillThrows() {
        // Tolerance must not extend to corrupt payloads on types we do know —
        // that is a real bug and should surface, not be silently skipped.
        #expect(throws: (any Error).self) {
            _ = try Self.decode(#"{"type":"token","payload":{"not":"a string"}}"#)
        }
    }

    @Test("Re-encoding an unrecognized event keeps the tag and drops the payload")
    func unrecognizedReencodesLossily() throws {
        let data = try JSONEncoder().encode(QueryStreamEvent.unrecognized("not_a_real_event"))
        let object = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(object["type"] as? String == "not_a_real_event")
        #expect(object["payload"] == nil)
        #expect(
            try JSONDecoder().decode(QueryStreamEvent.self, from: data)
                == .unrecognized("not_a_real_event")
        )
    }

    @Test("Every existing case still round-trips unchanged")
    func knownCasesRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let cases: [QueryStreamEvent] = [
            .token("hello"),
            .summary("a summary"),
            .followUps(["one", "two"]),
            .done,
            .error("boom"),
            .linkSaved(
                LinkSavedDTO(
                    url: "https://example.com",
                    vaultPath: "captures/example.md",
                    capturedAt: Date(timeIntervalSince1970: 1_000),
                    fromUserMessage: true
                )
            ),
        ]

        for value in cases {
            let data = try encoder.encode(value)
            #expect(try decoder.decode(QueryStreamEvent.self, from: data) == value)
        }
    }

    @Test("A known type's wire tag is unchanged by the tolerance change")
    func wireTagsAreStable() throws {
        // follow_ups and link_saved are snake_case on the wire; a regression
        // here would silently break every shipped client.
        let followUps = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(QueryStreamEvent.followUps(["a"]))
        ) as? [String: Any]
        #expect(followUps?["type"] as? String == "follow_ups")
    }
}
