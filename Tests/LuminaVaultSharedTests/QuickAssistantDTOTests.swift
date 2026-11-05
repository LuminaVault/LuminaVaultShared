import Foundation
import Testing
@testable import LuminaVaultShared

struct QuickAssistantDTOTests {
    @Test func requestWithoutQuickAssistantDecodes() throws {
        let req = try JSONDecoder().decode(MessageStreamRequest.self, from: Data(#"{"content":"hi"}"#.utf8))
        #expect(req.quickAssistant == nil)
    }

    @Test func requestCarriesQuickAssistantContext() throws {
        let space = UUID()
        let ctx = QuickAssistantContextDTO(currentTab: "home", activeSpaceID: space)
        let data = try JSONEncoder().encode(MessageStreamRequest(content: "hi", quickAssistant: ctx))
        let decoded = try JSONDecoder().decode(MessageStreamRequest.self, from: data)
        #expect(decoded.quickAssistant == ctx)
        #expect(decoded.quickAssistant?.activeSpaceID == space)
    }

    @Test func contextCarriesTheDevicesTimeZone() throws {
        let ctx = QuickAssistantContextDTO(currentTab: "home", timeZone: "America/Santiago")
        let data = try JSONEncoder().encode(ctx)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["timeZone"] as? String == "America/Santiago")
        #expect(try JSONDecoder().decode(QuickAssistantContextDTO.self, from: data) == ctx)
    }

    @Test func contextFromAnOlderClientHasNoTimeZone() throws {
        let decoded = try JSONDecoder().decode(QuickAssistantContextDTO.self, from: Data(#"{"currentTab":"home"}"#.utf8))
        #expect(decoded.timeZone == nil)
        #expect(QuickAssistantContextDTO(currentTab: "home").timeZone == nil)
    }

    @Test func assistantActionFrameRoundTrips() throws {
        let action = AssistantActionDTO(
            id: UUID(),
            kind: .needsConfirm,
            summary: "Delete memory?",
            screen: .memory,
            memoryID: UUID(),
            expiresAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let data = try JSONEncoder().encode(QueryStreamEvent.assistantAction(action))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["type"] as? String == "assistant_action")

        let decoded = try JSONDecoder().decode(QueryStreamEvent.self, from: data)
        #expect(decoded == .assistantAction(action))
        guard case let .assistantAction(got) = decoded else {
            Issue.record("expected assistantAction")
            return
        }
        #expect(got.id == action.id)
        #expect(got.kind == action.kind)
        #expect(got.summary == action.summary)
        #expect(got.screen == action.screen)
        #expect(got.memoryID == action.memoryID)
        #expect(got.expiresAt == action.expiresAt)
    }

    @Test func unknownActionKindDoesNotThrow() throws {
        let id = UUID()
        let json = #"{"id":"\#(id.uuidString)","kind":"future","summary":"s"}"#
        let action = try JSONDecoder().decode(AssistantActionDTO.self, from: Data(json.utf8))
        #expect(action.kind == .unknown)
        #expect(action.screen == nil)
        #expect(action.memoryID == nil)
        #expect(action.expiresAt == nil)
    }

    @Test func resolutionRoundTrips() throws {
        let res = AssistantActionResolutionDTO(status: .alreadyResolved, message: "done earlier")
        let decoded = try JSONDecoder().decode(
            AssistantActionResolutionDTO.self,
            from: JSONEncoder().encode(res)
        )
        #expect(decoded == res)
    }

    @Test func unknownScreenInStreamFrameDecodesToUnknown() throws {
        let id = UUID()
        let frame = #"{"type":"assistant_action","payload":{"id":"\#(id.uuidString)","kind":"openScreen","summary":"s","screen":"future"}}"#
        let event = try JSONDecoder().decode(QueryStreamEvent.self, from: Data(frame.utf8))
        guard case let .assistantAction(action) = event else {
            Issue.record("expected assistantAction, got \(event)")
            return
        }
        #expect(action.kind == .openScreen)
        #expect(action.screen == .unknown)
    }

    @Test func unknownKindInStreamFrameDecodesToUnknown() throws {
        let id = UUID()
        let frame = #"{"type":"assistant_action","payload":{"id":"\#(id.uuidString)","kind":"future","summary":"s"}}"#
        let event = try JSONDecoder().decode(QueryStreamEvent.self, from: Data(frame.utf8))
        guard case let .assistantAction(action) = event else {
            Issue.record("expected assistantAction, got \(event)")
            return
        }
        #expect(action.kind == .unknown)
    }

    @Test func unknownStatusDecodesToUnknown() throws {
        let res = try JSONDecoder().decode(
            AssistantActionResolutionDTO.self,
            from: Data(#"{"status":"future","message":"m"}"#.utf8)
        )
        #expect(res.status == .unknown)
    }
}
