import Foundation
import Testing
@testable import LuminaVaultShared

struct BriefDTOTests {
    @Test("a brief with cards and refs round-trips")
    func briefRoundTrip() throws {
        let brief = BriefDTO(
            id: UUID(),
            date: "2026-10-20",
            cards: [
                BriefCardDTO(
                    id: "openLoops",
                    kind: .openLoops,
                    title: "Open loops",
                    body: "- Send Ana the deck",
                    why: "You said you'd do this on Friday",
                    refs: [BriefCardRefDTO(kind: .commitment, id: UUID().uuidString)]
                ),
                BriefCardDTO(id: "onYourMind", kind: .onYourMind, title: "On your mind", body: "text"),
            ],
            endNote: "That's it for today.",
            createdAt: Date(timeIntervalSince1970: 1)
        )
        let response = MeBriefResponse(brief: brief)
        let data = try JSONEncoder().encode(response)
        #expect(try JSONDecoder().decode(MeBriefResponse.self, from: data) == response)
    }

    @Test("no brief that day decodes as nil, not an error")
    func emptyBrief() throws {
        let decoded = try JSONDecoder().decode(MeBriefResponse.self, from: Data(#"{"brief":null}"#.utf8))
        #expect(decoded.brief == nil)
        #expect(try JSONDecoder().decode(MeBriefResponse.self, from: Data("{}".utf8)).brief == nil)
    }

    @Test("unknown card and ref kinds degrade to .unknown")
    func lenientKinds() throws {
        let json = #"{"id":"x","kind":"stocks","title":"t","body":"b","refs":[{"kind":"photo","id":"1"}]}"#
        let card = try JSONDecoder().decode(BriefCardDTO.self, from: Data(json.utf8))
        #expect(card.kind == .unknown)
        #expect(card.refs.first?.kind == .unknown)
        #expect(card.why == nil)
    }

    @Test("feedback request encodes its action")
    func feedback() throws {
        let data = try JSONEncoder().encode(BriefCardFeedbackRequest(action: .dismiss))
        #expect(String(decoding: data, as: UTF8.self) == #"{"action":"dismiss"}"#)
    }
}

struct CommitmentDTOTests {
    @Test("commitments round-trip with optional fields")
    func roundTrip() throws {
        let response = CommitmentsResponse(items: [
            CommitmentDTO(
                id: UUID(),
                text: "Call the dentist",
                dueAt: Date(timeIntervalSince1970: 100),
                state: .open,
                surfacedCount: 2,
                memoryId: UUID(),
                createdAt: Date(timeIntervalSince1970: 1)
            ),
            CommitmentDTO(id: UUID(), text: "Renew passport", state: .done, createdAt: Date(), doneAt: Date()),
        ])
        let data = try JSONEncoder().encode(response)
        #expect(try JSONDecoder().decode(CommitmentsResponse.self, from: data) == response)
    }

    @Test("an unknown state degrades to .unknown")
    func lenientState() throws {
        let decoded = try JSONDecoder().decode(CommitmentUpdateRequest.self, from: Data(#"{"state":"snoozed"}"#.utf8))
        #expect(decoded.state == .unknown)
        let known = try JSONDecoder().decode(CommitmentUpdateRequest.self, from: Data(#"{"state":"dropped"}"#.utf8))
        #expect(known.state == .dropped)
    }
}
