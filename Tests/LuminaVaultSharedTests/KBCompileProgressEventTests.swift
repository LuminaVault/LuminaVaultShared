import Foundation
import Testing
@testable import LuminaVaultShared

// MARK: - HER-288 KBCompileProgressEvent round-trip tests

@Suite("KBCompileProgressEvent Codable")
struct KBCompileProgressEventTests {
    private let runId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    private func roundTrip(_ event: KBCompileProgressEvent) throws -> KBCompileProgressEvent {
        let data = try JSONEncoder().encode(event)
        return try JSONDecoder().decode(KBCompileProgressEvent.self, from: data)
    }

    @Test func startedRoundTrip() throws {
        let original: KBCompileProgressEvent = .started(.init(runId: runId, totalFiles: 12))
        #expect(try roundTrip(original) == original)
    }

    @Test func preparingRoundTrip() throws {
        let original: KBCompileProgressEvent = .preparing(.init(runId: runId))
        #expect(try roundTrip(original) == original)
    }

    @Test func thinkingRoundTrip() throws {
        let original: KBCompileProgressEvent = .thinking(.init(runId: runId, iteration: 3))
        #expect(try roundTrip(original) == original)
    }

    @Test func memorySavedRoundTrip() throws {
        let memory = MemoryDTO(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            content: "user prefers dark mode",
            tags: ["preferences"],
            createdAt: nil
        )
        let original: KBCompileProgressEvent = .memorySaved(.init(runId: runId, memory: memory))
        #expect(try roundTrip(original) == original)
    }

    @Test func completedRoundTrip() throws {
        let response = KBCompileResponse(
            memoriesIngested: 5,
            memoriesUpdated: nil,
            durationMs: 4123,
            runId: runId
        )
        let original: KBCompileProgressEvent = .completed(.init(runId: runId, response: response))
        #expect(try roundTrip(original) == original)
    }

    @Test func errorRoundTrip() throws {
        let original: KBCompileProgressEvent = .error(.init(runId: runId, message: "transport failed"))
        #expect(try roundTrip(original) == original)
    }

    @Test func wireEnvelopeShape() throws {
        let event: KBCompileProgressEvent = .started(.init(runId: runId, totalFiles: 0))
        let data = try JSONEncoder().encode(event)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["type"] as? String == "started")
        #expect(json["payload"] is [String: Any])

        // Pin the exact `memorySaved` wire discriminator string to guard against
        // accidental raw-value drift (e.g. someone renaming the case to "memory_saved").
        let memory = MemoryDTO(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            content: "pin check",
            tags: [],
            createdAt: nil
        )
        let memorySavedEvent: KBCompileProgressEvent = .memorySaved(.init(runId: runId, memory: memory))
        let memorySavedData = try JSONEncoder().encode(memorySavedEvent)
        let memorySavedJSON = try #require(try JSONSerialization.jsonObject(with: memorySavedData) as? [String: Any])
        #expect(memorySavedJSON["type"] as? String == "memorySaved")
        #expect(memorySavedJSON["payload"] is [String: Any])
    }

    @Test func unknownTypeFailsToDecode() {
        let json = #"{"type":"bogus","payload":{}}"#.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(KBCompileProgressEvent.self, from: json)
        }
    }
}
