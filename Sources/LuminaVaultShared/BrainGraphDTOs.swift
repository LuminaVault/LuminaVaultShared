import Foundation

// Wire types for `GET /v1/brain/graph`: one knowledge graph of notes and
// memories across all of a user's vaults, with hub nodes for tags, authors,
// mentioned entities and Spaces.

public enum BrainNodeKindDTO: String, Codable, Sendable {
    case note, memory, tag, author, entity, space
}

public enum BrainLinkKindDTO: String, Codable, Sendable, CaseIterable {
    case link, source, tag, author, entity, space, similar
}

public struct BrainGraphVaultDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let personal: Bool

    public init(id: UUID, name: String, personal: Bool) {
        self.id = id; self.name = name; self.personal = personal
    }

    /// `personal` defaults to false when the key is missing.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        personal = try c.decodeIfPresent(Bool.self, forKey: .personal) ?? false
    }
}

/// Entity hubs only: the `knowledge_nodes` id of the entity in one vault.
public struct BrainGraphRefDTO: Codable, Sendable, Equatable {
    public let vaultID: UUID
    public let id: UUID

    public init(vaultID: UUID, id: UUID) {
        self.vaultID = vaultID; self.id = id
    }
}

public struct BrainGraphNodeDTO: Codable, Sendable, Identifiable, Equatable {
    /// A uuid string for notes and memories, a prefixed id for hubs
    /// (`tag:go`, `author:user:<UUID>`, `entity:acme`, `space:<UUID>`).
    /// Never normalised and never parsed as a `UUID`.
    public let id: String
    public let kind: BrainNodeKindDTO
    public let label: String
    /// Set on notes, memories and Space hubs.
    public let vaultID: UUID?
    public let spaceID: UUID?
    /// The node's edge count in the returned graph.
    public let weight: Int
    public let createdAt: Date?
    /// Precomputed layout coordinate; `nil` means the client lays the node out.
    public let pos: GraphPosition3D?
    /// Entity hubs only.
    public let refs: [BrainGraphRefDTO]?

    public init(
        id: String,
        kind: BrainNodeKindDTO,
        label: String,
        vaultID: UUID? = nil,
        spaceID: UUID? = nil,
        weight: Int,
        createdAt: Date? = nil,
        pos: GraphPosition3D? = nil,
        refs: [BrainGraphRefDTO]? = nil
    ) {
        self.id = id; self.kind = kind; self.label = label
        self.vaultID = vaultID; self.spaceID = spaceID; self.weight = weight
        self.createdAt = createdAt; self.pos = pos; self.refs = refs
    }

    /// Tolerates `weight` written as a JSON number with a zero fraction (`3.0`).
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = try c.decode(BrainNodeKindDTO.self, forKey: .kind)
        label = try c.decode(String.self, forKey: .label)
        vaultID = try c.decodeIfPresent(UUID.self, forKey: .vaultID)
        spaceID = try c.decodeIfPresent(UUID.self, forKey: .spaceID)
        if let whole = try? c.decode(Int.self, forKey: .weight) {
            weight = whole
        } else {
            let number = try c.decode(Double.self, forKey: .weight)
            guard number.rounded() == number, let whole = Int(exactly: number) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .weight, in: c, debugDescription: "weight must be a whole number"
                )
            }
            weight = whole
        }
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        pos = try c.decodeIfPresent(GraphPosition3D.self, forKey: .pos)
        refs = try c.decodeIfPresent([BrainGraphRefDTO].self, forKey: .refs)
    }
}

public struct BrainGraphEdgeDTO: Codable, Sendable, Equatable {
    public let from: String
    public let to: String
    public let kind: BrainLinkKindDTO
    /// Set only on `similar` edges: the cosine similarity.
    public let weight: Double?

    public init(from: String, to: String, kind: BrainLinkKindDTO, weight: Double? = nil) {
        self.from = from; self.to = to; self.kind = kind; self.weight = weight
    }
}

public struct BrainGraphResponse: Codable, Sendable {
    public let generatedAt: Date
    public let truncated: Bool
    public let vaults: [BrainGraphVaultDTO]
    public let nodes: [BrainGraphNodeDTO]
    public let edges: [BrainGraphEdgeDTO]

    public init(
        generatedAt: Date,
        truncated: Bool = false,
        vaults: [BrainGraphVaultDTO],
        nodes: [BrainGraphNodeDTO],
        edges: [BrainGraphEdgeDTO]
    ) {
        self.generatedAt = generatedAt; self.truncated = truncated
        self.vaults = vaults; self.nodes = nodes; self.edges = edges
    }

    /// Fails softly: `nodes` and `edges` decode element by element, so a node
    /// or edge with an unknown kind (or any other defect) is dropped and the
    /// rest of the graph survives. Edges whose endpoints are not in `nodes`
    /// are kept; the client filters them. Missing `truncated` is false.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try c.decode(Date.self, forKey: .generatedAt)
        truncated = try c.decodeIfPresent(Bool.self, forKey: .truncated) ?? false
        vaults = try c.decodeIfPresent([BrainGraphVaultDTO].self, forKey: .vaults) ?? []
        nodes = try (c.decodeIfPresent([Lossy<BrainGraphNodeDTO>].self, forKey: .nodes) ?? []).compactMap(\.value)
        edges = try (c.decodeIfPresent([Lossy<BrainGraphEdgeDTO>].self, forKey: .edges) ?? []).compactMap(\.value)
    }

    /// Decodes one array element, yielding `nil` instead of throwing.
    private struct Lossy<Element: Decodable>: Decodable {
        let value: Element?
        init(from decoder: any Decoder) throws {
            value = try? Element(from: decoder)
        }
    }
}
