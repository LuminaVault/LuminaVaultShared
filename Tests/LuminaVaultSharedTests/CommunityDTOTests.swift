import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Community board contract")
struct CommunityDTOTests {
    private let aiPost = """
    {"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","parentId":null,
    "title":"Your inbox is not a to-do list","body":"…","author":{"kind":"ai"},
    "isDailyPost":true,"aiLabel":"AI-generated · Daily Post","status":"visible",
    "replyCount":3,"reactionCount":0,"viewerReacted":false,"isOwn":false,
    "createdAt":0,"lastActivityAt":0}
    """

    @Test("the AI Daily Post decodes with its label and no profile")
    func aiPostDecodes() throws {
        let post = try JSONDecoder().decode(CommunityPostDTO.self, from: Data(aiPost.utf8))
        #expect(post.author.kind == .ai)
        #expect(post.author.profileId == nil)
        #expect(post.author.handle == nil)
        #expect(post.isDailyPost)
        #expect(post.aiLabel == "AI-generated · Daily Post")
        #expect(post.status == .visible)
    }

    @Test("an author kind or status this client does not know degrades to unknown")
    func unknownEnumsDegrade() throws {
        let json = aiPost
            .replacingOccurrences(of: "\"kind\":\"ai\"", with: "\"kind\":\"bot\"")
            .replacingOccurrences(of: "\"status\":\"visible\"", with: "\"status\":\"quarantined\"")
        let post = try JSONDecoder().decode(CommunityPostDTO.self, from: Data(json.utf8))
        #expect(post.author.kind == .unknown)
        #expect(post.status == .unknown)
    }

    @Test("a member post round-trips with camelCase wire names")
    func memberPostRoundTrips() throws {
        let profileID = UUID()
        let post = CommunityPostDTO(
            id: UUID(), parentId: UUID(), title: nil, body: "Agreed — weekly review saves me.",
            author: CommunityAuthorDTO(kind: .user, profileId: profileID, handle: "ana_k", displayName: "Ana"),
            status: .pending, isOwn: true, createdAt: Date(), lastActivityAt: Date()
        )
        let data = try JSONEncoder().encode(post)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["parentId"] != nil)
        #expect(object["isOwn"] as? Bool == true)
        #expect(object["status"] as? String == "pending")
        let author = try #require(object["author"] as? [String: Any])
        #expect(author["kind"] as? String == "user")
        #expect(author["displayName"] as? String == "Ana")
        #expect(try JSONDecoder().decode(CommunityPostDTO.self, from: data) == post)
    }

    @Test("a report reason uses snake_case on the wire and unknown reasons become other")
    func reportReasons() throws {
        let data = try JSONEncoder().encode(CommunityReportRequest(reason: .selfHarm))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["reason"] as? String == "self_harm")
        let odd = try JSONDecoder().decode(CommunityReportRequest.self, from: Data(#"{"reason":"vibes"}"#.utf8))
        #expect(odd.reason == .other)
        #expect(odd.note == nil)
    }

    @Test("me decodes for a signed-in user without a profile yet")
    func meWithoutProfile() throws {
        let json = """
        {"enabled":true,"postingEnabled":true,"profile":null,"termsVersionRequired":1,"isModerator":false}
        """
        let me = try JSONDecoder().decode(CommunityMeDTO.self, from: Data(json.utf8))
        #expect(me.enabled)
        #expect(me.profile == nil)
        #expect(me.termsVersionRequired == 1)
    }

    @Test("a page with no next cursor marks the end")
    func pageEnd() throws {
        let json = #"{"items":[],"nextCursor":null}"#
        let page = try JSONDecoder().decode(CommunityPostPageDTO.self, from: Data(json.utf8))
        #expect(page.items.isEmpty)
        #expect(page.nextCursor == nil)
    }

    @Test("lifting a suspension sends a null until")
    func liftSuspension() throws {
        let data = try JSONEncoder().encode(CommunityProfileSuspendRequest(until: nil))
        let decoded = try JSONDecoder().decode(CommunityProfileSuspendRequest.self, from: data)
        #expect(decoded.until == nil)
    }
}
