import Foundation
import Testing
@testable import LuminaVaultShared

/// The 5.17.0 additions: the run pointer, agent mode, attachments and the
/// context-meter fields.
///
/// The compatibility tests here matter more than the round-trips. Every new
/// field is optional so a 5.15-era server or client stays readable, and that
/// promise is only worth anything if something checks it — otherwise the
/// first sign of a break is a decode failure in TestFlight.
struct ChatAgentTurnContractTests {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Backward compatibility

    /// A usage payload written before these fields existed must still decode,
    /// with the new fields empty rather than throwing.
    @Test("A 5.15-era usage payload still decodes")
    func oldUsagePayloadDecodes() throws {
        let json = """
        {
          "executionID": "\(UUID().uuidString)",
          "tokensIn": 120,
          "tokensOut": 340,
          "estimatedCostUsdMicros": 4200,
          "latencyMs": 830,
          "usageEstimated": false
        }
        """
        let usage = try Self.decoder.decode(RouterUsageDTO.self, from: Data(json.utf8))
        #expect(usage.tokensIn == 120)
        #expect(usage.contextWindowTokens == nil)
        #expect(usage.toolCallCount == nil)
    }

    @Test("A 5.15-era routing payload still decodes")
    func oldRoutingPayloadDecodes() throws {
        let json = """
        {
          "executionID": "\(UUID().uuidString)",
          "phase": "selected",
          "profileID": "\(UUID().uuidString)",
          "profileName": "Auto",
          "taskType": "general",
          "strategy": "sequential",
          "activeRoutes": []
        }
        """
        let routing = try Self.decoder.decode(RouterRoutingEventDTO.self, from: Data(json.utf8))
        #expect(routing.profileName == "Auto")
        #expect(routing.promptTokens == nil)
        #expect(routing.contextWindowTokens == nil)
        #expect(routing.droppedHistoryTurns == nil)
    }

    /// An older client sends neither field. Absent must mean "as before",
    /// not "off" — treating a missing agentMode as `.off` would silently
    /// disable escalation for everyone who has not updated.
    @Test("A 5.15-era message request still decodes and leaves the new fields empty")
    func oldMessageRequestDecodes() throws {
        let request = try Self.decoder.decode(
            MessageStreamRequest.self,
            from: Data(#"{"content":"hello"}"#.utf8)
        )
        #expect(request.content == "hello")
        #expect(request.agentMode == nil)
        #expect(request.attachments == nil)
    }

    // MARK: - The run pointer

    @Test("The run pointer round-trips")
    func runPointerRoundTrips() throws {
        let ref = ChatHermesRunRefDTO(
            runID: UUID(),
            sessionID: "sess-1",
            afterSeq: 0,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let event = QueryStreamEvent.hermesRun(ref)
        let data = try Self.encoder.encode(event)
        #expect(try Self.decoder.decode(QueryStreamEvent.self, from: data) == event)
    }

    /// The wire tag is what every client switches on, and what 5.16.0's
    /// tolerance was released to survive. Changing it silently would strand
    /// both clients.
    @Test("The run pointer's wire tag is hermes_run")
    func runPointerWireTag() throws {
        let ref = ChatHermesRunRefDTO(runID: UUID(), startedAt: Date())
        let object = try #require(
            try JSONSerialization.jsonObject(
                with: Self.encoder.encode(QueryStreamEvent.hermesRun(ref))
            ) as? [String: Any]
        )
        #expect(object["type"] as? String == "hermes_run")
        #expect(object["payload"] is [String: Any])
    }

    /// A 5.16.0 client — tolerant but not yet aware of this type — must see
    /// it as unrecognised and skip it, rather than throw. That is the whole
    /// reason 5.16.0 shipped first.
    @Test("An unknown payload shape on a known tag still throws")
    func malformedRunPointerThrows() {
        #expect(throws: (any Error).self) {
            _ = try Self.decoder.decode(
                QueryStreamEvent.self,
                from: Data(#"{"type":"hermes_run","payload":{"runID":"not-a-uuid"}}"#.utf8)
            )
        }
    }

    @Test("A run pointer omitting the optional session decodes")
    func runPointerWithoutSession() throws {
        let json = """
        {"runID":"\(UUID().uuidString)","afterSeq":0,"startedAt":"2026-09-18T10:00:00Z"}
        """
        let ref = try Self.decoder.decode(ChatHermesRunRefDTO.self, from: Data(json.utf8))
        #expect(ref.sessionID == nil)
    }

    // MARK: - Agent mode and attachments

    @Test("Agent modes use their bare names on the wire")
    func agentModeWireValues() {
        #expect(ChatAgentModeDTO.off.rawValue == "off")
        #expect(ChatAgentModeDTO.auto.rawValue == "auto")
        #expect(ChatAgentModeDTO.force.rawValue == "force")
        #expect(ChatAgentModeDTO.allCases.count == 3)
    }

    @Test("Attachment kinds keep their snake_case wire spelling")
    func attachmentKindWireValues() {
        #expect(ChatAttachmentDTO.Kind.text.rawValue == "text")
        #expect(ChatAttachmentDTO.Kind.vaultFile.rawValue == "vault_file")
        #expect(ChatAttachmentDTO.Kind.link.rawValue == "link")
    }

    @Test("A request carrying mode and attachments round-trips")
    func requestWithAttachmentsRoundTrips() throws {
        let request = MessageStreamRequest(
            content: "summarise these",
            agentMode: .force,
            attachments: [
                ChatAttachmentDTO(kind: .text, name: "notes.txt", text: "hello"),
                ChatAttachmentDTO(kind: .vaultFile, name: "plan.md", vaultPath: "notes/plan.md"),
                ChatAttachmentDTO(kind: .link, name: "spec", url: "https://example.com")
            ]
        )
        let decoded = try Self.decoder.decode(
            MessageStreamRequest.self,
            from: Self.encoder.encode(request)
        )
        #expect(decoded.agentMode == .force)
        #expect(decoded.attachments?.count == 3)
        #expect(decoded.attachments?[1].vaultPath == "notes/plan.md")
    }

    /// The server decodes request bodies with a camelCase decoder, so the
    /// property names are the wire names. `vaultPath` arriving as
    /// `vault_path` is the exact shape of a past outage.
    @Test("Request bodies encode camelCase property names")
    func requestEncodesCamelCase() throws {
        let request = MessageStreamRequest(
            content: "hi",
            agentMode: .auto,
            attachments: [ChatAttachmentDTO(kind: .vaultFile, name: "p", vaultPath: "a/b.md")]
        )
        // Plain encoder: what the clients actually use for request bodies.
        let object = try #require(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        )
        #expect(object["agentMode"] != nil)
        let attachments = try #require(object["attachments"] as? [[String: Any]])
        #expect(attachments[0]["vaultPath"] != nil)
        #expect(attachments[0]["vault_path"] == nil)
    }
}
