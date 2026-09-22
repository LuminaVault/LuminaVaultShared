import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Agents page and agent-connection contracts")
struct AgentsDTOTests {
    private func coder() -> (JSONEncoder, JSONDecoder) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (encoder, decoder)
    }

    @Test("a connection from an older server decodes with the grant off")
    func connectionWithoutGrantDecodesAsOff() throws {
        let (_, decoder) = coder()
        let json = """
        {"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"laptop","clientKind":"hermes",
         "tokenPrefix":"lv_abcdefgh","createdAt":"2026-09-22T10:00:00Z"}
        """
        let dto = try decoder.decode(AgentConnectionDTO.self, from: Data(json.utf8))
        #expect(dto.allowPersonalData == false)
        #expect(dto.lastUsedAt == nil)
    }

    @Test("the grant round-trips")
    func grantRoundTrips() throws {
        let (encoder, decoder) = coder()
        let original = AgentConnectionDTO(
            id: UUID(), name: "vps", clientKind: .hermes, tokenPrefix: "lv_12345678",
            createdAt: Date(timeIntervalSince1970: 1_790_000_000), allowPersonalData: true
        )
        let decoded = try decoder.decode(AgentConnectionDTO.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("an issue request without the grant sends no field")
    func issueRequestOmitsNilGrant() throws {
        let data = try JSONEncoder().encode(AgentConnectionIssueRequest(name: "a", clientKind: .codex))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["allowPersonalData"] == nil)
    }

    @Test("sessions response round-trips with optional fields absent")
    func sessionsRoundTrip() throws {
        let (encoder, decoder) = coder()
        let original = AgentSessionsResponse(
            sessions: [
                AgentSessionDTO(
                    instanceID: "byo", profile: "mac-mcp", id: "tg_1", title: "Groceries", source: "telegram",
                    startedAt: Date(timeIntervalSince1970: 1_790_000_000), lastActiveAt: nil,
                    messageCount: 4, isActive: true, costUSD: 0.002
                ),
                AgentSessionDTO(
                    instanceID: "central", profile: nil, id: "c1", title: nil, source: "app",
                    startedAt: nil, lastActiveAt: nil, messageCount: nil, isActive: false, costUSD: nil
                ),
            ],
            errors: [AgentInstanceErrorDTO(instanceID: "byo", message: "Your Hermes did not answer.")]
        )
        #expect(try decoder.decode(AgentSessionsResponse.self, from: encoder.encode(original)) == original)
    }

    @Test("instance kinds and statuses keep their wire values")
    func wireValues() {
        #expect(AgentInstanceKind.central.rawValue == "central")
        #expect(AgentInstanceKind.byo.rawValue == "byo")
        #expect(AgentInstanceStatus.outdated.rawValue == "outdated")
        #expect(AgentInstanceStatus(rawValue: "unreachable") == .unreachable)
    }
}
