import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Hermes runs contracts")
struct HermesRunsDTOTests {
    private func coder() -> (JSONEncoder, JSONDecoder) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (encoder, decoder)
    }

    @Test("status raw values are snake_case and terminal set is right")
    func statusRawValues() {
        #expect(HermesRunStatus.waitingForApproval.rawValue == "waiting_for_approval")
        #expect(HermesRunStatus(rawValue: "waiting_for_approval") == .waitingForApproval)
        #expect(HermesRunStatus.allCases.filter(\.isTerminal) == [.completed, .failed, .stopped, .lost])
    }

    @Test("run DTO round trips with a pending approval")
    func runRoundTrip() throws {
        let (encoder, decoder) = coder()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let run = HermesRunDTO(
            id: UUID(),
            hermesRunID: "run_abc",
            status: .waitingForApproval,
            prompt: "list files",
            sessionID: "sess-1",
            model: "hermes-3",
            conversationID: UUID(),
            startedAt: now,
            lastEvent: "approval.request",
            lastSeq: 4,
            pendingApproval: HermesRunPendingApprovalDTO(
                command: "rm -rf ***",
                choices: HermesApprovalChoice.allCases,
                requestedAt: now,
                extra: ["tool": .string("terminal")]
            )
        )
        let data = try encoder.encode(run)
        let decoded = try decoder.decode(HermesRunDTO.self, from: data)
        #expect(decoded == run)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains(#""status":"waiting_for_approval""#))
        #expect(json.contains(#""choices":["once","session","always","deny"]"#))
    }

    @Test("event DTO payload encodes as plain JSON and decodes back")
    func eventPayloadPlainJSON() throws {
        let (encoder, decoder) = coder()
        let event = HermesRunEventDTO(
            runID: UUID(),
            seq: 1,
            event: "tool.completed",
            payload: .object([
                "tool": .string("terminal"),
                "duration": .number(0.25),
                "error": .bool(false),
                "args": .array([.string("ls"), .null]),
            ]),
            at: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let data = try encoder.encode(event)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains(#""tool":"terminal""#))
        #expect(!json.contains("_0"))
        let decoded = try decoder.decode(HermesRunEventDTO.self, from: data)
        #expect(decoded == event)
    }

    @Test("start and approval requests decode from client JSON")
    func requestsDecode() throws {
        let (_, decoder) = coder()
        let start = try decoder.decode(
            HermesRunStartRequest.self,
            from: Data(#"{"prompt":"hi","sessionID":"s","model":"m"}"#.utf8)
        )
        #expect(start == HermesRunStartRequest(prompt: "hi", sessionID: "s", model: "m"))
        let approval = try decoder.decode(HermesRunApprovalRequest.self, from: Data(#"{"choice":"deny"}"#.utf8))
        #expect(approval.choice == .deny)
    }

    @Test("APNS categories include approval and runCompleted")
    func apnsCategories() {
        #expect(APNSCategory.approval.rawValue == "approval")
        #expect(APNSCategory.runCompleted.rawValue == "runCompleted")
        #expect(APNSCategory.allCases.count == 5)
    }
}
