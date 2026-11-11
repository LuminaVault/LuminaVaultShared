import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Brain graph contracts")
struct BrainGraphDTOTests {
    private static let vaultID = "6F1C2B7A-0D4E-4B8E-9A55-1C2D3E4F5A6B"
    private static let otherVaultID = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
    private static let noteID = "11111111-2222-3333-4444-555555555555"
    private static let spaceID = "99999999-8888-7777-6666-555555555555"
    private static let refID = "12345678-1234-1234-1234-123456789ABC"

    private static let fullJSON = """
    {
      "generatedAt": "2026-11-11T10:00:00Z",
      "truncated": true,
      "vaults": [
        {"id": "\(vaultID)", "name": "Personal", "personal": true},
        {"id": "\(otherVaultID)", "name": "Team"}
      ],
      "nodes": [
        {"id": "\(noteID)", "kind": "note", "label": "Pricing", "vaultID": "\(vaultID)",
         "spaceID": "\(spaceID)", "weight": 4, "createdAt": "2026-11-01T08:30:00Z",
         "pos": {"x": 1.5, "y": -2, "z": 0.25}},
        {"id": "tag:go", "kind": "tag", "label": "go", "weight": 2},
        {"id": "author:model:anthropic/claude-haiku-5-5", "kind": "author", "label": "Haiku", "weight": 1},
        {"id": "entity:acme", "kind": "entity", "label": "Acme", "weight": 3,
         "refs": [{"vaultID": "\(vaultID)", "id": "\(refID)"}]},
        {"id": "space:\(spaceID)", "kind": "space", "label": "Work", "vaultID": "\(vaultID)", "weight": 1}
      ],
      "edges": [
        {"from": "\(noteID)", "to": "tag:go", "kind": "tag"},
        {"from": "\(noteID)", "to": "\(refID)", "kind": "similar", "weight": 0.83}
      ]
    }
    """

    private func decode<T: Decodable>(_: T.Type, _ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: #require(json.data(using: .utf8)))
    }

    @Test("a full response decodes")
    func fullResponse() throws {
        let graph = try decode(BrainGraphResponse.self, Self.fullJSON)
        #expect(graph.truncated)
        #expect(graph.vaults.count == 2)
        #expect(graph.nodes.count == 5)
        #expect(graph.edges.count == 2)
        #expect(graph.generatedAt == Date(timeIntervalSince1970: 1_794_391_200))
        let note = graph.nodes[0]
        #expect(note.kind == .note)
        #expect(note.weight == 4)
        #expect(note.createdAt != nil)
        #expect(note.pos == GraphPosition3D(x: 1.5, y: -2, z: 0.25))
        #expect(note.refs == nil)
    }

    @Test("uppercase uuids decode into UUID")
    func uppercaseUUIDs() throws {
        let graph = try decode(BrainGraphResponse.self, Self.fullJSON)
        #expect(graph.vaults[0].id == UUID(uuidString: Self.vaultID))
        #expect(graph.nodes[0].vaultID == UUID(uuidString: Self.vaultID))
        #expect(graph.nodes[0].spaceID == UUID(uuidString: Self.spaceID))
    }

    @Test("personal defaults to false when missing")
    func personalDefault() throws {
        let graph = try decode(BrainGraphResponse.self, Self.fullJSON)
        #expect(graph.vaults[0].personal)
        #expect(graph.vaults[1].personal == false)
    }

    @Test("a hub node has no vaultID and keeps its id verbatim")
    func hubNodes() throws {
        let graph = try decode(BrainGraphResponse.self, Self.fullJSON)
        let tag = graph.nodes[1]
        #expect(tag.vaultID == nil)
        #expect(tag.spaceID == nil)
        #expect(tag.createdAt == nil)
        #expect(tag.pos == nil)
        #expect(tag.id == "tag:go")
        #expect(graph.nodes[2].id == "author:model:anthropic/claude-haiku-5-5")
        #expect(graph.nodes[4].id == "space:\(Self.spaceID)")
        #expect(graph.nodes[4].vaultID == UUID(uuidString: Self.vaultID))
    }

    @Test("an entity hub's refs decode")
    func entityRefs() throws {
        let graph = try decode(BrainGraphResponse.self, Self.fullJSON)
        let refs = try #require(graph.nodes[3].refs)
        let vault = try #require(UUID(uuidString: Self.vaultID))
        let ref = try #require(UUID(uuidString: Self.refID))
        #expect(refs == [BrainGraphRefDTO(vaultID: vault, id: ref)])
    }

    @Test("a similar edge carries weight, others do not")
    func edgeWeight() throws {
        let graph = try decode(BrainGraphResponse.self, Self.fullJSON)
        #expect(graph.edges[0].kind == .tag)
        #expect(graph.edges[0].weight == nil)
        #expect(graph.edges[1].kind == .similar)
        #expect(graph.edges[1].weight == 0.83)
    }

    @Test("an unknown node kind drops that node only")
    func unknownNodeKind() throws {
        let json = """
        {"generatedAt":"2026-11-11T10:00:00Z","truncated":false,"vaults":[],
         "nodes":[{"id":"a","kind":"hologram","label":"x","weight":1},
                  {"id":"tag:go","kind":"tag","label":"go","weight":1}],
         "edges":[]}
        """
        let graph = try decode(BrainGraphResponse.self, json)
        #expect(graph.nodes.map(\.id) == ["tag:go"])
    }

    @Test("an unknown edge kind drops that edge only, dangling endpoints are kept")
    func unknownEdgeKind() throws {
        let json = """
        {"generatedAt":"2026-11-11T10:00:00Z","truncated":false,"vaults":[],"nodes":[],
         "edges":[{"from":"a","to":"b","kind":"teleport"},
                  {"from":"missing-1","to":"missing-2","kind":"link"}]}
        """
        let graph = try decode(BrainGraphResponse.self, json)
        #expect(graph.edges == [BrainGraphEdgeDTO(from: "missing-1", to: "missing-2", kind: .link)])
    }

    @Test("a malformed element is dropped, the rest survives")
    func malformedElement() throws {
        let json = """
        {"generatedAt":"2026-11-11T10:00:00Z","truncated":false,"vaults":[],
         "nodes":[{"id":"a","kind":"tag"},{"id":"tag:go","kind":"tag","label":"go","weight":1}],
         "edges":[]}
        """
        #expect(try decode(BrainGraphResponse.self, json).nodes.count == 1)
    }

    @Test("a response without truncated decodes to false")
    func missingTruncated() throws {
        let json = #"{"generatedAt":"2026-11-11T10:00:00Z","vaults":[],"nodes":[],"edges":[]}"#
        #expect(try decode(BrainGraphResponse.self, json).truncated == false)
    }

    @Test("a node weight written as 3.0 decodes to 3")
    func fractionalZeroWeight() throws {
        let node = try decode(BrainGraphNodeDTO.self, #"{"id":"tag:go","kind":"tag","label":"go","weight":3.0}"#)
        #expect(node.weight == 3)
    }

    @Test("a node weight with a real fraction is rejected")
    func fractionalWeightFails() {
        #expect(throws: DecodingError.self) {
            try decode(BrainGraphNodeDTO.self, #"{"id":"tag:go","kind":"tag","label":"go","weight":3.5}"#)
        }
    }

    @Test("a node survives an encode and decode round trip")
    func roundTrip() throws {
        let node = BrainGraphNodeDTO(
            id: "tag:go", kind: .tag, label: "go", vaultID: nil, spaceID: nil,
            weight: 2, createdAt: nil, pos: GraphPosition3D(x: 1, y: 2, z: 3), refs: nil
        )
        let data = try JSONEncoder().encode(node)
        #expect(try JSONDecoder().decode(BrainGraphNodeDTO.self, from: data) == node)
    }

    @Test("every public type is Sendable")
    func sendable() {
        func requireSendable<T: Sendable>(_: T.Type) {}
        requireSendable(BrainNodeKindDTO.self)
        requireSendable(BrainLinkKindDTO.self)
        requireSendable(BrainGraphVaultDTO.self)
        requireSendable(BrainGraphRefDTO.self)
        requireSendable(BrainGraphNodeDTO.self)
        requireSendable(BrainGraphEdgeDTO.self)
        requireSendable(BrainGraphResponse.self)
    }
}
