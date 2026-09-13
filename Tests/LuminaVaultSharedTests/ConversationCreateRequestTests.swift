import Foundation
import Testing
@testable import LuminaVaultShared

/// `POST /v1/conversations` request contract.
///
/// `pinnedMemoryIDs` is optional in the OpenAPI schema and defaults to `[]` in
/// the memberwise initialiser, but a memberwise default never reaches `Codable`
/// — a synthesized `init(from:)` treats a non-optional array as required. That
/// mismatch turned every create call that omitted the key into a 400, which is
/// the same failure that once reached TestFlight (see the note in the client's
/// `APIRequestFailure.swift`). These tests pin the decoder to the schema.
@Suite("Conversation create request contract")
struct ConversationCreateRequestTests {
    private func decode(_ json: String) throws -> ConversationCreateRequest {
        try JSONDecoder().decode(ConversationCreateRequest.self, from: Data(json.utf8))
    }

    @Test("a body with only a title decodes, with no pinned memories")
    func titleOnly() throws {
        let request = try decode(#"{"title":"Sleep patterns"}"#)
        #expect(request.title == "Sleep patterns")
        #expect(request.pinnedMemoryIDs.isEmpty)
        #expect(request.spaceId == nil)
        #expect(request.routeOverride == nil)
    }

    @Test("an empty body decodes — every field is optional in the schema")
    func emptyBody() throws {
        let request = try decode("{}")
        #expect(request.title == nil)
        #expect(request.pinnedMemoryIDs.isEmpty)
    }

    @Test("an explicit null for the array is treated as absent")
    func explicitNull() throws {
        let request = try decode(#"{"title":"x","pinnedMemoryIDs":null}"#)
        #expect(request.pinnedMemoryIDs.isEmpty)
    }

    @Test("pinned ids are kept when sent")
    func pinnedIDsPreserved() throws {
        let id = UUID()
        let request = try decode(#"{"pinnedMemoryIDs":["\#(id.uuidString)"]}"#)
        #expect(request.pinnedMemoryIDs == [id])
    }

    @Test("the wire shape is camelCase — pinned_memory_i_ds is not the key")
    func encodesCamelCase() throws {
        let encoded = try JSONEncoder().encode(
            ConversationCreateRequest(title: "x", pinnedMemoryIDs: [UUID()])
        )
        let json = try #require(String(data: encoded, encoding: .utf8))
        #expect(json.contains("pinnedMemoryIDs"))
        #expect(!json.contains("pinned_memory"))
    }

    @Test("round trips through encode and decode")
    func roundTrip() throws {
        let original = ConversationCreateRequest(
            title: "Sleep patterns",
            spaceId: UUID(),
            pinnedMemoryIDs: [UUID(), UUID()]
        )
        let decoded = try JSONDecoder().decode(
            ConversationCreateRequest.self,
            from: JSONEncoder().encode(original)
        )
        #expect(decoded.title == original.title)
        #expect(decoded.spaceId == original.spaceId)
        #expect(decoded.pinnedMemoryIDs == original.pinnedMemoryIDs)
    }
}
