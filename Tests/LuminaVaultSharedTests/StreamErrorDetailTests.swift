import Foundation
import Testing
@testable import LuminaVaultShared

/// A stream error that knows how the user can get out of it.
///
/// Over HTTP a routing refusal arrives as `{error:{code,message,cta}}` and the
/// clients render its `cta` tokens as buttons. Mid-stream the status is already
/// 200, so the same refusal used to arrive as a bare `error` string and the
/// buttons were lost. `errorDetail` carries the code and the tokens, on a wire
/// shape an older build still reads as a plain `.error(message)`.
struct StreamErrorDetailTests {
    private static let detail = StreamErrorDTO(
        message: "You've used today's free messages.",
        code: "free_lane_exhausted",
        cta: ["add_key", "switch_to_managed"]
    )

    private static func decode(_ json: String) throws -> QueryStreamEvent {
        try JSONDecoder().decode(QueryStreamEvent.self, from: Data(json.utf8))
    }

    private static func object(_ event: QueryStreamEvent) throws -> [String: Any] {
        let data = try JSONEncoder().encode(event)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("A detailed error keeps the plain error wire shape and adds code and cta beside it")
    func encodesAsErrorWithSiblings() throws {
        let json = try Self.object(.errorDetail(Self.detail))
        #expect(json["type"] as? String == "error")
        #expect(json["payload"] as? String == Self.detail.message)
        #expect(json["code"] as? String == "free_lane_exhausted")
        #expect(json["cta"] as? [String] == ["add_key", "switch_to_managed"])
    }

    @Test("A detailed error round-trips")
    func roundTrips() throws {
        let data = try JSONEncoder().encode(QueryStreamEvent.errorDetail(Self.detail))
        #expect(try JSONDecoder().decode(QueryStreamEvent.self, from: data) == .errorDetail(Self.detail))
    }

    @Test("A plain error still decodes as a plain error")
    func plainErrorUnchanged() throws {
        #expect(try Self.decode(#"{"type":"error","payload":"upstream failure"}"#) == .error("upstream failure"))
        let json = try Self.object(.error("upstream failure"))
        #expect(json["code"] == nil)
        #expect(json["cta"] == nil)
    }

    @Test("A code with no cta decodes with an empty cta")
    func codeWithoutCta() throws {
        let decoded = try Self.decode(#"{"type":"error","payload":"m","code":"byok_keys_required"}"#)
        #expect(decoded == .errorDetail(StreamErrorDTO(message: "m", code: "byok_keys_required", cta: [])))
    }

    /// What a 5.19.0 build does with the new frame: it knows only `type` and a
    /// string `payload`, and a keyed decode ignores the rest.
    @Test("A build that predates the detail reads it as its message")
    func olderShapeStillDecodes() throws {
        struct OldErrorFrame: Decodable {
            let type: String
            let payload: String
        }
        let data = try JSONEncoder().encode(QueryStreamEvent.errorDetail(Self.detail))
        let old = try JSONDecoder().decode(OldErrorFrame.self, from: data)
        #expect(old.type == "error")
        #expect(old.payload == Self.detail.message)
    }

    @Test("The message is what a client shows for either kind of error")
    func messageAccessor() {
        #expect(QueryStreamEvent.errorDetail(Self.detail).errorMessage == Self.detail.message)
        #expect(QueryStreamEvent.error("x").errorMessage == "x")
        #expect(QueryStreamEvent.done.errorMessage == nil)
    }
}
