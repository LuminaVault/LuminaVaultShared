import Foundation
import Testing
@testable import LuminaVaultShared

struct JobOriginDTOTests {
    @Test("an unknown origin kind decodes instead of failing")
    func unknownKind() throws {
        let id = UUID()
        let origin = try JSONDecoder().decode(JobOriginDTO.self, from: Data(#"{"kind":"email","id":"\#(id)"}"#.utf8))
        #expect(origin.kind == .unknown)
        #expect(origin.id == id)
    }

    @Test("origin round-trips and a request sends the conversation only when set")
    func roundTrip() throws {
        let origin = JobOriginDTO(kind: .conversation, id: UUID())
        #expect(try JSONDecoder().decode(JobOriginDTO.self, from: JSONEncoder().encode(origin)) == origin)
        let bare = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(JobCreateRequest(title: "t", cron: "0 9 * * *", spec: "s"))
        ) as? [String: Any]
        #expect(bare?["conversationId"] == nil)
    }
}
