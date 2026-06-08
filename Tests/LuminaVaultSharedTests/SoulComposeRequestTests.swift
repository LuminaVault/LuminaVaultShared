import XCTest
@testable import LuminaVaultShared

final class SoulComposeRequestTests: XCTestCase {
    func testDecodesFromSnakeCaseWire() throws {
        let json = """
        { "agent_name": "Athena", "tone": "warm", "role": "second_brain", "autonomy": "ask_first" }
        """.data(using: .utf8)!
        let req = try JSONDecoder().decode(SoulComposeRequest.self, from: json)
        XCTAssertEqual(req.agentName, "Athena")
        XCTAssertEqual(req.tone, .warm)
        XCTAssertEqual(req.role, .secondBrain)
        XCTAssertEqual(req.autonomy, .askFirst)
    }

    func testEncodeRoundTrip() throws {
        let req = SoulComposeRequest(agentName: "Hermes", tone: .conciseTechnical, role: .coworker, autonomy: .act)
        let data = try JSONEncoder().encode(req)
        let back = try JSONDecoder().decode(SoulComposeRequest.self, from: data)
        XCTAssertEqual(back.agentName, "Hermes")
        XCTAssertEqual(back.tone, .conciseTechnical)
        XCTAssertEqual(back.role, .coworker)
        XCTAssertEqual(back.autonomy, .act)
    }
}
