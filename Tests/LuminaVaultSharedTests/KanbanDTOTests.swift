import XCTest
@testable import LuminaVaultShared

final class KanbanDTOTests: XCTestCase {
    func testCardRoundTrips() throws {
        let card = CardDTO(
            id: UUID(), columnID: UUID(), title: "Write spec",
            body: "## notes", priority: .high,
            dueAt: Date(timeIntervalSince1970: 1_800_000_000),
            rank: "n", updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(card)
        let back = try JSONDecoder().decode(CardDTO.self, from: data)
        XCTAssertEqual(back, card)
    }

    func testBoardSnapshotDecodesNestedColumnsAndCards() throws {
        let json = """
        {"id":"\(UUID().uuidString)","title":"My Board","version":3,
         "columns":[{"id":"\(UUID().uuidString)","title":"Todo","rank":"a","cards":[]}]}
        """.data(using: .utf8)!
        let board = try JSONDecoder().decode(BoardDTO.self, from: json)
        XCTAssertEqual(board.title, "My Board")
        XCTAssertEqual(board.version, 3)
        XCTAssertEqual(board.columns.first?.title, "Todo")
    }
}
