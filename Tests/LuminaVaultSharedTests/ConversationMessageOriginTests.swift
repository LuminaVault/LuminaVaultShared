import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Conversation message origin contract")
struct ConversationMessageOriginTests {
    private let base = """
    "id":"6F9619FF-8B86-D011-B42D-00C04FC964FF",
    "conversationId":"7F9619FF-8B86-D011-B42D-00C04FC964FF",
    "role":"assistant","content":"Rain on Thursday.","sourceMemoryIDs":[],
    "createdAt":0
    """

    @Test("a message from a pre-5.20 server decodes as a reply")
    func absentOriginIsReply() throws {
        let json = "{\(base)}"
        let m = try JSONDecoder().decode(ConversationMessageDTO.self, from: Data(json.utf8))
        #expect(m.origin == .reply)
        #expect(m.sourceLabel == nil)
    }

    @Test("a proactive message carries its source label")
    func proactiveDecodes() throws {
        let json = "{\(base),\"origin\":\"proactive\",\"sourceLabel\":\"daily-brief\"}"
        let m = try JSONDecoder().decode(ConversationMessageDTO.self, from: Data(json.utf8))
        #expect(m.origin == .proactive)
        #expect(m.sourceLabel == "daily-brief")
    }

    @Test("an origin this client does not know degrades to reply instead of failing")
    func unknownOriginIsReply() throws {
        let json = "{\(base),\"origin\":\"telepathic\",\"sourceLabel\":null}"
        let m = try JSONDecoder().decode(ConversationMessageDTO.self, from: Data(json.utf8))
        #expect(m.origin == .reply)
    }

    @Test("round-trips and puts the wire names on the wire")
    func roundTrip() throws {
        let m = ConversationMessageDTO(
            id: UUID(), conversationId: UUID(), role: .assistant, content: "Hi",
            origin: .proactive, sourceLabel: "Standing task", createdAt: Date()
        )
        let data = try JSONEncoder().encode(m)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["origin"] as? String == "proactive")
        #expect(object["sourceLabel"] as? String == "Standing task")
        let decoded = try JSONDecoder().decode(ConversationMessageDTO.self, from: data)
        #expect(decoded.origin == .proactive)
        #expect(decoded.sourceLabel == "Standing task")
    }

    @Test("the default origin is reply")
    func defaultIsReply() {
        let m = ConversationMessageDTO(
            id: UUID(), conversationId: UUID(), role: .user, content: "Hi", createdAt: Date()
        )
        #expect(m.origin == .reply)
        #expect(m.sourceLabel == nil)
    }
}

@Suite("Muse data-source settings contracts")
struct MuseDataSourceSettingsTests {
    @Test("Gmail status decodes the server shape")
    func gmailStatus() throws {
        let json = #"{"connected":true,"needsReauth":false,"accountEmail":"a@b.c","calendarConnected":true}"#
        let s = try JSONDecoder().decode(GmailStatusResponse.self, from: Data(json.utf8))
        #expect(s == GmailStatusResponse(connected: true, needsReauth: false, accountEmail: "a@b.c", calendarConnected: true))
    }

    @Test("an empty location cache decodes with only `cached`")
    func emptyLocation() throws {
        let s = try JSONDecoder().decode(LastKnownLocationResponse.self, from: Data(#"{"cached":false}"#.utf8))
        #expect(s == LastKnownLocationResponse(cached: false))
    }
}
