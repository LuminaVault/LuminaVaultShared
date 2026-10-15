import Foundation
import Testing
@testable import LuminaVaultShared

struct MemoryKindDTOTests {
    private static let base = #""id":"2F1B6D3E-5A4C-4F7E-9E1D-1C2B3A4D5E6F","content":"Prefers Python.","tags":[],"reviewState":"auto""#

    @Test("a memory from a server without kinds decodes as unclassified")
    func absentKindIsNil() throws {
        let dto = try JSONDecoder().decode(MemoryDTO.self, from: Data("{\(Self.base)}".utf8))
        #expect(dto.kind == nil)
    }

    @Test("a known kind decodes")
    func knownKind() throws {
        let dto = try JSONDecoder().decode(MemoryDTO.self, from: Data(#"{\#(Self.base),"kind":"preference"}"#.utf8))
        #expect(dto.kind == .preference)
    }

    @Test("an unknown kind from a newer server does not break decoding")
    func unknownKindIsNil() throws {
        let dto = try JSONDecoder().decode(MemoryDTO.self, from: Data(#"{\#(Self.base),"kind":"hunch"}"#.utf8))
        #expect(dto.kind == nil)
        #expect(dto.content == "Prefers Python.")
    }

    @Test("kind round-trips and keeps its wire values")
    func roundTrip() throws {
        #expect(MemoryKindDTO.allCases.map(\.rawValue) == ["preference", "decision", "fact", "note"])
        let original = MemoryDTO(id: UUID(), content: "We ship Tuesdays.", tags: ["ops"], kind: .decision)
        let decoded = try JSONDecoder().decode(MemoryDTO.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }

    @Test("upsert and patch send kind only when set")
    func requestsOmitNilKind() throws {
        let upsert = try JSONSerialization
            .jsonObject(with: JSONEncoder().encode(MemoryUpsertRequest(content: "x"))) as? [String: Any]
        #expect(upsert?["kind"] == nil)
        let patch = try JSONSerialization
            .jsonObject(with: JSONEncoder().encode(MemoryPatchRequest(kind: .fact))) as? [String: Any]
        #expect(patch?["kind"] as? String == "fact")
    }

    @Test("an unknown source kind reads as legacy instead of failing")
    func unknownSourceKindIsLegacy() throws {
        let decoded = try JSONDecoder().decode([MemorySourceKindDTO].self, from: Data(#"["chat","agent"]"#.utf8))
        #expect(decoded == [.chat, .legacy])
    }
}

struct MemorySpaceAssignmentTests {
    private func json(_ request: MemoryPatchRequest) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try String(decoding: encoder.encode(request), as: UTF8.self)
    }

    @Test("a move, an unfile and no change are three different bodies")
    func encodesThreeStates() throws {
        let id = try #require(UUID(uuidString: "2F1B6D3E-5A4C-4F7E-9E1D-1C2B3A4D5E6F"))
        #expect(try json(MemoryPatchRequest(spaceId: .space(id))) ==
            #"{"spaceId":"2F1B6D3E-5A4C-4F7E-9E1D-1C2B3A4D5E6F"}"#)
        #expect(try json(MemoryPatchRequest(spaceId: .unfiled)) == #"{"spaceId":null}"#)
        #expect(try json(MemoryPatchRequest(content: "x")) == #"{"content":"x"}"#)
    }

    @Test("decoding keeps null apart from absent")
    func decodesThreeStates() throws {
        let decoder = JSONDecoder()
        let id = UUID()
        #expect(try decoder.decode(MemoryPatchRequest.self, from: Data(#"{"spaceId":"\#(id)"}"#.utf8))
            .spaceId == .space(id))
        #expect(try decoder.decode(MemoryPatchRequest.self, from: Data(#"{"spaceId":null}"#.utf8)).spaceId == .unfiled)
        #expect(try decoder.decode(MemoryPatchRequest.self, from: Data(#"{"tags":[]}"#.utf8)).spaceId == nil)
    }

    @Test("a memory carries its Space")
    func memoryCarriesSpace() throws {
        let space = UUID()
        let original = MemoryDTO(id: UUID(), content: "x", tags: [], spaceId: space)
        let decoded = try JSONDecoder().decode(MemoryDTO.self, from: JSONEncoder().encode(original))
        #expect(decoded.spaceId == space)
    }
}
