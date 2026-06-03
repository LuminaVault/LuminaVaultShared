import Foundation

// ═══════════════════════════════════════════════════════════════════════════
// Shared API types between LuminaVaultServer (Hummingbird) and iOS client.
// NO Hummingbird imports here — all types are pure Foundation + Codable.
// ResponseEncodable conformances live on the server side.
//
// All types get explicit `public init` so cross-module callers can construct
// them (Swift does not synthesise a public memberwise init for a `public struct`).
// ═══════════════════════════════════════════════════════════════════════════

// ─── Auth Domain ─────────────────────────────────────────────────────────

public struct RegisterRequest: Codable, Sendable {
    public let email: String
    public let username: String
    public let password: String
    public init(email: String, username: String, password: String) {
        self.email = email; self.username = username; self.password = password
    }
}

public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let mfaCode: String?
    public init(email: String, password: String, mfaCode: String?) {
        self.email = email; self.password = password; self.mfaCode = mfaCode
    }
}

public struct RefreshRequest: Codable, Sendable {
    public let refreshToken: String
    public init(refreshToken: String) { self.refreshToken = refreshToken }
}

public struct AuthResponse: Codable {
    public let userId: UUID
    public let email: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let mfaRequired: Bool?
    public let mfaChallengeId: UUID?
    /// True once the tenant has run `POST /v1/vault/create`. Clients gate the
    /// "Create My Vault" screen on this value being false.
    public let vaultInitialized: Bool
    public init(userId: UUID, email: String, accessToken: String, refreshToken: String, expiresIn: Int, mfaRequired: Bool?, mfaChallengeId: UUID?, vaultInitialized: Bool = false) {
        self.userId = userId; self.email = email; self.accessToken = accessToken
        self.refreshToken = refreshToken; self.expiresIn = expiresIn
        self.mfaRequired = mfaRequired; self.mfaChallengeId = mfaChallengeId
        self.vaultInitialized = vaultInitialized
    }
}

public struct MFAVerifyRequest: Codable, Sendable {
    public let challengeId: UUID
    public let code: String
    public init(challengeId: UUID, code: String) {
        self.challengeId = challengeId; self.code = code
    }
}

public struct MFAResendRequest: Codable, Sendable {
    public let email: String
    public init(email: String) { self.email = email }
}

public struct OAuthExchangeRequest: Codable, Sendable {
    public let idToken: String
    public init(idToken: String) { self.idToken = idToken }
}

/// HER-144: X (Twitter) OAuth 2.0 PKCE returns an access_token, not an
/// id_token, so its `/v1/auth/oauth/x/exchange` route decodes this body
/// shape instead of `OAuthExchangeRequest`. Mirrors the
/// `OAuthAccessTokenRequest` schema in `openapi.yaml`.
public struct OAuthAccessTokenRequest: Codable, Sendable {
    public let accessToken: String
    public init(accessToken: String) { self.accessToken = accessToken }
}

public struct ForgotPasswordRequest: Codable, Sendable {
    public let email: String
    public init(email: String) { self.email = email }
}

public struct ResetPasswordRequest: Codable, Sendable {
    public let email: String
    public let code: String
    public let newPassword: String
    public init(email: String, code: String, newPassword: String) {
        self.email = email; self.code = code; self.newPassword = newPassword
    }
}

public struct SendVerificationRequest: Codable, Sendable {
    public let email: String
    public init(email: String) { self.email = email }
}

public struct ConfirmEmailRequest: Codable, Sendable {
    public let email: String
    public let code: String
    public init(email: String, code: String) {
        self.email = email; self.code = code
    }
}

public struct MeResponse: Codable {
    public let userId: UUID
    public let email: String
    public let username: String
    public let isVerified: Bool
    public let privacyNoCNOrigin: Bool
    public let contextRouting: Bool
    /// HER-274 — gates the auto-save-link post-processor on the chat
    /// stream. Default `true`. Toggle via `PUT /v1/me/privacy`.
    public let autoSaveLinks: Bool
    public init(
        userId: UUID,
        email: String,
        username: String,
        isVerified: Bool,
        privacyNoCNOrigin: Bool,
        contextRouting: Bool,
        autoSaveLinks: Bool = true
    ) {
        self.userId = userId; self.email = email; self.username = username
        self.isVerified = isVerified; self.privacyNoCNOrigin = privacyNoCNOrigin
        self.contextRouting = contextRouting
        self.autoSaveLinks = autoSaveLinks
    }
}

public struct UpdatePrivacyRequest: Codable {
    public let privacyNoCNOrigin: Bool?
    public let contextRouting: Bool?
    /// HER-274 — opt out of the chat auto-save-link behavior. When set
    /// to `false`, URLs mentioned in user prompts or assistant replies
    /// are no longer captured to the vault, and no `link_saved` SSE
    /// event is emitted on the stream.
    public let autoSaveLinks: Bool?
    public init(privacyNoCNOrigin: Bool?, contextRouting: Bool?, autoSaveLinks: Bool? = nil) {
        self.privacyNoCNOrigin = privacyNoCNOrigin
        self.contextRouting = contextRouting
        self.autoSaveLinks = autoSaveLinks
    }
}

// ─── Phone Auth ──────────────────────────────────────────────────────────

public struct PhoneStartRequest: Codable, Sendable {
    public let phone: String
    public init(phone: String) { self.phone = phone }
}

public struct PhoneStartResponse: Codable {
    public let challengeId: UUID
    public let expiresAt: Date
    public init(challengeId: UUID, expiresAt: Date) {
        self.challengeId = challengeId; self.expiresAt = expiresAt
    }
}

public struct PhoneVerifyRequest: Codable, Sendable {
    public let phone: String
    public let code: String
    public init(phone: String, code: String) {
        self.phone = phone; self.code = code
    }
}

// ─── Email Magic Link ────────────────────────────────────────────────────

public struct EmailMagicStartRequest: Codable, Sendable {
    public let email: String
    public init(email: String) { self.email = email }
}

public struct EmailMagicStartResponse: Codable {
    public let challengeId: UUID
    public let expiresAt: Date
    public init(challengeId: UUID, expiresAt: Date) {
        self.challengeId = challengeId; self.expiresAt = expiresAt
    }
}

public struct EmailMagicVerifyRequest: Codable, Sendable {
    public let email: String
    public let code: String
    public init(email: String, code: String) {
        self.email = email; self.code = code
    }
}

// ─── SOUL ────────────────────────────────────────────────────────────────

public struct SoulResponse: Codable {
    public let content: String
    public let sizeBytes: Int
    public init(content: String, sizeBytes: Int) {
        self.content = content; self.sizeBytes = sizeBytes
    }
}

// ─── LLM / Chat ─────────────────────────────────────────────────────────

public enum AnyJSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case object([String: AnyJSONValue])
    case array([AnyJSONValue])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .string(v)
        } else if let v = try? c.decode(Double.self) { self = .number(v)
        } else if let v = try? c.decode(Bool.self) { self = .bool(v)
        } else if let v = try? c.decode([String: AnyJSONValue].self) { self = .object(v)
        } else if let v = try? c.decode([AnyJSONValue].self) { self = .array(v)
        } else if c.decodeNil() { self = .null
        } else { self = .string("") }
    }
}

public typealias AnyCodableDict = [String: AnyJSONValue]

public struct EmptyResponse: Codable, Sendable {
    public init() {}
}

public struct ChatMessage: Codable, Sendable {
    public let role: String
    public let content: String
    public let tool_calls: [ChatToolCall]?
    enum CodingKeys: String, CodingKey { case role, content, tool_calls }
    public init(role: String, content: String, tool_calls: [ChatToolCall]? = nil) {
        self.role = role; self.content = content; self.tool_calls = tool_calls
    }
}

public struct ChatToolCall: Codable, Sendable {
    public let id: String
    public let type: String
    public let function: ChatToolCallFunction
    public init(id: String, type: String, function: ChatToolCallFunction) {
        self.id = id; self.type = type; self.function = function
    }
}

public struct ChatToolCallFunction: Codable, Sendable {
    public let name: String
    public let arguments: String
    public init(name: String, arguments: String) {
        self.name = name; self.arguments = arguments
    }
}

public struct ChatTool: Codable, Sendable {
    public let type: String
    public let function: ChatToolDefinition
    public init(type: String, function: ChatToolDefinition) {
        self.type = type; self.function = function
    }
}

public struct ChatToolDefinition: Codable, Sendable {
    public let name: String
    public let description: String?
    public let parameters: AnyCodableDict?
    public init(name: String, description: String? = nil, parameters: AnyCodableDict? = nil) {
        self.name = name; self.description = description; self.parameters = parameters
    }
}

public struct ChatRequest: Codable, Sendable {
    public let messages: [ChatMessage]
    public let model: String?
    public let temperature: Double?
    public let stream: Bool
    public let tools: [ChatTool]?
    public let tool_choice: AnyJSONValue?
    /// HER-183 — opt-in conversation continuity ID forwarded as
    /// `X-Hermes-Session-Id` to the upstream Hermes gateway.
    public let sessionID: String?
    enum CodingKeys: String, CodingKey {
        case messages, model, temperature, stream, tools, tool_choice
        case sessionID = "session_id"
    }

    public init(
        messages: [ChatMessage],
        model: String? = nil,
        temperature: Double? = nil,
        stream: Bool = false,
        tools: [ChatTool]? = nil,
        tool_choice: AnyJSONValue? = nil,
        sessionID: String? = nil
    ) {
        self.messages = messages
        self.model = model
        self.temperature = temperature
        self.stream = stream
        self.tools = tools
        self.tool_choice = tool_choice
        self.sessionID = sessionID
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.messages = try c.decode([ChatMessage].self, forKey: .messages)
        self.model = try c.decodeIfPresent(String.self, forKey: .model)
        self.temperature = try c.decodeIfPresent(Double.self, forKey: .temperature)
        self.stream = try c.decodeIfPresent(Bool.self, forKey: .stream) ?? false
        self.tools = try c.decodeIfPresent([ChatTool].self, forKey: .tools)
        self.tool_choice = try c.decodeIfPresent(AnyJSONValue.self, forKey: .tool_choice)
        self.sessionID = try c.decodeIfPresent(String.self, forKey: .sessionID)
    }
}

public struct ChatResponse: Codable, Sendable {
    public let id: String
    public let model: String
    public let message: ChatMessage
    public let raw: HermesUpstreamResponse
    public init(id: String, model: String, message: ChatMessage, raw: HermesUpstreamResponse) {
        self.id = id; self.model = model; self.message = message; self.raw = raw
    }
}

public struct HermesUpstreamChoice: Codable, Sendable {
    public let index: Int?
    public let message: ChatMessage
    public let finishReason: String?
    enum CodingKeys: String, CodingKey { case index, message; case finishReason = "finish_reason" }
    public init(index: Int?, message: ChatMessage, finishReason: String? = nil) {
        self.index = index; self.message = message; self.finishReason = finishReason
    }
}

public struct HermesUpstreamUsage: Codable, Sendable {
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"; case completionTokens = "completion_tokens"; case totalTokens = "total_tokens"
    }
    public init(promptTokens: Int? = nil, completionTokens: Int? = nil, totalTokens: Int? = nil) {
        self.promptTokens = promptTokens; self.completionTokens = completionTokens
        self.totalTokens = totalTokens
    }
}

public struct HermesUpstreamResponse: Codable, Sendable {
    public let id: String
    public let object: String?
    public let created: Int?
    public let model: String
    public let choices: [HermesUpstreamChoice]
    public let usage: HermesUpstreamUsage?
    public init(id: String, object: String? = nil, created: Int? = nil, model: String, choices: [HermesUpstreamChoice], usage: HermesUpstreamUsage? = nil) {
        self.id = id; self.object = object; self.created = created; self.model = model
        self.choices = choices; self.usage = usage
    }
}

// ─── Memory ──────────────────────────────────────────────────────────────

public struct MemoryUpsertResponse: Codable, Sendable {
    public let memoryId: UUID
    public let content: String
    public let summary: String
    public init(memoryId: UUID, content: String, summary: String) {
        self.memoryId = memoryId; self.content = content; self.summary = summary
    }
}

public struct MemorySearchRequest: Codable, Sendable {
    public let query: String
    public let limit: Int?
    public init(query: String, limit: Int? = nil) {
        self.query = query; self.limit = limit
    }
}

public struct MemorySearchHitDTO: Codable, Sendable {
    public let id: UUID
    public let content: String
    public let distance: Float
    public let createdAt: Date?
    public init(id: UUID, content: String, distance: Float, createdAt: Date? = nil) {
        self.id = id; self.content = content; self.distance = distance
        self.createdAt = createdAt
    }
}

public struct MemorySearchResponse: Codable, Sendable {
    public let hits: [MemorySearchHitDTO]
    public let summary: String
    public init(hits: [MemorySearchHitDTO], summary: String) {
        self.hits = hits; self.summary = summary
    }
}

public struct MemoryUpsertRequest: Codable, Sendable {
    public let content: String
    /// HER-207 — optional geo anchor. All four are nil for memories captured
    /// without location; set together when the client supplies a MapKit
    /// reverse-geocoded coordinate. `accuracyM` is the radius of the GPS fix
    /// in metres; `placeName` is the human label.
    public let lat: Double?
    public let lng: Double?
    public let accuracyM: Double?
    public let placeName: String?
    public init(
        content: String,
        lat: Double? = nil,
        lng: Double? = nil,
        accuracyM: Double? = nil,
        placeName: String? = nil
    ) {
        self.content = content
        self.lat = lat
        self.lng = lng
        self.accuracyM = accuracyM
        self.placeName = placeName
    }
}

public struct MemoryDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let content: String
    public let tags: [String]
    public let createdAt: Date?
    /// HER-207 geo anchor (see `MemoryUpsertRequest` for field semantics).
    public let lat: Double?
    public let lng: Double?
    public let accuracyM: Double?
    public let placeName: String?
    /// HER-290 — moderation state.
    /// * `"auto"` — created outside kb-compile (manual upsert, backfill). Visible everywhere.
    /// * `"pending"` — produced by a kb-compile run, awaiting user approve/reject.
    /// * `"approved"` — user kept it.
    /// * `"rejected"` — user dismissed it; suppressed from list defaults and added to the
    ///   kb-compile reject list so future runs skip the same source+content_hash pair.
    public let reviewState: String
    public init(
        id: UUID,
        content: String,
        tags: [String],
        createdAt: Date? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        accuracyM: Double? = nil,
        placeName: String? = nil,
        reviewState: String = "auto"
    ) {
        self.id = id
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.lat = lat
        self.lng = lng
        self.accuracyM = accuracyM
        self.placeName = placeName
        self.reviewState = reviewState
    }
}

/// HER-290 — string constants for the four `MemoryDTO.reviewState` values.
/// Use these instead of raw string literals at call sites.
public enum MemoryReviewState {
    public static let auto = "auto"
    public static let pending = "pending"
    public static let approved = "approved"
    public static let rejected = "rejected"
    public static let all: [String] = [auto, pending, approved, rejected]
}

public struct MemoryListResponse: Codable, Sendable {
    public let memories: [MemoryDTO]
    public let limit: Int
    public let offset: Int
    public init(memories: [MemoryDTO], limit: Int, offset: Int) {
        self.memories = memories; self.limit = limit; self.offset = offset
    }
}

public struct MemoryPatchRequest: Codable, Sendable {
    public let content: String?
    public let tags: [String]?
    /// HER-290 — only `pending → approved` and `pending → rejected` are accepted.
    /// Other transitions return 422 from the server.
    public let reviewState: String?
    public init(content: String? = nil, tags: [String]? = nil, reviewState: String? = nil) {
        self.content = content
        self.tags = tags
        self.reviewState = reviewState
    }
}

public struct MemoryLineageSourceDTO: Codable, Sendable {
    public let vaultFileId: UUID
    public let path: String
    public let createdAt: Date?
    public init(vaultFileId: UUID, path: String, createdAt: Date? = nil) {
        self.vaultFileId = vaultFileId; self.path = path; self.createdAt = createdAt
    }
}

public struct MemoryLineageResponse: Codable, Sendable {
    public let memoryId: UUID
    public let source: MemoryLineageSourceDTO?
    public let trace: String
    public init(memoryId: UUID, source: MemoryLineageSourceDTO?, trace: String) {
        self.memoryId = memoryId; self.source = source; self.trace = trace
    }
}

// ─── Memory Graph (HER-235) ──────────────────────────────────────────────
//
// Read-only derived graph view of a tenant's second brain. Nodes are
// memories (recall layer) and/or wiki pages (the compiled raw/ → wiki/
// notes). Edges are derived on read from: explicit [[wiki-links]], shared
// tags, shared Space, pgvector cosine similarity, and temporal proximity.
// No edges are persisted server-side in v1.

/// Which backing store a graph node's `id` belongs to. Lets one graph mix
/// memory nodes, source (`vault_files`) nodes, and synthetic Space hub nodes.
/// Decodes to `.memory` for pre-enrich payloads that omit the field.
///
/// - `space` is a synthetic hub node (id = the Space's UUID, title = the Space
///   name) that member nodes connect to via `.space` star edges, giving each
///   Space visual cohesion in the graph. (`wikiPage` is the raw source layer.)
public enum GraphNodeKindDTO: String, Codable, Sendable {
    case memory
    case wikiPage
    case space
}

public struct MemoryGraphNodeDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let tags: [String]
    public let createdAt: Date
    public let score: Double
    /// Graph-enrich: store the id belongs to. Drives node styling +
    /// tap-target routing (wiki page → full markdown page, memory → sheet).
    public let kind: GraphNodeKindDTO
    /// Optional Space the node is filed under; powers `.space` edges and
    /// space-tinted clustering. `nil` for unfiled nodes.
    public let spaceID: UUID?

    public init(
        id: UUID,
        title: String,
        tags: [String],
        createdAt: Date,
        score: Double,
        kind: GraphNodeKindDTO = .memory,
        spaceID: UUID? = nil
    ) {
        self.id = id; self.title = title; self.tags = tags
        self.createdAt = createdAt; self.score = score
        self.kind = kind; self.spaceID = spaceID
    }

    // Custom decode so a newer client stays robust against an older server
    // that predates `kind`/`spaceID`: missing keys fall back to a memory
    // node with no Space rather than failing the whole graph decode.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        score = try c.decode(Double.self, forKey: .score)
        kind = try c.decodeIfPresent(GraphNodeKindDTO.self, forKey: .kind) ?? .memory
        spaceID = try c.decodeIfPresent(UUID.self, forKey: .spaceID)
    }
}

public enum MemoryEdgeKindDTO: String, Codable, Sendable {
    /// Explicit `[[wiki-link]]` between notes — the strongest, human-authored
    /// signal. Wins on dedupe in the server merge.
    case wikilink
    case tag
    /// Both endpoints filed under the same Space.
    case space
    case semantic
    /// Captured close together in time.
    case temporal
}

public struct MemoryGraphEdgeDTO: Codable, Sendable {
    public let from: UUID
    public let to: UUID
    public let kind: MemoryEdgeKindDTO
    /// Populated when `kind == .tag`: the shared tag that produced the edge.
    public let tag: String?
    /// Populated when `kind == .semantic`: cosine similarity in `[0, 1]`.
    public let similarity: Double?
    /// Normalised edge strength in `[0, 1]` used for visual alpha/thickness.
    public let weight: Double
    public init(from: UUID, to: UUID, kind: MemoryEdgeKindDTO, tag: String?, similarity: Double?, weight: Double) {
        self.from = from; self.to = to; self.kind = kind
        self.tag = tag; self.similarity = similarity; self.weight = weight
    }
}

public struct MemoryGraphResponse: Codable, Sendable {
    public let nodes: [MemoryGraphNodeDTO]
    public let edges: [MemoryGraphEdgeDTO]
    public let generatedAt: Date
    public init(nodes: [MemoryGraphNodeDTO], edges: [MemoryGraphEdgeDTO], generatedAt: Date) {
        self.nodes = nodes; self.edges = edges; self.generatedAt = generatedAt
    }
}

// ─── Memo ────────────────────────────────────────────────────────────────

/// Request body for `POST /v1/memos`. The server runs the memo-generator
/// agent over the caller's vault, optionally persisting the result as a
/// markdown file under `memos/` when `save == true`.
public struct MemoRequest: Codable, Sendable {
    public let topic: String
    public let hint: String?
    public let save: Bool?
    public init(topic: String, hint: String? = nil, save: Bool? = nil) {
        self.topic = topic; self.hint = hint; self.save = save
    }
}

public struct MemoResponse: Codable, Sendable {
    public let memo: String
    public let path: String?
    public let sourceMemoryIds: [UUID]
    public let summary: String
    public init(memo: String, path: String? = nil, sourceMemoryIds: [UUID], summary: String) {
        self.memo = memo; self.path = path; self.sourceMemoryIds = sourceMemoryIds
        self.summary = summary
    }
}

/// Item shape for "Lumina's Notebook" memo list view.
public struct MemoSummaryDTO: Codable, Sendable {
    public let id: UUID
    public let title: String
    public let path: String
    public let createdAt: Date
    public let summary: String?
    public init(id: UUID, title: String, path: String, createdAt: Date, summary: String? = nil) {
        self.id = id; self.title = title; self.path = path
        self.createdAt = createdAt; self.summary = summary
    }
}

/// Response body for `GET /v1/memos`. Wraps the array so pagination fields
/// can be added later without breaking the wire shape.
public struct MemoListResponse: Codable, Sendable {
    public let memos: [MemoSummaryDTO]
    public init(memos: [MemoSummaryDTO]) { self.memos = memos }
}

// ─── Query ───────────────────────────────────────────────────────────────

/// Request body for `POST /v1/query` — natural-language semantic query
/// over the caller's vault memories.
public struct QueryRequest: Codable, Sendable {
    public let query: String
    public let limit: Int?
    /// HER-183 — optional Hermes Session-Id for conversation continuity
    /// on the streamed query path.
    public let sessionID: String?

    enum CodingKeys: String, CodingKey {
        case query, limit
        case sessionID = "session_id"
    }

    public init(query: String, limit: Int? = nil, sessionID: String? = nil) {
        self.query = query
        self.limit = limit
        self.sessionID = sessionID
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.query = try c.decode(String.self, forKey: .query)
        self.limit = try c.decodeIfPresent(Int.self, forKey: .limit)
        self.sessionID = try c.decodeIfPresent(String.self, forKey: .sessionID)
    }
}

public struct QueryHitDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let content: String
    public let distance: Float
    public let createdAt: Date?
    public init(id: UUID, content: String, distance: Float, createdAt: Date? = nil) {
        self.id = id; self.content = content; self.distance = distance
        self.createdAt = createdAt
    }
}

public struct QueryResponse: Codable, Sendable {
    public let summary: String
    public let hits: [QueryHitDTO]
    /// Server-generated follow-up prompts derived from the response context.
    /// Optional for backward compatibility with pre-HER-37 streaming clients.
    public let followUps: [String]?
    public init(summary: String, hits: [QueryHitDTO], followUps: [String]? = nil) {
        self.summary = summary; self.hits = hits; self.followUps = followUps
    }
}

/// Discriminated-union event emitted on `POST /v1/query/stream` and
/// `POST /v1/conversations/:id/messages/stream` Server-Sent-Event streams.
///
/// Wire shape: each SSE `data:` line carries a JSON object of form
/// `{ "type": "<case>", "payload": <case-specific> }`. Cases without a
/// payload (`done`) omit the `payload` key.
public enum QueryStreamEvent: Codable, Sendable, Equatable {
    /// Retrieved memory hit. Emitted up-front, once per top-N source.
    case source(QueryHitDTO)
    /// Incremental token delta from the LLM. Concatenate in order.
    case token(String)
    /// Final summary string (sent after all tokens). Optional — clients may
    /// reconstruct from concatenated tokens instead.
    case summary(String)
    /// Server-generated follow-up chips. Emitted after `done` or just before.
    case followUps([String])
    /// Stream terminator.
    case done
    /// Stream-level error. Client should surface and abort.
    case error(String)
    /// HER-252 — emitted when `RoutedLLMTransport` failed over from one
    /// provider to another (e.g. xAI credit exhaustion → Qwen2.5 via
    /// OpenRouter). The payload carries the original + fallback route
    /// plus a localized `userMessage` the client can surface verbatim.
    /// Sent before subsequent `.token` events so the client banner
    /// renders in time.
    case fallback(ProviderFallbackNoticeDTO)
    /// HER-274 — emitted once per URL the server auto-captured to the
    /// user's vault while processing this chat turn. Sent AFTER tokens
    /// have streamed, BEFORE the `.done` terminator. Multiple events
    /// per turn possible when the user pastes several links.
    case linkSaved(LinkSavedDTO)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum EventType: String, Codable {
        case source, token, summary
        case followUps = "follow_ups"
        case done, error, fallback
        case linkSaved = "link_saved"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(EventType.self, forKey: .type)
        switch type {
        case .source: self = .source(try c.decode(QueryHitDTO.self, forKey: .payload))
        case .token: self = .token(try c.decode(String.self, forKey: .payload))
        case .summary: self = .summary(try c.decode(String.self, forKey: .payload))
        case .followUps: self = .followUps(try c.decode([String].self, forKey: .payload))
        case .done: self = .done
        case .error: self = .error(try c.decode(String.self, forKey: .payload))
        case .fallback: self = .fallback(try c.decode(ProviderFallbackNoticeDTO.self, forKey: .payload))
        case .linkSaved: self = .linkSaved(try c.decode(LinkSavedDTO.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .source(let h):
            try c.encode(EventType.source, forKey: .type)
            try c.encode(h, forKey: .payload)
        case .token(let s):
            try c.encode(EventType.token, forKey: .type)
            try c.encode(s, forKey: .payload)
        case .summary(let s):
            try c.encode(EventType.summary, forKey: .type)
            try c.encode(s, forKey: .payload)
        case .followUps(let arr):
            try c.encode(EventType.followUps, forKey: .type)
            try c.encode(arr, forKey: .payload)
        case .done:
            try c.encode(EventType.done, forKey: .type)
        case .error(let s):
            try c.encode(EventType.error, forKey: .type)
            try c.encode(s, forKey: .payload)
        case .fallback(let notice):
            try c.encode(EventType.fallback, forKey: .type)
            try c.encode(notice, forKey: .payload)
        case .linkSaved(let payload):
            try c.encode(EventType.linkSaved, forKey: .type)
            try c.encode(payload, forKey: .payload)
        }
    }
}

/// HER-274 — payload of the `link_saved` SSE event. Identifies a URL
/// the server auto-captured to the vault while processing a chat turn,
/// so the iOS client can render a toast and deep-link to the file.
public struct LinkSavedDTO: Codable, Sendable, Equatable {
    public let url: String
    /// Tenant-relative vault path (e.g. `captures/2026-05-24-103045-news-ycombinator-com.md`).
    public let vaultPath: String
    public let capturedAt: Date
    /// `true` when the URL appeared in the user's prompt; `false` when
    /// it appeared only in the assistant's reply. Lets the client copy
    /// vary ("you saved …" vs "Hermes saved …").
    public let fromUserMessage: Bool
    public init(url: String, vaultPath: String, capturedAt: Date, fromUserMessage: Bool) {
        self.url = url
        self.vaultPath = vaultPath
        self.capturedAt = capturedAt
        self.fromUserMessage = fromUserMessage
    }
}

// ─── Conversations ───────────────────────────────────────────────────────

/// Role of an individual turn within a persisted Conversation.
public enum ConversationMessageRole: String, Codable, Sendable, CaseIterable {
    case user
    case assistant
    case system
}

/// A persisted multi-turn chat thread. Backs the "thinking workspace"
/// continuity surface on the Think tab.
public struct ConversationDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    /// Optional Space this conversation is scoped to.
    public let spaceId: UUID?
    public let createdAt: Date
    public let updatedAt: Date
    public init(id: UUID, title: String, spaceId: UUID? = nil, createdAt: Date, updatedAt: Date) {
        self.id = id; self.title = title; self.spaceId = spaceId
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

/// A single persisted turn within a Conversation. Distinct from the
/// transient `ChatMessage` used on the Hermes upstream wire — this type
/// is the durable, source-grounded record.
public struct ConversationMessageDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let conversationId: UUID
    public let role: ConversationMessageRole
    public let content: String
    /// Memory IDs the assistant cited when producing this turn. Empty for
    /// user/system turns.
    public let sourceMemoryIDs: [UUID]
    public let createdAt: Date
    public init(
        id: UUID,
        conversationId: UUID,
        role: ConversationMessageRole,
        content: String,
        sourceMemoryIDs: [UUID] = [],
        createdAt: Date
    ) {
        self.id = id; self.conversationId = conversationId; self.role = role
        self.content = content; self.sourceMemoryIDs = sourceMemoryIDs
        self.createdAt = createdAt
    }
}

/// Request body for `POST /v1/conversations`.
public struct ConversationCreateRequest: Codable, Sendable {
    public let title: String?
    public let spaceId: UUID?
    public init(title: String? = nil, spaceId: UUID? = nil) {
        self.title = title; self.spaceId = spaceId
    }
}

/// Response body for `GET /v1/conversations`.
public struct ConversationListResponse: Codable, Sendable {
    public let conversations: [ConversationDTO]
    public let nextCursor: String?
    public init(conversations: [ConversationDTO], nextCursor: String? = nil) {
        self.conversations = conversations; self.nextCursor = nextCursor
    }
}

/// Response body for `GET /v1/conversations/:id`.
public struct ConversationDetailResponse: Codable, Sendable {
    public let conversation: ConversationDTO
    public let messages: [ConversationMessageDTO]
    public init(conversation: ConversationDTO, messages: [ConversationMessageDTO]) {
        self.conversation = conversation; self.messages = messages
    }
}

/// Request body for `POST /v1/conversations/:id/messages/stream`. The
/// response is an SSE stream of `QueryStreamEvent`.
public struct MessageStreamRequest: Codable, Sendable {
    public let content: String
    public init(content: String) {
        self.content = content
    }
}

// ─── Spaces ──────────────────────────────────────────────────────────────

public struct SpaceDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let slug: String
    public let description: String?
    public let color: String?
    public let icon: String?
    /// Free-form bucket label (e.g. "ai", "stocks", "health") rendered as a
    /// segmented control on the client. Null for un-categorised spaces.
    public let category: String?
    /// Denormalized memo count, updated on ingest. Default 0.
    public let noteCount: Int
    /// Timestamp of last KB compile that included this space; null if never.
    public let lastCompiledAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?
    public init(id: UUID, name: String, slug: String, description: String? = nil, color: String? = nil, icon: String? = nil, category: String? = nil, noteCount: Int = 0, lastCompiledAt: Date? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id; self.name = name; self.slug = slug; self.description = description
        self.color = color; self.icon = icon; self.category = category
        self.noteCount = noteCount; self.lastCompiledAt = lastCompiledAt
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

public struct SpaceListResponse: Codable, Sendable {
    public let spaces: [SpaceDTO]
    public init(spaces: [SpaceDTO]) { self.spaces = spaces }
}

public struct CreateSpaceRequest: Codable, Sendable {
    public let name: String
    public let slug: String
    public let description: String?
    public let color: String?
    public let icon: String?
    public let category: String?
    public init(name: String, slug: String, description: String? = nil, color: String? = nil, icon: String? = nil, category: String? = nil) {
        self.name = name; self.slug = slug; self.description = description
        self.color = color; self.icon = icon; self.category = category
    }
}

public struct UpdateSpaceRequest: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let color: String?
    public let icon: String?
    public let category: String?
    public init(name: String? = nil, description: String? = nil, color: String? = nil, icon: String? = nil, category: String? = nil) {
        self.name = name; self.description = description; self.color = color
        self.icon = icon; self.category = category
    }
}

// ─── Vault ───────────────────────────────────────────────────────────────

/// `POST /v1/vault/create` carries no fields; defined as an empty marker
/// struct so client API layers retain a typed Encodable for the endpoint.
public struct VaultCreateRequest: Codable, Sendable {
    public init() {}
}

/// Returned by both `POST /v1/vault/create` (idempotent) and
/// `GET /v1/vault/status`. `defaultSpaceSlugs` lists the seeded Space slugs
/// created during the first successful vault bootstrap.
public struct VaultStatusResponse: Codable, Sendable {
    public let initialized: Bool
    public let createdAt: Date?
    public let defaultSpaceSlugs: [String]
    public init(initialized: Bool, createdAt: Date? = nil, defaultSpaceSlugs: [String] = []) {
        self.initialized = initialized
        self.createdAt = createdAt
        self.defaultSpaceSlugs = defaultSpaceSlugs
    }
}

public struct VaultUploadResponse: Codable, Sendable {
    public let path: String
    public let size: Int
    public let contentType: String
    public let sha256: String
    public init(path: String, size: Int, contentType: String, sha256: String) {
        self.path = path; self.size = size; self.contentType = contentType
        self.sha256 = sha256
    }
}

/// Note/smart-todo sidecar carried on a vault file. All optional so a plain
/// file (no note semantics) serialises to an empty object. `isTodo` promotes
/// a note to a checkable task; `done` + `dueAt` drive completion and the
/// client-scheduled reminder.
public struct VaultNoteMetadataDTO: Codable, Sendable, Equatable {
    public let title: String?
    public let tags: [String]?
    public let isTodo: Bool?
    public let done: Bool?
    public let dueAt: Date?
    public init(title: String? = nil, tags: [String]? = nil, isTodo: Bool? = nil, done: Bool? = nil, dueAt: Date? = nil) {
        self.title = title; self.tags = tags; self.isTodo = isTodo
        self.done = done; self.dueAt = dueAt
    }
}

public struct VaultFileDTO: Codable, Sendable {
    public let id: UUID
    public let path: String
    public let contentType: String
    public let sizeBytes: Int64
    public let sha256: String
    public let spaceId: UUID?
    public let createdAt: Date?
    public let updatedAt: Date?
    /// HER-Notes — note/todo metadata. Null/absent for non-note files.
    public let metadata: VaultNoteMetadataDTO?
    public init(id: UUID, path: String, contentType: String, sizeBytes: Int64, sha256: String, spaceId: UUID? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, metadata: VaultNoteMetadataDTO? = nil) {
        self.id = id; self.path = path; self.contentType = contentType
        self.sizeBytes = sizeBytes; self.sha256 = sha256; self.spaceId = spaceId
        self.createdAt = createdAt; self.updatedAt = updatedAt
        self.metadata = metadata
    }
}

public struct VaultFileListResponse: Codable, Sendable {
    public let files: [VaultFileDTO]
    public let limit: Int
    public let nextBefore: Date?
    public init(files: [VaultFileDTO], limit: Int, nextBefore: Date? = nil) {
        self.files = files; self.limit = limit; self.nextBefore = nextBefore
    }
}

public struct VaultMoveRequest: Codable, Sendable {
    public let path: String
    public let newPath: String
    public init(path: String, newPath: String) {
        self.path = path; self.newPath = newPath
    }
}

// ─── Device ──────────────────────────────────────────────────────────────

public enum DevicePlatform: String, Codable, Sendable, CaseIterable {
    case ios
    case android
}

public struct DeviceRegistrationRequest: Codable, Sendable {
    public let token: String
    public let platform: DevicePlatform
    public init(token: String, platform: DevicePlatform) {
        self.token = token; self.platform = platform
    }
}

public struct DeviceRegistrationResponse: Codable, Sendable {
    public let id: UUID
    public let token: String
    public let platform: String
    public init(id: UUID, token: String, platform: String) {
        self.id = id; self.token = token; self.platform = platform
    }
}

// ─── Onboarding ──────────────────────────────────────────────────────────

public struct OnboardingStateDTO: Codable, Sendable {
    public let signupCompleted: Bool
    public let signupCompletedAt: Date?
    public let emailVerifiedCompleted: Bool
    public let emailVerifiedCompletedAt: Date?
    public let soulConfiguredCompleted: Bool
    public let soulConfiguredCompletedAt: Date?
    public let firstCaptureCompleted: Bool
    public let firstCaptureCompletedAt: Date?
    public let firstKBCompileCompleted: Bool
    public let firstKBCompileCompletedAt: Date?
    public let firstQueryCompleted: Bool
    public let firstQueryCompletedAt: Date?
    /// HER-300 — true once user picks a default LLM brain (managed or BYOK).
    public let brainConfiguredCompleted: Bool
    public let brainConfiguredCompletedAt: Date?
    public init(
        signupCompleted: Bool,
        signupCompletedAt: Date?,
        emailVerifiedCompleted: Bool,
        emailVerifiedCompletedAt: Date?,
        soulConfiguredCompleted: Bool,
        soulConfiguredCompletedAt: Date?,
        firstCaptureCompleted: Bool,
        firstCaptureCompletedAt: Date?,
        firstKBCompileCompleted: Bool,
        firstKBCompileCompletedAt: Date?,
        firstQueryCompleted: Bool,
        firstQueryCompletedAt: Date?,
        brainConfiguredCompleted: Bool = false,
        brainConfiguredCompletedAt: Date? = nil
    ) {
        self.signupCompleted = signupCompleted; self.signupCompletedAt = signupCompletedAt
        self.emailVerifiedCompleted = emailVerifiedCompleted; self.emailVerifiedCompletedAt = emailVerifiedCompletedAt
        self.soulConfiguredCompleted = soulConfiguredCompleted; self.soulConfiguredCompletedAt = soulConfiguredCompletedAt
        self.firstCaptureCompleted = firstCaptureCompleted; self.firstCaptureCompletedAt = firstCaptureCompletedAt
        self.firstKBCompileCompleted = firstKBCompileCompleted; self.firstKBCompileCompletedAt = firstKBCompileCompletedAt
        self.firstQueryCompleted = firstQueryCompleted; self.firstQueryCompletedAt = firstQueryCompletedAt
        self.brainConfiguredCompleted = brainConfiguredCompleted
        self.brainConfiguredCompletedAt = brainConfiguredCompletedAt
    }

    private enum CodingKeys: String, CodingKey {
        case signupCompleted, signupCompletedAt
        case emailVerifiedCompleted, emailVerifiedCompletedAt
        case soulConfiguredCompleted, soulConfiguredCompletedAt
        case firstCaptureCompleted, firstCaptureCompletedAt
        case firstKBCompileCompleted, firstKBCompileCompletedAt
        case firstQueryCompleted, firstQueryCompletedAt
        case brainConfiguredCompleted, brainConfiguredCompletedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.signupCompleted = try c.decode(Bool.self, forKey: .signupCompleted)
        self.signupCompletedAt = try c.decodeIfPresent(Date.self, forKey: .signupCompletedAt)
        self.emailVerifiedCompleted = try c.decode(Bool.self, forKey: .emailVerifiedCompleted)
        self.emailVerifiedCompletedAt = try c.decodeIfPresent(Date.self, forKey: .emailVerifiedCompletedAt)
        self.soulConfiguredCompleted = try c.decode(Bool.self, forKey: .soulConfiguredCompleted)
        self.soulConfiguredCompletedAt = try c.decodeIfPresent(Date.self, forKey: .soulConfiguredCompletedAt)
        self.firstCaptureCompleted = try c.decode(Bool.self, forKey: .firstCaptureCompleted)
        self.firstCaptureCompletedAt = try c.decodeIfPresent(Date.self, forKey: .firstCaptureCompletedAt)
        self.firstKBCompileCompleted = try c.decode(Bool.self, forKey: .firstKBCompileCompleted)
        self.firstKBCompileCompletedAt = try c.decodeIfPresent(Date.self, forKey: .firstKBCompileCompletedAt)
        self.firstQueryCompleted = try c.decode(Bool.self, forKey: .firstQueryCompleted)
        self.firstQueryCompletedAt = try c.decodeIfPresent(Date.self, forKey: .firstQueryCompletedAt)
        self.brainConfiguredCompleted = try c.decodeIfPresent(Bool.self, forKey: .brainConfiguredCompleted) ?? false
        self.brainConfiguredCompletedAt = try c.decodeIfPresent(Date.self, forKey: .brainConfiguredCompletedAt)
    }
}

/// PATCH `/v1/onboarding` body. All flags optional; only `true` accepted —
/// `false` is rejected by the server because each flag is a one-way latch.
/// Omitted fields are left untouched. Server stamps an `*At` timestamp on
/// the first transition to `true` and ignores subsequent re-PATCHes.
public struct OnboardingPatchRequest: Codable, Sendable {
    public let signupCompleted: Bool?
    public let emailVerifiedCompleted: Bool?
    public let soulConfiguredCompleted: Bool?
    public let firstCaptureCompleted: Bool?
    public let firstKBCompileCompleted: Bool?
    public let firstQueryCompleted: Bool?
    public let brainConfiguredCompleted: Bool?
    public init(
        signupCompleted: Bool? = nil,
        emailVerifiedCompleted: Bool? = nil,
        soulConfiguredCompleted: Bool? = nil,
        firstCaptureCompleted: Bool? = nil,
        firstKBCompileCompleted: Bool? = nil,
        firstQueryCompleted: Bool? = nil,
        brainConfiguredCompleted: Bool? = nil
    ) {
        self.signupCompleted = signupCompleted
        self.emailVerifiedCompleted = emailVerifiedCompleted
        self.soulConfiguredCompleted = soulConfiguredCompleted
        self.firstCaptureCompleted = firstCaptureCompleted
        self.firstKBCompileCompleted = firstKBCompileCompleted
        self.firstQueryCompleted = firstQueryCompleted
        self.brainConfiguredCompleted = brainConfiguredCompleted
    }
}

// ─── KB Compile ──────────────────────────────────────────────────────────

/// Triggers a kb-compile run over the caller's vault. Three modes:
/// - `vaultFileIds == nil` (default) → server compiles all rows where `processedAt` is null.
/// - `vaultFileIds == [ids]` → server compiles exactly those rows (tenant-scoped).
/// - `forceFullRecompile == true` → server compiles every row for the tenant, ignoring `processedAt`.
public struct KBCompileRequest: Codable, Sendable {
    public let vaultFileIds: [UUID]?
    public let forceFullRecompile: Bool
    public init(vaultFileIds: [UUID]? = nil, forceFullRecompile: Bool = false) {
        self.vaultFileIds = vaultFileIds
        self.forceFullRecompile = forceFullRecompile
    }
}

public struct KBCompileResponse: Codable, Sendable, Equatable {
    public let memoriesIngested: Int
    public let memoriesUpdated: Int?
    public let durationMs: Int?
    public let runId: UUID
    /// HER-290 — IDs of memories produced by this run that are now awaiting
    /// approve/reject. Empty when nothing landed in `pending`. Mirrors what
    /// the WS `.memorySaved` events carry, so clients that don't subscribe
    /// to /v1/ws can still render the review list.
    public let pendingMemoryIds: [UUID]
    public init(
        memoriesIngested: Int,
        memoriesUpdated: Int?,
        durationMs: Int?,
        runId: UUID,
        pendingMemoryIds: [UUID] = []
    ) {
        self.memoriesIngested = memoriesIngested
        self.memoriesUpdated = memoriesUpdated
        self.durationMs = durationMs
        self.runId = runId
        self.pendingMemoryIds = pendingMemoryIds
    }
}

// MARK: - kb-compile progress (HER-288)

public struct KBCompileStartedDTO: Codable, Sendable, Equatable {
    public let runId: UUID
    public let totalFiles: Int
    public init(runId: UUID, totalFiles: Int) {
        self.runId = runId
        self.totalFiles = totalFiles
    }
}

public struct KBCompilePreparingDTO: Codable, Sendable, Equatable {
    public let runId: UUID
    public init(runId: UUID) { self.runId = runId }
}

public struct KBCompileThinkingDTO: Codable, Sendable, Equatable {
    public let runId: UUID
    public let iteration: Int
    public init(runId: UUID, iteration: Int) {
        self.runId = runId
        self.iteration = iteration
    }
}

public struct KBCompileMemorySavedDTO: Codable, Sendable, Equatable {
    public let runId: UUID
    public let memory: MemoryDTO
    public init(runId: UUID, memory: MemoryDTO) {
        self.runId = runId
        self.memory = memory
    }
}

public struct KBCompileCompletedDTO: Codable, Sendable, Equatable {
    public let runId: UUID
    public let response: KBCompileResponse
    public init(runId: UUID, response: KBCompileResponse) {
        self.runId = runId
        self.response = response
    }
}

public struct KBCompileErrorDTO: Codable, Sendable, Equatable {
    public let runId: UUID
    public let message: String
    public init(runId: UUID, message: String) {
        self.runId = runId
        self.message = message
    }
}

public enum KBCompileProgressEvent: Codable, Sendable, Equatable {
    case started(KBCompileStartedDTO)
    case preparing(KBCompilePreparingDTO)
    case thinking(KBCompileThinkingDTO)
    case memorySaved(KBCompileMemorySavedDTO)
    case completed(KBCompileCompletedDTO)
    case error(KBCompileErrorDTO)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum EventType: String, Codable {
        case started, preparing, thinking
        case memorySaved
        case completed, error
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(EventType.self, forKey: .type)
        switch type {
        case .started:
            self = .started(try c.decode(KBCompileStartedDTO.self, forKey: .payload))
        case .preparing:
            self = .preparing(try c.decode(KBCompilePreparingDTO.self, forKey: .payload))
        case .thinking:
            self = .thinking(try c.decode(KBCompileThinkingDTO.self, forKey: .payload))
        case .memorySaved:
            self = .memorySaved(try c.decode(KBCompileMemorySavedDTO.self, forKey: .payload))
        case .completed:
            self = .completed(try c.decode(KBCompileCompletedDTO.self, forKey: .payload))
        case .error:
            self = .error(try c.decode(KBCompileErrorDTO.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .started(let p):
            try c.encode(EventType.started, forKey: .type)
            try c.encode(p, forKey: .payload)
        case .preparing(let p):
            try c.encode(EventType.preparing, forKey: .type)
            try c.encode(p, forKey: .payload)
        case .thinking(let p):
            try c.encode(EventType.thinking, forKey: .type)
            try c.encode(p, forKey: .payload)
        case .memorySaved(let p):
            try c.encode(EventType.memorySaved, forKey: .type)
            try c.encode(p, forKey: .payload)
        case .completed(let p):
            try c.encode(EventType.completed, forKey: .type)
            try c.encode(p, forKey: .payload)
        case .error(let p):
            try c.encode(EventType.error, forKey: .type)
            try c.encode(p, forKey: .payload)
        }
    }
}

/// HER-293 — cheap pending-count probe behind the "Sync & Learn" button.
/// Returns the number of vault rows for the caller with `processedAt == nil`
/// so the iOS client can drive the button's disabled state and microcopy
/// without firing a full kb-compile.
public struct KBCompilePendingResponse: Codable, Sendable {
    public let pendingFiles: Int
    public init(pendingFiles: Int) {
        self.pendingFiles = pendingFiles
    }
}

// ─── Achievements ────────────────────────────────────────────────────────

public struct AchievementsListResponse: Codable, Sendable {
    public struct SubDTO: Codable, Sendable {
        public let key: String
        public let label: String
        public let target: Int64
        public let progress: Int64
        public let unlockedAt: Date?
        public init(key: String, label: String, target: Int64, progress: Int64, unlockedAt: Date? = nil) {
            self.key = key; self.label = label; self.target = target
            self.progress = progress; self.unlockedAt = unlockedAt
        }
    }
    public struct ArchetypeDTO: Codable, Sendable {
        public let key: String
        public let label: String
        public let sub: [SubDTO]
        public init(key: String, label: String, sub: [SubDTO]) {
            self.key = key; self.label = label; self.sub = sub
        }
    }
    public let catalogVersion: Int
    public let archetypes: [ArchetypeDTO]
    public init(catalogVersion: Int, archetypes: [ArchetypeDTO]) {
        self.catalogVersion = catalogVersion; self.archetypes = archetypes
    }
}

public struct AchievementsRecentResponse: Codable, Sendable {
    public struct UnlockDTO: Codable, Sendable {
        public let key: String
        public let label: String
        public let unlockedAt: Date
        public init(key: String, label: String, unlockedAt: Date) {
            self.key = key; self.label = label; self.unlockedAt = unlockedAt
        }
    }
    public let unlocks: [UnlockDTO]
    public init(unlocks: [UnlockDTO]) { self.unlocks = unlocks }
}

// ─── Health Ingest ───────────────────────────────────────────────────────

public struct HealthEventInput: Codable, Sendable {
    public let type: String
    public let recordedAt: Date
    public let valueNumeric: Double?
    public let valueText: String?
    public let unit: String?
    public let source: String?
    public let metadata: [String: String]?
    public init(type: String, recordedAt: Date, valueNumeric: Double? = nil, valueText: String? = nil, unit: String? = nil, source: String? = nil, metadata: [String: String]? = nil) {
        self.type = type; self.recordedAt = recordedAt; self.valueNumeric = valueNumeric
        self.valueText = valueText; self.unit = unit; self.source = source
        self.metadata = metadata
    }
}

public struct HealthIngestedRef: Codable, Sendable {
    public let id: UUID
    public let type: String
    public let recordedAt: Date
    public init(id: UUID, type: String, recordedAt: Date) {
        self.id = id; self.type = type; self.recordedAt = recordedAt
    }
}

public struct HealthIngestResponse: Codable, Sendable {
    public let inserted: Int
    public let skipped: Int
    public let events: [HealthIngestedRef]
    public init(inserted: Int, skipped: Int, events: [HealthIngestedRef]) {
        self.inserted = inserted; self.skipped = skipped; self.events = events
    }
}

// ─── Health Read (HER-118) ───────────────────────────────────────────────

/// One ingested health sample as returned by `GET /v1/health` (read-side).
/// Mirrors `HealthEventInput` (write-side) with the server-assigned `id`.
public struct HealthEventDTO: Codable, Sendable, Equatable {
    public let id: UUID
    /// Lowercased event type identifier (e.g. `"steps"`, `"hr_bpm"`,
    /// `"hrv_ms"`, `"sleep_session"`, `"mindful_minutes"`).
    public let type: String
    /// Timestamp when the sample was recorded on the source device (ISO-8601).
    public let recordedAt: Date
    public let valueNumeric: Double?
    public let valueText: String?
    public let unit: String?
    public let source: String?
    public init(
        id: UUID,
        type: String,
        recordedAt: Date,
        valueNumeric: Double? = nil,
        valueText: String? = nil,
        unit: String? = nil,
        source: String? = nil,
    ) {
        self.id = id; self.type = type; self.recordedAt = recordedAt
        self.valueNumeric = valueNumeric; self.valueText = valueText
        self.unit = unit; self.source = source
    }
}

/// Paginated response for `GET /v1/health?type=&from=&to=&limit=&offset=`.
public struct HealthListResponse: Codable, Sendable {
    public let events: [HealthEventDTO]
    public let limit: Int
    public let offset: Int
    public init(events: [HealthEventDTO], limit: Int, offset: Int) {
        self.events = events; self.limit = limit; self.offset = offset
    }
}

/// Single-day aggregation bucket for a given event type. Sum for
/// accumulating metrics (steps, active_energy, mindful_minutes); average
/// for instantaneous metrics (hr_bpm, hrv_ms, weight_kg, blood_oxygen);
/// sum of duration for `sleep_session`.
///
/// `value` is `0` and `sampleCount` is `0` for days with no samples —
/// the server fills gaps so the response always has a fixed-length
/// chronological window suitable for sparkline rendering without
/// client-side bucketing.
public struct HealthDayAggregateDTO: Codable, Sendable, Equatable {
    /// Start of the day in UTC (`date_trunc('day', recorded_at AT TIME ZONE 'UTC')`).
    public let date: Date
    public let type: String
    public let value: Double
    public let sampleCount: Int
    public init(date: Date, type: String, value: Double, sampleCount: Int) {
        self.date = date; self.type = type; self.value = value; self.sampleCount = sampleCount
    }
}

/// Response for `GET /v1/health/daily?type=&days=`. The `days` array is
/// chronologically ascending and always exactly `days` entries long
/// (gaps filled with zero-sample placeholders).
public struct HealthDailyResponse: Codable, Sendable {
    public let type: String
    public let days: [HealthDayAggregateDTO]
    public init(type: String, days: [HealthDayAggregateDTO]) {
        self.type = type; self.days = days
    }
}

// ─── Suggestions ─────────────────────────────────────────────────────────

/// Response body for `GET /v1/me/suggestions` — context-aware natural-language
/// query suggestions surfaced above the "Ask Lumina" input bar.
///
/// Scaffold returns a static list; future iterations will derive suggestions
/// from recent compiles, active Spaces, and SOUL.md tone.
public struct SuggestionsResponse: Codable, Sendable {
    public let suggestions: [String]
    public init(suggestions: [String]) { self.suggestions = suggestions }
}

// ─── Hermes Config ───────────────────────────────────────────────────────

public struct HermesConfigGetResponse: Codable, Sendable {
    public let baseUrl: String
    public let hasAuthHeader: Bool
    public let verifiedAt: Date?
    public init(baseUrl: String, hasAuthHeader: Bool, verifiedAt: Date? = nil) {
        self.baseUrl = baseUrl; self.hasAuthHeader = hasAuthHeader
        self.verifiedAt = verifiedAt
    }
}

public struct HermesConfigPutRequest: Codable, Sendable {
    public let baseUrl: String
    public let authHeader: String?
    public init(baseUrl: String, authHeader: String? = nil) {
        self.baseUrl = baseUrl; self.authHeader = authHeader
    }
}

public struct HermesConfigTestResponse: Codable, Sendable {
    public let verifiedAt: Date
    public init(verifiedAt: Date) { self.verifiedAt = verifiedAt }
}

// ─── Nous Portal subscription (OAuth device-code) ───────────────────────
// Lets a user connect their own Nous Portal subscription so their per-tenant
// Hermes container runs on their credits. Nous auth is OAuth device-code
// (no API key) and exposes no programmatic credits balance, so `plan` is a
// best-effort human string and there is no credits field.

/// GET /v1/integrations/nous — current Nous Portal connection state.
public struct NousStatusResponse: Codable, Sendable {
    public let connected: Bool
    public let nousConnectedAt: Date?
    public let plan: String?
    public init(connected: Bool, nousConnectedAt: Date? = nil, plan: String? = nil) {
        self.connected = connected
        self.nousConnectedAt = nousConnectedAt
        self.plan = plan
    }
}

/// POST /v1/integrations/nous/start — server returns the device verification
/// URL the client opens in a browser plus the user-code to display. The
/// in-container CLI polls Nous and self-completes once the user approves, so
/// there is no loopback callback to capture.
public struct NousStartResponse: Codable, Sendable {
    public let sessionID: String
    public let verifyURL: String
    public let userCode: String?
    public init(sessionID: String, verifyURL: String, userCode: String? = nil) {
        self.sessionID = sessionID
        self.verifyURL = verifyURL
        self.userCode = userCode
    }
}

/// POST /v1/integrations/nous/complete — client posts this once the user has
/// approved in their browser; the server awaits the polling CLI's exit.
public struct NousCompleteRequest: Codable, Sendable {
    public let sessionID: String
    public init(sessionID: String) {
        self.sessionID = sessionID
    }
}

// ─── Hermes Gateways (HER-241) ──────────────────────────────────────────

public enum HermesGatewayID: String, Codable, Sendable, CaseIterable {
    case telegram
    case discord
    case slack
    case whatsapp
    case email
}

public enum HermesGatewayStatus: String, Codable, Sendable, CaseIterable {
    case notConfigured = "not_configured"
    case configured
    case verified
    case error
}

public enum HermesGatewayFieldKind: String, Codable, Sendable, CaseIterable {
    case text
    case secret
    case url
}

public struct HermesGatewayField: Codable, Sendable, Hashable {
    public let key: String
    public let label: String
    public let placeholder: String?
    public let kind: HermesGatewayFieldKind
    public let isRequired: Bool

    public init(
        key: String,
        label: String,
        placeholder: String? = nil,
        kind: HermesGatewayFieldKind,
        isRequired: Bool = true
    ) {
        self.key = key
        self.label = label
        self.placeholder = placeholder
        self.kind = kind
        self.isRequired = isRequired
    }
}

/// How a gateway is configured from the app. `nil`/absent means the default
/// credential flow (enter token fields → `PUT` → Save & apply). A non-nil value
/// marks a gateway that needs an interactive pairing surface instead of a
/// credential form — currently only WhatsApp, which pairs via a streamed QR.
public enum HermesGatewayPairingKind: String, Codable, Sendable, CaseIterable {
    /// WhatsApp QR pairing: server runs `hermes whatsapp`, streams the QR to the
    /// app, the user scans it with their phone's *Linked Devices*. See
    /// `HermesWhatsAppPairEvent`.
    case whatsappQR
}

public struct HermesGatewayCatalogEntry: Codable, Sendable, Identifiable, Equatable {
    public let id: HermesGatewayID
    public let displayName: String
    public let iconSlug: String
    public let description: String
    public let requiredFields: [HermesGatewayField]
    public let status: HermesGatewayStatus
    public let hasConfig: Bool
    public let verifiedAt: Date?
    public let lastFailureCode: String?
    /// Non-nil → this gateway uses an interactive pairing flow, not the
    /// credential form. Optional for back-compat: omitted by older servers and
    /// for all credential gateways. The client branches its detail screen on it.
    public let pairingKind: HermesGatewayPairingKind?

    public init(
        id: HermesGatewayID,
        displayName: String,
        iconSlug: String,
        description: String,
        requiredFields: [HermesGatewayField],
        status: HermesGatewayStatus,
        hasConfig: Bool,
        verifiedAt: Date? = nil,
        lastFailureCode: String? = nil,
        pairingKind: HermesGatewayPairingKind? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.iconSlug = iconSlug
        self.description = description
        self.requiredFields = requiredFields
        self.status = status
        self.hasConfig = hasConfig
        self.verifiedAt = verifiedAt
        self.lastFailureCode = lastFailureCode
        self.pairingKind = pairingKind
    }
}

public struct HermesGatewaysListResponse: Codable, Sendable {
    public let items: [HermesGatewayCatalogEntry]
    public init(items: [HermesGatewayCatalogEntry]) { self.items = items }
}

public struct HermesGatewayPutRequest: Codable, Sendable {
    public let config: [String: String]
    public init(config: [String: String]) { self.config = config }
}

public struct HermesGatewayTestResponse: Codable, Sendable {
    public let ok: Bool
    public let verifiedAt: Date?
    public let errorCode: String?
    public let errorMessage: String?

    public init(
        ok: Bool,
        verifiedAt: Date? = nil,
        errorCode: String? = nil,
        errorMessage: String? = nil
    ) {
        self.ok = ok
        self.verifiedAt = verifiedAt
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
}

// ─── Hermes Gateway Apply (actuation) ───────────────────────────────────
//
// Wire types for the tenant-scoped "apply gateway config" flow. After the app
// PUTs a gateway's credentials, it calls `POST /v1/me/hermes-gateways/apply`,
// the backend rewrites the tenant's `.env` and recreates the Hermes container,
// and the client observes progress over an SSE stream of
// `HermesGatewayApplyEvent` (and/or by polling the job status). Mirrors the
// HER-330 self-update shape but per-tenant. See `LuminaVaultServer/Sources/App/`.

/// One step in the gateway-apply pipeline. Execution order.
public enum HermesGatewayApplyStepID: String, Codable, Sendable, CaseIterable {
    /// Render the tenant's gateway tokens into `/opt/data/.env`.
    case writeEnv
    /// `docker rm -f` + re-`docker run` so the new env takes effect.
    case restartContainer
    /// Probe the freshly-started container's health endpoint.
    case healthCheck
}

public enum HermesGatewayApplyStepState: String, Codable, Sendable {
    case pending
    case running
    case succeeded
    case failed
    case skipped
}

/// A single step's live state. `detail` carries a short human-readable status
/// line surfaced under the step row.
public struct HermesGatewayApplyStep: Codable, Sendable, Equatable, Identifiable {
    public let id: HermesGatewayApplyStepID
    public let state: HermesGatewayApplyStepState
    public let detail: String?
    public let startedAt: Date?
    public let finishedAt: Date?
    public init(
        id: HermesGatewayApplyStepID,
        state: HermesGatewayApplyStepState,
        detail: String? = nil,
        startedAt: Date? = nil,
        finishedAt: Date? = nil
    ) {
        self.id = id
        self.state = state
        self.detail = detail
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
}

public enum HermesGatewayApplyJobState: String, Codable, Sendable {
    case running
    case succeeded
    case failed
}

/// Full snapshot of an apply job. Returned by the poll/status and reconnect
/// endpoints, and as the terminal `.done` SSE event payload.
public struct HermesGatewayApplyJobStatus: Codable, Sendable, Equatable, Identifiable {
    public let jobID: UUID
    public let state: HermesGatewayApplyJobState
    public let steps: [HermesGatewayApplyStep]
    public let errorMessage: String?
    public let startedAt: Date
    public let updatedAt: Date
    public var id: UUID { jobID }
    public init(
        jobID: UUID,
        state: HermesGatewayApplyJobState,
        steps: [HermesGatewayApplyStep],
        errorMessage: String? = nil,
        startedAt: Date,
        updatedAt: Date
    ) {
        self.jobID = jobID
        self.state = state
        self.steps = steps
        self.errorMessage = errorMessage
        self.startedAt = startedAt
        self.updatedAt = updatedAt
    }
}

/// SSE frame for the apply stream. Discriminated by a top-level `type` field,
/// matching `HermesUpdateEvent`. Decoded on the client with
/// `JSONDecoder.hvDefault` (`.iso8601` dates).
public enum HermesGatewayApplyEvent: Codable, Sendable, Equatable {
    /// A step changed state. Emitted on every transition.
    case step(HermesGatewayApplyStep)
    /// Job-level state change.
    case status(HermesGatewayApplyJobState)
    /// Terminal event carrying the final snapshot.
    case done(HermesGatewayApplyJobStatus)
    /// Stream-level error (distinct from a step failure inside `.done`).
    case error(String)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum EventType: String, Codable {
        case step, status, done, error
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(EventType.self, forKey: .type)
        switch type {
        case .step: self = .step(try c.decode(HermesGatewayApplyStep.self, forKey: .payload))
        case .status: self = .status(try c.decode(HermesGatewayApplyJobState.self, forKey: .payload))
        case .done: self = .done(try c.decode(HermesGatewayApplyJobStatus.self, forKey: .payload))
        case .error: self = .error(try c.decode(String.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .step(let s):
            try c.encode(EventType.step, forKey: .type)
            try c.encode(s, forKey: .payload)
        case .status(let st):
            try c.encode(EventType.status, forKey: .type)
            try c.encode(st, forKey: .payload)
        case .done(let snapshot):
            try c.encode(EventType.done, forKey: .type)
            try c.encode(snapshot, forKey: .payload)
        case .error(let message):
            try c.encode(EventType.error, forKey: .type)
            try c.encode(message, forKey: .payload)
        }
    }
}

/// Response body for `POST /v1/me/hermes-gateways/apply`.
public struct StartHermesGatewayApplyResponse: Codable, Sendable {
    public let jobID: UUID
    public let state: HermesGatewayApplyJobState
    public init(jobID: UUID, state: HermesGatewayApplyJobState) {
        self.jobID = jobID
        self.state = state
    }
}

// ─── Hermes WhatsApp QR Pairing ─────────────────────────────────────────
//
// WhatsApp is the one gateway with no enterable credential: Hermes pairs via
// Baileys, driven by the interactive `hermes whatsapp` CLI which streams a QR
// to its terminal. The server runs that CLI inside the tenant's container,
// captures the QR block-art from stdout, and relays it to the app over SSE as
// a stream of `HermesWhatsAppPairEvent`. The user scans the QR with their
// phone's *WhatsApp → Linked Devices*; the session then persists on the
// tenant's data volume. Mirrors the `HermesGatewayApplyEvent` wire shape.

/// Live status of a WhatsApp pairing session.
public enum HermesWhatsAppPairStatus: String, Codable, Sendable, CaseIterable {
    /// CLI is launching inside the container; no QR yet.
    case starting
    /// A QR has been emitted and is waiting to be scanned.
    case awaitingScan
    /// Phone scanned the QR; Hermes is establishing the session.
    case linking
    /// Device successfully linked; session persisted.
    case linked
    /// The current QR expired before it was scanned (a fresh one usually
    /// follows). Surfaced so the UI can show a "refreshing…" hint.
    case expired
    /// Pairing failed; see the accompanying `.error` event message.
    case failed
}

/// SSE frame for the WhatsApp pairing stream. Discriminated by a top-level
/// `type` field, matching `HermesGatewayApplyEvent`. Decoded on the client with
/// `JSONDecoder.hvDefault`.
public enum HermesWhatsAppPairEvent: Codable, Sendable, Equatable {
    /// One complete terminal QR block (Unicode block-art). Each emission
    /// fully replaces the previously displayed QR (Hermes refreshes it
    /// roughly every 20s).
    case qr(String)
    /// Pairing status changed.
    case status(HermesWhatsAppPairStatus)
    /// Terminal success — the device is linked and the session is saved.
    case linked
    /// Terminal failure with a human-readable reason.
    case error(String)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum EventType: String, Codable {
        case qr, status, linked, error
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(EventType.self, forKey: .type)
        switch type {
        case .qr: self = .qr(try c.decode(String.self, forKey: .payload))
        case .status: self = .status(try c.decode(HermesWhatsAppPairStatus.self, forKey: .payload))
        case .linked: self = .linked
        case .error: self = .error(try c.decode(String.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .qr(let art):
            try c.encode(EventType.qr, forKey: .type)
            try c.encode(art, forKey: .payload)
        case .status(let s):
            try c.encode(EventType.status, forKey: .type)
            try c.encode(s, forKey: .payload)
        case .linked:
            try c.encode(EventType.linked, forKey: .type)
        case .error(let message):
            try c.encode(EventType.error, forKey: .type)
            try c.encode(message, forKey: .payload)
        }
    }
}

/// Response body for `POST /v1/me/hermes-gateways/whatsapp/pair`. The client
/// then opens the SSE stream at `.../whatsapp/pair/{sessionID}/stream`.
public struct StartWhatsAppPairResponse: Codable, Sendable {
    public let sessionID: UUID
    public init(sessionID: UUID) { self.sessionID = sessionID }
}

// ─── Hermes Profiles (HER-273 — multi-agent per user) ───────────────────

public struct HermesProfileDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let slug: String
    public let label: String
    public let systemPrompt: String
    public let isDefault: Bool
    public let skillsEnabled: [String]
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID,
        slug: String,
        label: String,
        systemPrompt: String,
        isDefault: Bool,
        skillsEnabled: [String],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.slug = slug
        self.label = label
        self.systemPrompt = systemPrompt
        self.isDefault = isDefault
        self.skillsEnabled = skillsEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct HermesProfilesListResponse: Codable, Sendable {
    public let items: [HermesProfileDTO]
    public let activeSlug: String?
    public init(items: [HermesProfileDTO], activeSlug: String?) {
        self.items = items
        self.activeSlug = activeSlug
    }
}

public struct HermesProfileCreateRequest: Codable, Sendable {
    public let slug: String
    public let label: String
    public let systemPrompt: String?
    public let templateSlug: String?
    public let skillsEnabled: [String]?

    public init(
        slug: String,
        label: String,
        systemPrompt: String? = nil,
        templateSlug: String? = nil,
        skillsEnabled: [String]? = nil
    ) {
        self.slug = slug
        self.label = label
        self.systemPrompt = systemPrompt
        self.templateSlug = templateSlug
        self.skillsEnabled = skillsEnabled
    }
}

public struct HermesProfilePatchRequest: Codable, Sendable {
    public let label: String?
    public let systemPrompt: String?
    public let skillsEnabled: [String]?

    public init(
        label: String? = nil,
        systemPrompt: String? = nil,
        skillsEnabled: [String]? = nil
    ) {
        self.label = label
        self.systemPrompt = systemPrompt
        self.skillsEnabled = skillsEnabled
    }
}

public struct HermesProfileActivateResponse: Codable, Sendable {
    public let slug: String
    public let activatedAt: Date
    public init(slug: String, activatedAt: Date) {
        self.slug = slug
        self.activatedAt = activatedAt
    }
}

// ─── Dashboard (HER-244 — OS Shell Home) ────────────────────────────────

public enum TaskState: String, Codable, Sendable, CaseIterable {
    case running
    case queued
    case completed
    case failed
}

public struct TaskDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let kind: String
    public let label: String
    public let state: TaskState
    public let progress: Double?
    public let startedAt: Date?
    public let elapsedSeconds: Int?
    public let error: String?
    public init(
        id: UUID,
        kind: String,
        label: String,
        state: TaskState,
        progress: Double? = nil,
        startedAt: Date? = nil,
        elapsedSeconds: Int? = nil,
        error: String? = nil
    ) {
        self.id = id; self.kind = kind; self.label = label; self.state = state
        self.progress = progress; self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds; self.error = error
    }
}

public struct TaskListResponse: Codable, Sendable {
    public let tasks: [TaskDTO]
    public let nextCursor: String?
    public init(tasks: [TaskDTO], nextCursor: String? = nil) {
        self.tasks = tasks; self.nextCursor = nextCursor
    }
}

public enum InsightSection: String, Codable, Sendable, CaseIterable {
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case patterns
    case contradictions
    case connections
}

public struct InsightDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let headline: String
    public let summary: String
    public let section: InsightSection
    public let createdAt: Date
    public let sourceMemoryIDs: [UUID]
    public let dismissed: Bool
    /// Inclusive start of the analytical period this insight covers. Set for
    /// `thisWeek`/`thisMonth` synthesis rows; nil for pattern-style insights.
    public let periodStart: Date?
    /// Inclusive end of the analytical period. See `periodStart`.
    public let periodEnd: Date?
    public init(
        id: UUID,
        headline: String,
        summary: String,
        section: InsightSection,
        createdAt: Date,
        sourceMemoryIDs: [UUID] = [],
        dismissed: Bool = false,
        periodStart: Date? = nil,
        periodEnd: Date? = nil
    ) {
        self.id = id; self.headline = headline; self.summary = summary
        self.section = section; self.createdAt = createdAt
        self.sourceMemoryIDs = sourceMemoryIDs; self.dismissed = dismissed
        self.periodStart = periodStart; self.periodEnd = periodEnd
    }
}

public struct InsightListResponse: Codable, Sendable {
    public let insights: [InsightDTO]
    public let nextCursor: String?
    public init(insights: [InsightDTO], nextCursor: String? = nil) {
        self.insights = insights; self.nextCursor = nextCursor
    }
}

public struct DashboardStatsResponse: Codable, Sendable {
    public let memoriesToday: Int
    public let memoriesTotal: Int
    public let lastCompileAt: Date?
    public init(memoriesToday: Int, memoriesTotal: Int, lastCompileAt: Date? = nil) {
        self.memoriesToday = memoriesToday
        self.memoriesTotal = memoriesTotal
        self.lastCompileAt = lastCompileAt
    }
}

/// `GET /v1/dashboard/profile` — the "player profile" HUD counts shown on
/// the Home dashboard. Aggregated server-side per tenant.
/// `badgesEarned` is the count of unlocked sub-achievements
/// (`achievement_progress` rows with a non-null `unlocked_at`).
/// `powerLevel` is derived from `powerXP`: `floor(sqrt(powerXP)) + 1`.
/// `powerXP` is returned too so the client can render a progress ring
/// toward the next level.
public struct DashboardProfileResponse: Codable, Sendable {
    public let skillsCount: Int
    public let jobsCount: Int
    public let sessionsCount: Int
    public let badgesEarned: Int
    public let powerLevel: Int
    public let powerXP: Int
    public init(
        skillsCount: Int,
        jobsCount: Int,
        sessionsCount: Int,
        badgesEarned: Int,
        powerLevel: Int,
        powerXP: Int
    ) {
        self.skillsCount = skillsCount
        self.jobsCount = jobsCount
        self.sessionsCount = sessionsCount
        self.badgesEarned = badgesEarned
        self.powerLevel = powerLevel
        self.powerXP = powerXP
    }
}

// ─── Skills (HER-247 / HER-178) ───────────────────────────────────────────

public enum SkillSource: String, Codable, Sendable, CaseIterable {
    case builtin
    case vault
}

public enum SkillRunStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case running
    case success
    case error
}

// ─── Lumina Blocks (Jobs P2) — structured, natively-rendered output ──────
//
// A domain-agnostic block schema the AI emits and the iOS client renders as
// native SwiftUI (cards, charts, lists) instead of Markdown. Reused for job
// results, note bodies, and link summaries. Intentionally a *flat
// discriminated union* (a `type` string + optional typed fields) rather than
// a Swift enum-with-associated-values, so: (a) the AI emits trivially
// (`{"type":"statCard", ...}`), and (b) **older clients tolerate unknown
// block types** — an unrecognised `type` renders a graceful fallback instead
// of failing to decode the whole payload. Versioned by the `type` vocabulary.

public struct LuminaChartPoint: Codable, Sendable {
    public let x: String
    public let y: Double
    public init(x: String, y: Double) { self.x = x; self.y = y }
}

public struct LuminaSeries: Codable, Sendable {
    public let name: String
    public let points: [LuminaChartPoint]
    public init(name: String, points: [LuminaChartPoint]) { self.name = name; self.points = points }
}

public struct LuminaKeyValue: Codable, Sendable {
    public let key: String
    public let value: String
    public init(key: String, value: String) { self.key = key; self.value = value }
}

public struct LuminaBlock: Codable, Sendable {
    /// Discriminator. Known: heading · paragraph · markdown · statCard ·
    /// lineChart · barChart · list · table · badge · keyValue · quote ·
    /// image · divider. Unknown values render a fallback client-side.
    public let type: String
    public let text: String?          // heading/paragraph/markdown/quote/badge
    public let level: Int?            // heading depth (1…3)
    public let label: String?         // statCard caption
    public let value: String?         // statCard primary value
    public let delta: String?         // statCard change ("+1.2%")
    public let trend: String?         // "up" | "down" | "flat"
    public let items: [String]?       // list rows
    public let columns: [String]?     // table header
    public let rows: [[String]]?      // table body
    public let series: [LuminaSeries]? // lineChart/barChart
    public let pairs: [LuminaKeyValue]? // keyValue grid
    public let url: String?           // image

    public init(
        type: String,
        text: String? = nil,
        level: Int? = nil,
        label: String? = nil,
        value: String? = nil,
        delta: String? = nil,
        trend: String? = nil,
        items: [String]? = nil,
        columns: [String]? = nil,
        rows: [[String]]? = nil,
        series: [LuminaSeries]? = nil,
        pairs: [LuminaKeyValue]? = nil,
        url: String? = nil
    ) {
        self.type = type; self.text = text; self.level = level
        self.label = label; self.value = value; self.delta = delta; self.trend = trend
        self.items = items; self.columns = columns; self.rows = rows
        self.series = series; self.pairs = pairs; self.url = url
    }
}

public enum SkillCapability: String, Codable, Sendable, CaseIterable {
    case low
    case medium
    case high
}

public struct SkillDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let source: SkillSource
    public let name: String
    public let title: String
    public let descriptionText: String
    public let capability: SkillCapability
    public let schedule: String?
    public let scheduleOverride: String?
    public let enabled: Bool
    public let lastRunAt: Date?
    public let lastStatus: SkillRunStatus?
    public let lastError: String?
    public let dailyRunCount: Int
    public let dailyRunCap: Int
    public let apnsCategory: APNSCategory?
    public let bodyExcerpt: String

    public init(
        id: String,
        source: SkillSource,
        name: String,
        title: String,
        descriptionText: String,
        capability: SkillCapability,
        schedule: String? = nil,
        scheduleOverride: String? = nil,
        enabled: Bool,
        lastRunAt: Date? = nil,
        lastStatus: SkillRunStatus? = nil,
        lastError: String? = nil,
        dailyRunCount: Int = 0,
        dailyRunCap: Int = 0,
        apnsCategory: APNSCategory? = nil,
        bodyExcerpt: String
    ) {
        self.id = id
        self.source = source
        self.name = name
        self.title = title
        self.descriptionText = descriptionText
        self.capability = capability
        self.schedule = schedule
        self.scheduleOverride = scheduleOverride
        self.enabled = enabled
        self.lastRunAt = lastRunAt
        self.lastStatus = lastStatus
        self.lastError = lastError
        self.dailyRunCount = dailyRunCount
        self.dailyRunCap = dailyRunCap
        self.apnsCategory = apnsCategory
        self.bodyExcerpt = bodyExcerpt
    }
}

public struct SkillListResponse: Codable, Sendable {
    public let skills: [SkillDTO]
    public init(skills: [SkillDTO]) { self.skills = skills }
}

// ─── Apple Ecosystem Integration — per-domain data-access consent ─────────
//
// The LuminaVault consent layer (separate from, and stricter than, the iOS
// permission). `allowed` gates BOTH on-device sync AND Hermes tool access for
// the domain; `allowWrites` lets Hermes make changes (Calendar/Reminders).
// Enforced server-side, not just in the UI.

public enum AppleDataDomain: String, Codable, Sendable, CaseIterable {
    case health
    case calendar
    case reminders
    case photos
    case location
    case files
}

public struct AppleConsentDTO: Codable, Sendable, Identifiable {
    public var id: AppleDataDomain { domain }
    public let domain: AppleDataDomain
    public let allowed: Bool
    public let allowWrites: Bool
    public let lastSyncAt: Date?

    public init(domain: AppleDataDomain, allowed: Bool, allowWrites: Bool = false, lastSyncAt: Date? = nil) {
        self.domain = domain; self.allowed = allowed
        self.allowWrites = allowWrites; self.lastSyncAt = lastSyncAt
    }
}

public struct AppleConsentResponse: Codable, Sendable {
    public let consents: [AppleConsentDTO]
    public init(consents: [AppleConsentDTO]) { self.consents = consents }
}

/// Upsert one domain's consent. `allowWrites` omitted = leave unchanged.
public struct AppleConsentUpdateRequest: Codable, Sendable {
    public let domain: AppleDataDomain
    public let allowed: Bool
    public let allowWrites: Bool?
    public init(domain: AppleDataDomain, allowed: Bool, allowWrites: Bool? = nil) {
        self.domain = domain; self.allowed = allowed; self.allowWrites = allowWrites
    }
}

// ─── Apple Integration P0b — device-RPC (server ⇄ on-device live/writes) ──
//
// When Hermes needs fresh on-device data or a write (add reminder, create
// event, fetch a photo), the backend enqueues a DeviceCommand, delivers it to
// the app over the WebSocket channel (APNS-wake fallback), the app executes it
// against the Apple SDK, and POSTs back a DeviceCommandResult. A broker
// correlates the two by `id` with a timeout. Consent is enforced server-side
// before the command is ever sent.

public enum DeviceCommandKind: String, Codable, Sendable {
    case ping                                  // round-trip health check
    case reminderCreate = "reminder_create"    // EventKit write
    case calendarCreate = "calendar_create"    // EventKit write
    case deviceFetch = "device_fetch"          // fresh read of a domain
    case photoAnalyze = "photo_analyze"        // on-demand single-asset analysis
}

public struct DeviceCommand: Codable, Sendable, Identifiable {
    public let id: UUID
    public let kind: DeviceCommandKind
    public let domain: AppleDataDomain?
    /// Free-form string args (kept simple + Codable; richer payloads can ride
    /// a JSON string value). e.g. {"title":"Call mom","due":"2026-06-02T18:00"}.
    public let payload: [String: String]

    public init(id: UUID = UUID(), kind: DeviceCommandKind, domain: AppleDataDomain? = nil, payload: [String: String] = [:]) {
        self.id = id; self.kind = kind; self.domain = domain; self.payload = payload
    }
}

/// WebSocket envelope wrapping a command for the device (`type` lets the client
/// route device commands apart from other WS traffic like compile progress).
public struct DeviceCommandEnvelope: Codable, Sendable {
    public let type: String
    public let command: DeviceCommand
    public init(command: DeviceCommand) { self.type = "device_command"; self.command = command }
}

public struct DeviceCommandResult: Codable, Sendable, Identifiable {
    public let id: UUID
    public let ok: Bool
    public let payload: [String: String]?
    public let error: String?
    public init(id: UUID, ok: Bool, payload: [String: String]? = nil, error: String? = nil) {
        self.id = id; self.ok = ok; self.payload = payload; self.error = error
    }
}

// ─── Lumina Jobs P3 — chat→job detection + creation ──────────────────────

/// Result of classifying a chat message for recurring-job intent
/// (POST /v1/jobs/detect). When `isJob` is true the client shows a
/// "Create Job" proposal card pre-filled from these fields.
public struct JobProposalDTO: Codable, Sendable {
    public let isJob: Bool
    public let title: String?
    /// Cron expression, e.g. "0 8 * * *".
    public let cron: String?
    /// Human-readable schedule, e.g. "Every day at 8:00 AM".
    public let scheduleHuman: String?
    /// Domain hint (stocks, sports, ai, tech, health, life…) — drives the
    /// AI's block choices when the job runs.
    public let domain: String?
    /// What the job should monitor/produce each run (becomes the skill body).
    public let spec: String?

    public init(
        isJob: Bool,
        title: String? = nil,
        cron: String? = nil,
        scheduleHuman: String? = nil,
        domain: String? = nil,
        spec: String? = nil
    ) {
        self.isJob = isJob; self.title = title; self.cron = cron
        self.scheduleHuman = scheduleHuman; self.domain = domain; self.spec = spec
    }
}

/// Body for POST /v1/jobs — creates a scheduled job (a vault cron skill).
public struct JobCreateRequest: Codable, Sendable {
    public let title: String
    public let cron: String
    public let domain: String?
    public let spec: String
    public let spaceId: UUID?

    public init(title: String, cron: String, domain: String? = nil, spec: String, spaceId: UUID? = nil) {
        self.title = title; self.cron = cron; self.domain = domain
        self.spec = spec; self.spaceId = spaceId
    }
}

public struct SkillRunDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let status: SkillRunStatus
    public let error: String?
    public let modelUsed: String?
    public let mtokIn: Int?
    public let mtokOut: Int?
    /// Lumina Jobs P1 — the run's rendered output (Markdown). The iOS Jobs
    /// surface renders this as the job result. `nil` for runs logged before
    /// output persistence (M66) or runs that produced no body.
    public let markdown: String?
    /// Lumina Jobs P2 — structured native-render blocks. When present the
    /// client renders these (cards/charts/lists) instead of `markdown`;
    /// `markdown` stays as the fallback + email/gateway body.
    public let blocks: [LuminaBlock]?

    public init(
        id: UUID,
        startedAt: Date,
        endedAt: Date? = nil,
        status: SkillRunStatus,
        error: String? = nil,
        modelUsed: String? = nil,
        mtokIn: Int? = nil,
        mtokOut: Int? = nil,
        markdown: String? = nil,
        blocks: [LuminaBlock]? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.status = status
        self.error = error
        self.modelUsed = modelUsed
        self.mtokIn = mtokIn
        self.mtokOut = mtokOut
        self.markdown = markdown
        self.blocks = blocks
    }
}

public struct SkillSparklinePoint: Codable, Sendable {
    public let day: Date
    public let count: Int
    public init(day: Date, count: Int) {
        self.day = day; self.count = count
    }
}

public struct SkillRunsResponse: Codable, Sendable {
    public let runs: [SkillRunDTO]
    public let sparkline: [SkillSparklinePoint]
    public let nextCursor: String?
    public init(runs: [SkillRunDTO], sparkline: [SkillSparklinePoint], nextCursor: String? = nil) {
        self.runs = runs; self.sparkline = sparkline; self.nextCursor = nextCursor
    }
}

public struct SkillPatchRequest: Codable, Sendable {
    public let enabled: Bool?
    public let scheduleOverride: String?
    public let apnsCategory: APNSCategory?
    public init(enabled: Bool? = nil, scheduleOverride: String? = nil, apnsCategory: APNSCategory? = nil) {
        self.enabled = enabled
        self.scheduleOverride = scheduleOverride
        self.apnsCategory = apnsCategory
    }
}

public struct SkillRunRequest: Codable, Sendable {
    public let input: String?
    public let arguments: [String: String]?
    public let save: Bool?

    public init(input: String? = nil, arguments: [String: String]? = nil, save: Bool? = nil) {
        self.input = input
        self.arguments = arguments
        self.save = save
    }
}

public struct SkillRunResponse: Codable, Sendable, Identifiable {
    public let id: UUID
    public let skillName: String
    public let status: SkillRunStatus
    public let markdown: String
    public let savedPath: String?
    public let modelUsed: String?
    public let mtokIn: Int?
    public let mtokOut: Int?
    public let startedAt: Date
    public let endedAt: Date?

    public init(
        id: UUID,
        skillName: String,
        status: SkillRunStatus,
        markdown: String,
        savedPath: String? = nil,
        modelUsed: String? = nil,
        mtokIn: Int? = nil,
        mtokOut: Int? = nil,
        startedAt: Date,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.skillName = skillName
        self.status = status
        self.markdown = markdown
        self.savedPath = savedPath
        self.modelUsed = modelUsed
        self.mtokIn = mtokIn
        self.mtokOut = mtokOut
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

public struct SkillSlashCommandRequest: Codable, Sendable {
    public let command: String

    public init(command: String) {
        self.command = command
    }
}

// ─── Skill Outputs / Today feed (HER-177) ─────────────────────────────────

public enum SkillOutputKind: String, Codable, Sendable, CaseIterable {
    case dailyBrief = "daily_brief"
    case weeklyMemo = "weekly_memo"
    case correlationInsight = "correlation_insight"
    case captureEnriched = "capture_enriched"
    case patternFinding = "pattern_finding"
    case contradictionFinding = "contradiction_finding"
    case generic
}

public struct SkillOutputDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let skillName: String
    public let source: SkillSource
    public let kind: SkillOutputKind
    public let headline: String
    public let body: String
    public let createdAt: Date
    public let memoryID: UUID?
    public let memoID: UUID?
    public let vaultFilePath: String?

    public init(
        id: UUID,
        skillName: String,
        source: SkillSource,
        kind: SkillOutputKind,
        headline: String,
        body: String,
        createdAt: Date,
        memoryID: UUID? = nil,
        memoID: UUID? = nil,
        vaultFilePath: String? = nil
    ) {
        self.id = id
        self.skillName = skillName
        self.source = source
        self.kind = kind
        self.headline = headline
        self.body = body
        self.createdAt = createdAt
        self.memoryID = memoryID
        self.memoID = memoID
        self.vaultFilePath = vaultFilePath
    }
}

public struct SkillOutputListResponse: Codable, Sendable {
    public let outputs: [SkillOutputDTO]
    public let streakDays: Int
    public let activeRun: Bool
    public let nextCursor: String?
    public init(outputs: [SkillOutputDTO], streakDays: Int, activeRun: Bool, nextCursor: String? = nil) {
        self.outputs = outputs
        self.streakDays = streakDays
        self.activeRun = activeRun
        self.nextCursor = nextCursor
    }
}

// ─── APNS category prefs (HER-179) ────────────────────────────────────────

public enum APNSCategory: String, Codable, Sendable, CaseIterable {
    case chat
    case nudge
    case digest
}

public struct APNSCategoryPrefsResponse: Codable, Sendable {
    public let chatEnabled: Bool
    public let nudgeEnabled: Bool
    public let digestEnabled: Bool
    public init(chatEnabled: Bool, nudgeEnabled: Bool, digestEnabled: Bool) {
        self.chatEnabled = chatEnabled
        self.nudgeEnabled = nudgeEnabled
        self.digestEnabled = digestEnabled
    }
}

public struct APNSCategoryPrefsPutRequest: Codable, Sendable {
    public let chatEnabled: Bool?
    public let nudgeEnabled: Bool?
    public let digestEnabled: Bool?
    public init(chatEnabled: Bool? = nil, nudgeEnabled: Bool? = nil, digestEnabled: Bool? = nil) {
        self.chatEnabled = chatEnabled
        self.nudgeEnabled = nudgeEnabled
        self.digestEnabled = digestEnabled
    }
}

// ─── Sessions (HER-245) ───────────────────────────────────────────────────

public struct SessionDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let preview: String
    public let messageCount: Int
    public let lastMessageAt: Date
    public let workspaceID: UUID?
    public let pinned: Bool
    public let archived: Bool
    public init(
        id: UUID,
        title: String,
        preview: String,
        messageCount: Int,
        lastMessageAt: Date,
        workspaceID: UUID? = nil,
        pinned: Bool = false,
        archived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.preview = preview
        self.messageCount = messageCount
        self.lastMessageAt = lastMessageAt
        self.workspaceID = workspaceID
        self.pinned = pinned
        self.archived = archived
    }
}

public struct SessionListResponse: Codable, Sendable {
    public let sessions: [SessionDTO]
    public let nextCursor: String?
    public init(sessions: [SessionDTO], nextCursor: String? = nil) {
        self.sessions = sessions
        self.nextCursor = nextCursor
    }
}

// ─── SOUL.md client read (HER-250) ────────────────────────────────────────

public struct SoulMdResponse: Codable, Sendable {
    public let body: String
    public let updatedAt: Date?
    public init(body: String, updatedAt: Date? = nil) {
        self.body = body
        self.updatedAt = updatedAt
    }
}

public struct SoulMdPutRequest: Codable, Sendable {
    public let body: String
    public init(body: String) { self.body = body }
}

// ─── Provider Credentials (HER-252) ──────────────────────────────────────

/// Identifies an external LLM provider the user can attach credentials to.
/// Mirrors the server-side `ProviderKind` cases that participate in
/// per-user credential management. Hermes gateway providers (in-VPS) are
/// not user-credential targets — they're deployment infrastructure.
public enum ProviderID: String, Codable, Sendable, CaseIterable {
    case xai
    case anthropic
    case openai
    case ollama
    case openRouter
    /// NVIDIA NIM — OpenAI-compatible inference API
    /// (`https://integrate.api.nvidia.com/v1`). Per-user `nvapi-` key in
    /// `user_provider_credentials`; routed via the OpenAI-compatible adapter.
    case nvidia
}

/// Shape of the credential we store for a given provider. `apiKey` and
/// `hostURL` are mutually exclusive: providers like Ollama only need a
/// reachable host URL with no secret. `oauth` is reserved for providers
/// (xAI Path B) that complete their flow elsewhere and only need a marker
/// row in the credential table.
public enum ProviderCredentialKind: String, Codable, Sendable {
    case apiKey
    case oauth
    case hostURL
}

/// Server's representation of a per-user provider credential.
/// Plaintext is never echoed back — callers see `hasCredential` only.
/// `verifiedAt` / `lastFailureAt` reflect the last `/test` outcome.
public struct ProviderCredentialDTO: Codable, Sendable {
    public let provider: ProviderID
    public let kind: ProviderCredentialKind
    public let hasCredential: Bool
    public let baseUrl: String?
    public let label: String?
    public let verifiedAt: Date?
    public let lastFailureAt: Date?
    public let lastFailureCode: String?
    public init(
        provider: ProviderID,
        kind: ProviderCredentialKind,
        hasCredential: Bool,
        baseUrl: String? = nil,
        label: String? = nil,
        verifiedAt: Date? = nil,
        lastFailureAt: Date? = nil,
        lastFailureCode: String? = nil
    ) {
        self.provider = provider
        self.kind = kind
        self.hasCredential = hasCredential
        self.baseUrl = baseUrl
        self.label = label
        self.verifiedAt = verifiedAt
        self.lastFailureAt = lastFailureAt
        self.lastFailureCode = lastFailureCode
    }
}

public struct ProviderCredentialsListResponse: Codable, Sendable {
    public let providers: [ProviderCredentialDTO]
    public init(providers: [ProviderCredentialDTO]) {
        self.providers = providers
    }
}

public struct ProviderCredentialPutRequest: Codable, Sendable {
    public let kind: ProviderCredentialKind
    public let apiKey: String?
    public let baseUrl: String?
    public let label: String?
    public init(
        kind: ProviderCredentialKind,
        apiKey: String? = nil,
        baseUrl: String? = nil,
        label: String? = nil
    ) {
        self.kind = kind
        self.apiKey = apiKey
        self.baseUrl = baseUrl
        self.label = label
    }
}

public struct ProviderTestResponse: Codable, Sendable {
    public let verifiedAt: Date
    public let model: String?
    public init(verifiedAt: Date, model: String? = nil) {
        self.verifiedAt = verifiedAt
        self.model = model
    }
}

// ─── LLM Preferences (HER-252) ───────────────────────────────────────────

/// HER-300 — Distinguishes server-managed default keys (`managed`) from
/// user-supplied API keys (`byok`). `managed` short-circuits the BYOK
/// credential lookup and routes through the shared Hermes gateway with a
/// LuminaVault-funded model; `byok` honours `UserProviderCredential` and
/// the full fallback chain.
public enum LLMBrainMode: String, Codable, Sendable, CaseIterable {
    case managed
    case byok
}

/// A single `(provider, model)` step in a user's fallback chain.
public struct ModelRouteDTO: Codable, Sendable, Hashable {
    public let provider: ProviderID
    public let model: String
    public init(provider: ProviderID, model: String) {
        self.provider = provider
        self.model = model
    }
}

public struct LLMPreferencesGetResponse: Codable, Sendable {
    public let mode: LLMBrainMode
    public let primaryProvider: ProviderID
    public let primaryModel: String
    public let fallbackChain: [ModelRouteDTO]
    public init(
        mode: LLMBrainMode = .managed,
        primaryProvider: ProviderID,
        primaryModel: String,
        fallbackChain: [ModelRouteDTO]
    ) {
        self.mode = mode
        self.primaryProvider = primaryProvider
        self.primaryModel = primaryModel
        self.fallbackChain = fallbackChain
    }

    private enum CodingKeys: String, CodingKey {
        case mode, primaryProvider, primaryModel, fallbackChain
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mode = try c.decodeIfPresent(LLMBrainMode.self, forKey: .mode) ?? .managed
        self.primaryProvider = try c.decode(ProviderID.self, forKey: .primaryProvider)
        self.primaryModel = try c.decode(String.self, forKey: .primaryModel)
        self.fallbackChain = try c.decode([ModelRouteDTO].self, forKey: .fallbackChain)
    }
}

public struct LLMPreferencesPutRequest: Codable, Sendable {
    public let mode: LLMBrainMode
    public let primaryProvider: ProviderID
    public let primaryModel: String
    public let fallbackChain: [ModelRouteDTO]
    public init(
        mode: LLMBrainMode = .managed,
        primaryProvider: ProviderID,
        primaryModel: String,
        fallbackChain: [ModelRouteDTO]
    ) {
        self.mode = mode
        self.primaryProvider = primaryProvider
        self.primaryModel = primaryModel
        self.fallbackChain = fallbackChain
    }

    private enum CodingKeys: String, CodingKey {
        case mode, primaryProvider, primaryModel, fallbackChain
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mode = try c.decodeIfPresent(LLMBrainMode.self, forKey: .mode) ?? .managed
        self.primaryProvider = try c.decode(ProviderID.self, forKey: .primaryProvider)
        self.primaryModel = try c.decode(String.self, forKey: .primaryModel)
        self.fallbackChain = try c.decode([ModelRouteDTO].self, forKey: .fallbackChain)
    }
}

// ─── SSE Fallback Notice (HER-252) ───────────────────────────────────────

/// Emitted on a streaming chat / query response when `RoutedLLMTransport`
/// fails over from one candidate to another. `reasonCode` is a stable
/// machine-readable tag; `userMessage` is a localized human string the
/// client can surface verbatim.
public struct ProviderFallbackNoticeDTO: Codable, Sendable, Equatable {
    public let originalProvider: ProviderID
    public let originalModel: String
    public let fallbackProvider: ProviderID
    public let fallbackModel: String
    public let reasonCode: String
    public let userMessage: String
    public init(
        originalProvider: ProviderID,
        originalModel: String,
        fallbackProvider: ProviderID,
        fallbackModel: String,
        reasonCode: String,
        userMessage: String
    ) {
        self.originalProvider = originalProvider
        self.originalModel = originalModel
        self.fallbackProvider = fallbackProvider
        self.fallbackModel = fallbackModel
        self.reasonCode = reasonCode
        self.userMessage = userMessage
    }
}

// ─── Billing (HER-185) ───────────────────────────────────────────────────

/// Subscription tier a user is currently entitled to, as resolved by the
/// server. Server-truth wins over local RevenueCat `CustomerInfo` whenever
/// both are available; the iOS `BillingService` reconciles them so the UI
/// reads a single source.
public enum UserTier: String, Codable, Sendable, CaseIterable {
    case trial
    case pro
    case ultimate
    case lapsed
    case archived
}

/// Response body for `GET /v1/auth/me/billing` — the server's authoritative
/// view of a user's tier + trial state, used by the iOS client to render
/// gating UI and reconcile against RevenueCat's local snapshot.
///
/// `tierOverride` is set when an admin has applied a manual override via
/// `PUT /v1/admin/users/{userID}/tier-override`; surface alongside `tier`
/// for QA / support workflows. `enforcementEnabled` reflects whether the
/// server is currently returning 402 on tier-gated endpoints (a global
/// kill-switch for safe rollout).
public struct MeBillingResponse: Codable, Sendable, Equatable {
    public let tier: UserTier
    public let tierOverride: String?
    public let inTrial: Bool
    public let daysRemaining: Int?
    public let enforcementEnabled: Bool
    public init(
        tier: UserTier,
        tierOverride: String? = nil,
        inTrial: Bool,
        daysRemaining: Int? = nil,
        enforcementEnabled: Bool
    ) {
        self.tier = tier
        self.tierOverride = tierOverride
        self.inTrial = inTrial
        self.daysRemaining = daysRemaining
        self.enforcementEnabled = enforcementEnabled
    }
}

/// One UTC day of measured usage for Settings → Subscription → Usage.
/// Metrics-only: these values are informational and do not imply quota
/// enforcement or overage billing.
public struct UsageDailyPointDTO: Codable, Sendable, Equatable {
    public let day: Date
    public let tokensIn: Int64
    public let tokensOut: Int64
    public let ttsCharacters: Int64
    public let compileRuns: Int64
    public let compileFiles: Int64

    public init(
        day: Date,
        tokensIn: Int64,
        tokensOut: Int64,
        ttsCharacters: Int64,
        compileRuns: Int64,
        compileFiles: Int64
    ) {
        self.day = day
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.ttsCharacters = ttsCharacters
        self.compileRuns = compileRuns
        self.compileFiles = compileFiles
    }
}

/// Response body for `GET /v1/auth/me/usage`.
public struct MeUsageResponse: Codable, Sendable, Equatable {
    public let tier: UserTier
    public let periodStart: Date
    public let periodEnd: Date
    public let generatedAt: Date
    public let storageBytes: Int64
    public let tokensIn: Int64
    public let tokensOut: Int64
    public let tokensTotal: Int64
    public let ttsCharacters: Int64
    public let compileRuns: Int64
    public let compileFiles: Int64
    public let daily: [UsageDailyPointDTO]

    public init(
        tier: UserTier,
        periodStart: Date,
        periodEnd: Date,
        generatedAt: Date,
        storageBytes: Int64,
        tokensIn: Int64,
        tokensOut: Int64,
        tokensTotal: Int64,
        ttsCharacters: Int64,
        compileRuns: Int64,
        compileFiles: Int64,
        daily: [UsageDailyPointDTO]
    ) {
        self.tier = tier
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.generatedAt = generatedAt
        self.storageBytes = storageBytes
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.tokensTotal = tokensTotal
        self.ttsCharacters = ttsCharacters
        self.compileRuns = compileRuns
        self.compileFiles = compileFiles
        self.daily = daily
    }
}

// ─── WebAuthn / Passkey DTOs (HER-216) ────────────────────────────────────
//
// Wire-format types for the four passkey routes:
//   POST /v1/auth/webauthn/register/begin
//   POST /v1/auth/webauthn/register/finish
//   POST /v1/auth/webauthn/authenticate/begin
//   POST /v1/auth/webauthn/authenticate/finish
//
// Binary fields use base64url (no padding) per WebAuthn spec. The
// server uses `swift-webauthn` types internally; these DTOs match the
// JSON shape so the client can construct/decode them without the
// `swift-webauthn` dependency.
//
// `options` blobs on the begin responses are passed through opaquely
// via `AnyJSONValue` — the client hands the raw structure to
// `ASAuthorizationPlatformPublicKeyCredentialProvider` and doesn't need
// to track every spec field.

public struct WebAuthnBeginRegistrationRequest: Codable, Sendable {
    public let username: String
    public let displayName: String?
    public init(username: String, displayName: String? = nil) {
        self.username = username
        self.displayName = displayName
    }
}

public struct WebAuthnBeginRegistrationResponse: Codable, Sendable {
    public let options: AnyJSONValue
    public init(options: AnyJSONValue) { self.options = options }
}

public struct WebAuthnAttestationResponseDTO: Codable, Sendable {
    public let attestationObject: String // base64url
    public let clientDataJSON: String    // base64url
    public init(attestationObject: String, clientDataJSON: String) {
        self.attestationObject = attestationObject
        self.clientDataJSON = clientDataJSON
    }
}

public struct WebAuthnRegistrationCredentialDTO: Codable, Sendable {
    public let id: String        // base64url credential ID
    public let rawId: String     // base64url credential ID (raw bytes)
    public let type: String      // "public-key"
    public let response: WebAuthnAttestationResponseDTO

    public init(
        id: String,
        rawId: String,
        type: String = "public-key",
        response: WebAuthnAttestationResponseDTO
    ) {
        self.id = id
        self.rawId = rawId
        self.type = type
        self.response = response
    }
}

public struct WebAuthnFinishRegistrationRequest: Codable, Sendable {
    public let username: String
    public let credentialCreationData: WebAuthnRegistrationCredentialDTO
    public init(username: String, credentialCreationData: WebAuthnRegistrationCredentialDTO) {
        self.username = username
        self.credentialCreationData = credentialCreationData
    }
}

public struct WebAuthnFinishRegistrationResponse: Codable, Sendable {
    public let credentialID: String
    public init(credentialID: String) { self.credentialID = credentialID }
}

public struct WebAuthnBeginAuthenticationRequest: Codable, Sendable {
    public let username: String
    public init(username: String) { self.username = username }
}

public struct WebAuthnBeginAuthenticationResponse: Codable, Sendable {
    public let options: AnyJSONValue
    public init(options: AnyJSONValue) { self.options = options }
}

public struct WebAuthnAssertionResponseDTO: Codable, Sendable {
    public let authenticatorData: String // base64url
    public let clientDataJSON: String    // base64url
    public let signature: String         // base64url
    public let userHandle: String?       // base64url, optional

    public init(
        authenticatorData: String,
        clientDataJSON: String,
        signature: String,
        userHandle: String? = nil
    ) {
        self.authenticatorData = authenticatorData
        self.clientDataJSON = clientDataJSON
        self.signature = signature
        self.userHandle = userHandle
    }
}

public struct WebAuthnAuthenticationCredentialDTO: Codable, Sendable {
    public let id: String
    public let rawId: String
    public let type: String
    public let response: WebAuthnAssertionResponseDTO

    public init(
        id: String,
        rawId: String,
        type: String = "public-key",
        response: WebAuthnAssertionResponseDTO
    ) {
        self.id = id
        self.rawId = rawId
        self.type = type
        self.response = response
    }
}

public struct WebAuthnFinishAuthenticationRequest: Codable, Sendable {
    public let username: String
    public let credential: WebAuthnAuthenticationCredentialDTO
    public init(username: String, credential: WebAuthnAuthenticationCredentialDTO) {
        self.username = username
        self.credential = credential
    }
}

// Settings — list and revoke enrolled passkeys for the authenticated user.

public struct WebAuthnCredentialSummaryDTO: Codable, Sendable, Identifiable {
    public let id: String        // base64url credential ID
    public let createdAt: Date
    public let lastUsedAt: Date?
    public let nickname: String?

    public init(
        id: String,
        createdAt: Date,
        lastUsedAt: Date? = nil,
        nickname: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.nickname = nickname
    }
}

public struct WebAuthnCredentialListResponse: Codable, Sendable {
    public let credentials: [WebAuthnCredentialSummaryDTO]
    public init(credentials: [WebAuthnCredentialSummaryDTO]) {
        self.credentials = credentials
    }
}

// MARK: - Hermes self-update (HER-330)
//
// Wire types for the owner-triggered "Update Hermes" flow. The iOS app calls
// `POST /v1/system/hermes/update` (owner JWT + admin-token gated), the backend
// runs a detached, blue-green update job over the Docker CLI, and the client
// observes progress over an SSE stream of `HermesUpdateEvent` (and/or by polling
// the job status). See `LuminaVaultServer/Sources/App/System/`.

/// Identifies one step in the Hermes update pipeline. Ordering is the
/// execution order; `rollback` runs only on failure at/after `swapCentral`.
public enum HermesUpdateStepID: String, Codable, Sendable, CaseIterable {
    case preflight
    case pullImage
    case verifyImage
    case snapshotCurrent
    case swapCentral
    case healthCheckCentral
    case reprovisionTenants
    case verifyTenants
    case promote
    case rollback
}

public enum HermesUpdateStepState: String, Codable, Sendable {
    case pending
    case running
    case succeeded
    case failed
    case skipped
}

/// A single step's live state. `detail` carries a short human-readable status
/// line (e.g. "pulled ghcr.io/…@sha256:abc") surfaced under the step row.
public struct HermesUpdateStep: Codable, Sendable, Equatable, Identifiable {
    public let id: HermesUpdateStepID
    public let state: HermesUpdateStepState
    public let detail: String?
    public let startedAt: Date?
    public let finishedAt: Date?
    public init(
        id: HermesUpdateStepID,
        state: HermesUpdateStepState,
        detail: String? = nil,
        startedAt: Date? = nil,
        finishedAt: Date? = nil
    ) {
        self.id = id
        self.state = state
        self.detail = detail
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
}

public enum HermesUpdateJobState: String, Codable, Sendable {
    case running
    case succeeded
    case failed
    /// Update failed but the previous version was successfully restored.
    case rolledBack
}

/// Full snapshot of an update job. Returned by the poll/status and reconnect
/// endpoints, and as the terminal `.done` SSE event payload.
public struct HermesUpdateJobStatus: Codable, Sendable, Equatable, Identifiable {
    public let jobID: UUID
    public let state: HermesUpdateJobState
    public let steps: [HermesUpdateStep]
    /// Image ref/version running before the update (the rollback target).
    public let fromVersion: String?
    /// Image ref/version this job is moving to.
    public let toVersion: String?
    public let errorMessage: String?
    public let startedAt: Date
    public let updatedAt: Date
    public var id: UUID { jobID }
    public init(
        jobID: UUID,
        state: HermesUpdateJobState,
        steps: [HermesUpdateStep],
        fromVersion: String? = nil,
        toVersion: String? = nil,
        errorMessage: String? = nil,
        startedAt: Date,
        updatedAt: Date
    ) {
        self.jobID = jobID
        self.state = state
        self.steps = steps
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.errorMessage = errorMessage
        self.startedAt = startedAt
        self.updatedAt = updatedAt
    }
}

/// SSE frame for the update stream. Discriminated by a top-level `type` field,
/// matching `QueryStreamEvent` / `KBCompileProgressEvent`. Decoded on the client
/// with `JSONDecoder.hvDefault` (`.iso8601` dates).
public enum HermesUpdateEvent: Codable, Sendable, Equatable {
    /// A step changed state. Emitted on every transition.
    case step(HermesUpdateStep)
    /// Job-level state change.
    case status(HermesUpdateJobState)
    /// Terminal event carrying the final snapshot.
    case done(HermesUpdateJobStatus)
    /// Stream-level error (distinct from a step failure inside `.done`).
    case error(String)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum EventType: String, Codable {
        case step, status, done, error
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(EventType.self, forKey: .type)
        switch type {
        case .step: self = .step(try c.decode(HermesUpdateStep.self, forKey: .payload))
        case .status: self = .status(try c.decode(HermesUpdateJobState.self, forKey: .payload))
        case .done: self = .done(try c.decode(HermesUpdateJobStatus.self, forKey: .payload))
        case .error: self = .error(try c.decode(String.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .step(let s):
            try c.encode(EventType.step, forKey: .type)
            try c.encode(s, forKey: .payload)
        case .status(let st):
            try c.encode(EventType.status, forKey: .type)
            try c.encode(st, forKey: .payload)
        case .done(let snapshot):
            try c.encode(EventType.done, forKey: .type)
            try c.encode(snapshot, forKey: .payload)
        case .error(let message):
            try c.encode(EventType.error, forKey: .type)
            try c.encode(message, forKey: .payload)
        }
    }
}

/// Request body for `POST /v1/system/hermes/update`. `targetTag` defaults to
/// the server's configured release channel (e.g. `latest`) when omitted.
public struct StartHermesUpdateRequest: Codable, Sendable {
    public let targetTag: String?
    public init(targetTag: String? = nil) {
        self.targetTag = targetTag
    }
}

/// Response body for `POST /v1/system/hermes/update`.
public struct StartHermesUpdateResponse: Codable, Sendable {
    public let jobID: UUID
    public let state: HermesUpdateJobState
    public init(jobID: UUID, state: HermesUpdateJobState) {
        self.jobID = jobID
        self.state = state
    }
}

/// Response body for `GET /v1/system/hermes/version`. Describes the running
/// central Hermes image and, best-effort, the newest tag available in the
/// registry so the client can show "update available".
public struct HermesVersionInfo: Codable, Sendable, Equatable {
    /// Full image reference currently running (e.g. `ghcr.io/.../luminavault-hermes:stable`).
    public let currentRef: String
    /// Resolved digest of the running image (e.g. `sha256:…`), if known.
    public let currentDigest: String?
    /// Short display label for the running version (tag or short digest).
    public let currentLabel: String
    /// Newest tag/label available to pull, when the server could resolve it.
    public let availableLabel: String?
    /// `true` when `availableLabel` differs from what's running.
    public let updateAvailable: Bool
    /// When the central image was last updated by this system, if recorded.
    public let lastUpdatedAt: Date?
    public init(
        currentRef: String,
        currentDigest: String? = nil,
        currentLabel: String,
        availableLabel: String? = nil,
        updateAvailable: Bool = false,
        lastUpdatedAt: Date? = nil
    ) {
        self.currentRef = currentRef
        self.currentDigest = currentDigest
        self.currentLabel = currentLabel
        self.availableLabel = availableLabel
        self.updateAvailable = updateAvailable
        self.lastUpdatedAt = lastUpdatedAt
    }
}

// MARK: - "Feed Your Brain" bulk import (HER-105)
//
// These cross the wire between client and server for the import flow. Encoded
// and decoded as plain camelCase JSON (the server reads them with the default
// request decoder — do NOT encode with `.convertToSnakeCase` client-side).

public struct ImportCreateRequest: Codable, Sendable {
    public let sourceType: String
    public let urls: [String]
    public init(sourceType: String, urls: [String]) {
        self.sourceType = sourceType
        self.urls = urls
    }
}

public struct ImportFilesRequest: Codable, Sendable {
    public let sourceType: String
    /// ids returned by `POST /v1/vault/files` (already-uploaded photos /
    /// documents / EventKit-rendered notes).
    public let vaultFileIds: [UUID]
    public init(sourceType: String, vaultFileIds: [UUID]) {
        self.sourceType = sourceType
        self.vaultFileIds = vaultFileIds
    }
}

public struct ImportCreateResponse: Codable, Sendable {
    public let sessionId: UUID
    public let status: String
    public let total: Int
    public let staged: Int
    public let skipped: Int
    public init(sessionId: UUID, status: String, total: Int, staged: Int, skipped: Int) {
        self.sessionId = sessionId
        self.status = status
        self.total = total
        self.staged = staged
        self.skipped = skipped
    }
}

public struct ImportItemDTO: Codable, Sendable {
    public let id: UUID
    public let url: String?
    public let title: String?
    /// existing Space slug, `new:<Name>`, or `imported`.
    public let proposedSpace: String?
    public let status: String
    public init(id: UUID, url: String?, title: String?, proposedSpace: String?, status: String) {
        self.id = id
        self.url = url
        self.title = title
        self.proposedSpace = proposedSpace
        self.status = status
    }
}

public struct ImportStatusResponse: Codable, Sendable {
    public let id: UUID
    public let sourceType: String
    public let status: String
    public let total: Int
    public let staged: Int
    public let items: [ImportItemDTO]
    public init(id: UUID, sourceType: String, status: String, total: Int, staged: Int, items: [ImportItemDTO]) {
        self.id = id
        self.sourceType = sourceType
        self.status = status
        self.total = total
        self.staged = staged
        self.items = items
    }
}

public struct ImportApproveRequest: Codable, Sendable {
    /// itemId → `slug | new:Name | imported`. Absent items keep their proposal.
    public let overrides: [String: String]?
    public init(overrides: [String: String]? = nil) {
        self.overrides = overrides
    }
}

public struct ImportApproveResponse: Codable, Sendable {
    public let sessionId: UUID
    public let status: String
    public let filed: Int
    public let memoriesIngested: Int
    public init(sessionId: UUID, status: String, filed: Int, memoriesIngested: Int) {
        self.sessionId = sessionId
        self.status = status
        self.filed = filed
        self.memoriesIngested = memoriesIngested
    }
}

// ─── Plugin Domain (HER-43, Slice 1: Plugin Foundation) ──────────────────
//
// Declarative plugins: a manifest in the first-party catalog wires into an
// existing server registry (connectors only in this slice). No third-party
// code runs. Per-tenant install config (e.g. an API token) is sealed at rest
// via SecretBox and never echoed in plaintext — responses carry `hasConfig`
// only, matching the Hermes-gateway contract.

public enum PluginCategory: String, Codable, Sendable, CaseIterable {
    case connector
    case skill
    case memory
    case export
    case ui
    case theme
    /// HER-54 (Slice 1) — capture plugins that hook into the capture pipeline
    /// to transform/enrich a captured item before it is persisted.
    case capture
}

/// Which server capability a plugin binds to. Only `connector` is wired in
/// this slice; the others are reserved so the schema is stable across slices.
public enum PluginCapabilityKind: String, Codable, Sendable, CaseIterable {
    case connector
    case skill
    case memory
    /// HER-54 (Slice 1) — binds to a `CaptureHook` run by the server's capture
    /// pipeline at a declared `CaptureHookPoint` (e.g. post-enrichment).
    case captureHook
}

public enum PluginConfigFieldKind: String, Codable, Sendable, CaseIterable {
    case text
    case secret
    case url
}

public struct PluginConfigField: Codable, Sendable, Hashable {
    public let key: String
    public let label: String
    public let placeholder: String?
    public let kind: PluginConfigFieldKind
    public let isRequired: Bool

    public init(
        key: String,
        label: String,
        placeholder: String? = nil,
        kind: PluginConfigFieldKind,
        isRequired: Bool = true
    ) {
        self.key = key
        self.label = label
        self.placeholder = placeholder
        self.kind = kind
        self.isRequired = isRequired
    }
}

public enum PluginInstallStatus: String, Codable, Sendable, CaseIterable {
    case enabled
    case disabled
}

/// One first-party catalog entry. `slug` is the stable id used by installs.
public struct PluginCatalogEntryDTO: Codable, Sendable, Identifiable, Equatable {
    public var id: String { slug }
    public let slug: String
    public let name: String
    public let summary: String
    public let description: String
    public let category: PluginCategory
    public let capabilityKind: PluginCapabilityKind
    public let iconSlug: String
    public let version: String
    public let publisher: String
    public let verified: Bool
    public let configFields: [PluginConfigField]

    public init(
        slug: String,
        name: String,
        summary: String,
        description: String,
        category: PluginCategory,
        capabilityKind: PluginCapabilityKind,
        iconSlug: String,
        version: String,
        publisher: String,
        verified: Bool,
        configFields: [PluginConfigField]
    ) {
        self.slug = slug
        self.name = name
        self.summary = summary
        self.description = description
        self.category = category
        self.capabilityKind = capabilityKind
        self.iconSlug = iconSlug
        self.version = version
        self.publisher = publisher
        self.verified = verified
        self.configFields = configFields
    }
}

public struct PluginCatalogListResponse: Codable, Sendable {
    public let items: [PluginCatalogEntryDTO]
    public init(items: [PluginCatalogEntryDTO]) { self.items = items }
}

/// A tenant's install of a catalog plugin. Config is never echoed — only
/// `hasConfig` reports whether a sealed config exists.
public struct PluginInstallDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let pluginSlug: String
    public let status: PluginInstallStatus
    public let hasConfig: Bool
    public let createdAt: Date?
    public let lastSyncAt: Date?

    public init(
        id: UUID,
        pluginSlug: String,
        status: PluginInstallStatus,
        hasConfig: Bool,
        createdAt: Date? = nil,
        lastSyncAt: Date? = nil
    ) {
        self.id = id
        self.pluginSlug = pluginSlug
        self.status = status
        self.hasConfig = hasConfig
        self.createdAt = createdAt
        self.lastSyncAt = lastSyncAt
    }
}

public struct PluginInstallsListResponse: Codable, Sendable {
    public let items: [PluginInstallDTO]
    public init(items: [PluginInstallDTO]) { self.items = items }
}

public struct InstallPluginRequest: Codable, Sendable {
    public let pluginSlug: String
    public let config: [String: String]
    public init(pluginSlug: String, config: [String: String]) {
        self.pluginSlug = pluginSlug
        self.config = config
    }
}

/// Patch an install: replace config and/or flip enabled/disabled. Both fields
/// optional so the client can send either independently.
public struct UpdatePluginInstallRequest: Codable, Sendable {
    public let config: [String: String]?
    public let status: PluginInstallStatus?
    public init(config: [String: String]? = nil, status: PluginInstallStatus? = nil) {
        self.config = config
        self.status = status
    }
}

/// Result of running a connector install's sync. Items are staged into the
/// reserved `imported` inbox via the existing import pipeline; the returned
/// `sessionId` is a standard import session the client polls / approves.
public struct PluginSyncResponse: Codable, Sendable {
    public let installId: UUID
    public let sessionId: UUID
    public let status: String
    public let total: Int
    public let staged: Int
    public let skipped: Int
    public init(installId: UUID, sessionId: UUID, status: String, total: Int, staged: Int, skipped: Int) {
        self.installId = installId
        self.sessionId = sessionId
        self.status = status
        self.total = total
        self.staged = staged
        self.skipped = skipped
    }
}

// ─── Reminders (HER-Reminders) ─────────────────────────────────────────────
// A user-scheduled timed message. When `fireAt` arrives, the server fires an
// APNS push (category `reminder`) and stamps `firedAt`. One-shot unless
// `recurrenceCron` is set, in which case `fireAt` is advanced to the next
// matching minute after each fire.

public struct ReminderDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let body: String
    public let fireAt: Date
    /// Optional cron expression for recurring reminders (nil = one-shot).
    public let recurrenceCron: String?
    /// Set once the reminder has fired at least once; nil while pending.
    public let firedAt: Date?
    public let createdAt: Date
    public init(
        id: UUID,
        title: String,
        body: String,
        fireAt: Date,
        recurrenceCron: String? = nil,
        firedAt: Date? = nil,
        createdAt: Date
    ) {
        self.id = id; self.title = title; self.body = body
        self.fireAt = fireAt; self.recurrenceCron = recurrenceCron
        self.firedAt = firedAt; self.createdAt = createdAt
    }
}

public struct ReminderListResponse: Codable, Sendable {
    public let reminders: [ReminderDTO]
    public let nextCursor: String?
    public init(reminders: [ReminderDTO], nextCursor: String? = nil) {
        self.reminders = reminders; self.nextCursor = nextCursor
    }
}

public struct ReminderCreateRequest: Codable, Sendable {
    public let title: String
    public let body: String
    public let fireAt: Date
    public let recurrenceCron: String?
    public init(title: String, body: String, fireAt: Date, recurrenceCron: String? = nil) {
        self.title = title; self.body = body
        self.fireAt = fireAt; self.recurrenceCron = recurrenceCron
    }
}

public struct ReminderPatchRequest: Codable, Sendable {
    public let title: String?
    public let body: String?
    public let fireAt: Date?
    public let recurrenceCron: String?
    public init(title: String? = nil, body: String? = nil, fireAt: Date? = nil, recurrenceCron: String? = nil) {
        self.title = title; self.body = body
        self.fireAt = fireAt; self.recurrenceCron = recurrenceCron
    }
}

// ─── Projects (HER-Projects) ───────────────────────────────────────────────
// A named container that groups Todos. Tenant-scoped.

public struct ProjectDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String?
    public let archived: Bool
    /// Number of todos linked to this project (nil when not computed).
    public let todoCount: Int?
    public let createdAt: Date
    public init(
        id: UUID,
        name: String,
        description: String? = nil,
        archived: Bool = false,
        todoCount: Int? = nil,
        createdAt: Date
    ) {
        self.id = id; self.name = name; self.description = description
        self.archived = archived; self.todoCount = todoCount; self.createdAt = createdAt
    }
}

public struct ProjectListResponse: Codable, Sendable {
    public let projects: [ProjectDTO]
    public let nextCursor: String?
    public init(projects: [ProjectDTO], nextCursor: String? = nil) {
        self.projects = projects; self.nextCursor = nextCursor
    }
}

public struct ProjectCreateRequest: Codable, Sendable {
    public let name: String
    public let description: String?
    public init(name: String, description: String? = nil) {
        self.name = name; self.description = description
    }
}

public struct ProjectPatchRequest: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let archived: Bool?
    public init(name: String? = nil, description: String? = nil, archived: Bool? = nil) {
        self.name = name; self.description = description; self.archived = archived
    }
}

// ─── Todos (HER-Todos — user to-do tasks) ──────────────────────────────────
// A user-owned to-do item. Distinct from the background-job-shaped `TaskDTO`
// above (which tracks server operations). The Home "Tasks" card surfaces
// these. Optionally linked to a Project.

public struct TodoDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let done: Bool
    public let dueAt: Date?
    public let projectID: UUID?
    public let createdAt: Date
    public init(
        id: UUID,
        title: String,
        done: Bool = false,
        dueAt: Date? = nil,
        projectID: UUID? = nil,
        createdAt: Date
    ) {
        self.id = id; self.title = title; self.done = done
        self.dueAt = dueAt; self.projectID = projectID; self.createdAt = createdAt
    }
}

public struct TodoListResponse: Codable, Sendable {
    public let todos: [TodoDTO]
    public let nextCursor: String?
    public init(todos: [TodoDTO], nextCursor: String? = nil) {
        self.todos = todos; self.nextCursor = nextCursor
    }
}

public struct TodoCreateRequest: Codable, Sendable {
    public let title: String
    public let dueAt: Date?
    public let projectID: UUID?
    public init(title: String, dueAt: Date? = nil, projectID: UUID? = nil) {
        self.title = title; self.dueAt = dueAt; self.projectID = projectID
    }
}

public struct TodoPatchRequest: Codable, Sendable {
    public let title: String?
    public let done: Bool?
    public let dueAt: Date?
    public let projectID: UUID?
    public init(title: String? = nil, done: Bool? = nil, dueAt: Date? = nil, projectID: UUID? = nil) {
        self.title = title; self.done = done; self.dueAt = dueAt; self.projectID = projectID
    }
}

// ─── Usage analytics (HER-Insights) ────────────────────────────────────────
// Aggregated per-tenant usage for the current billing period. Sourced from
// the usage meter (LLM tokens) + embedding usage counters.

public struct UsageSummaryResponse: Codable, Sendable {
    public let llmTokensIn: Int
    public let llmTokensOut: Int
    public let embeddingTokens: Int
    public let sessionsCount: Int
    public let estimatedCostCents: Int
    public let periodStart: Date
    public let periodEnd: Date
    public init(
        llmTokensIn: Int,
        llmTokensOut: Int,
        embeddingTokens: Int,
        sessionsCount: Int,
        estimatedCostCents: Int,
        periodStart: Date,
        periodEnd: Date
    ) {
        self.llmTokensIn = llmTokensIn; self.llmTokensOut = llmTokensOut
        self.embeddingTokens = embeddingTokens; self.sessionsCount = sessionsCount
        self.estimatedCostCents = estimatedCostCents
        self.periodStart = periodStart; self.periodEnd = periodEnd
    }
}

// ─── Home aggregate (HER-Home) ─────────────────────────────────────────────
// One-shot counts powering the Home dashboard cards, plus the active Hermes
// profile. Avoids N round-trips on the landing screen.

public struct HomeSummaryResponse: Codable, Sendable {
    public let skillsCount: Int
    public let jobsCount: Int
    public let remindersCount: Int
    public let todosCount: Int
    public let projectsCount: Int
    public let insightsCount: Int
    public let activeProfileName: String?
    public let activeProfileSlug: String?
    public init(
        skillsCount: Int,
        jobsCount: Int,
        remindersCount: Int,
        todosCount: Int,
        projectsCount: Int,
        insightsCount: Int,
        activeProfileName: String? = nil,
        activeProfileSlug: String? = nil
    ) {
        self.skillsCount = skillsCount; self.jobsCount = jobsCount
        self.remindersCount = remindersCount; self.todosCount = todosCount
        self.projectsCount = projectsCount; self.insightsCount = insightsCount
        self.activeProfileName = activeProfileName; self.activeProfileSlug = activeProfileSlug
    }
}

// MARK: - Kanban (native boards; LuminaVault is the system of record)

public enum CardPriority: String, Codable, Sendable, CaseIterable {
    case low, medium, high, urgent
}

public struct CardDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let columnID: UUID
    public let title: String
    public let body: String?
    public let priority: CardPriority?
    public let dueAt: Date?
    public let rank: String
    public let updatedAt: Date?
    /// Card→Job promotion config. Non-nil once the card has been promoted
    /// (carries `jobSlug`/`promotedAt`) or staged with promotion fields.
    public let jobConfig: CardJobConfigDTO?

    public init(id: UUID, columnID: UUID, title: String, body: String?,
                priority: CardPriority?, dueAt: Date?, rank: String, updatedAt: Date?,
                jobConfig: CardJobConfigDTO? = nil) {
        self.id = id; self.columnID = columnID; self.title = title; self.body = body
        self.priority = priority; self.dueAt = dueAt; self.rank = rank; self.updatedAt = updatedAt
        self.jobConfig = jobConfig
    }
}

/// Structured config for a card promoted to a scheduled Job (card→Job).
/// Mirrors the server's `CardJobConfig`. Recurring jobs use `cron`; one-shot
/// jobs use `runAt`. `jobSlug`/`promotedAt` are server-filled after promotion.
public struct CardJobConfigDTO: Codable, Sendable, Equatable {
    public let source: String
    public let cron: String?
    public let runAt: Date?
    public let domain: String?
    public let prompt: String?
    public let spaceID: UUID?
    public let jobSlug: String?
    public let promotedAt: Date?

    public init(source: String = "vault", cron: String? = nil, runAt: Date? = nil,
                domain: String? = nil, prompt: String? = nil, spaceID: UUID? = nil,
                jobSlug: String? = nil, promotedAt: Date? = nil) {
        self.source = source; self.cron = cron; self.runAt = runAt
        self.domain = domain; self.prompt = prompt; self.spaceID = spaceID
        self.jobSlug = jobSlug; self.promotedAt = promotedAt
    }
}

/// Body for `POST /v1/cards/:cardID/promote`. Optional — when omitted the
/// server promotes using config already on the card (`CardDTO.jobConfig`).
/// When present these fields are written onto the card before authoring, so a
/// card can be promoted in a single call.
public struct CardPromoteRequest: Codable, Sendable {
    public let cron: String?
    public let runAt: Date?
    public let domain: String?
    public let prompt: String?
    public let spaceID: UUID?

    public init(cron: String? = nil, runAt: Date? = nil, domain: String? = nil,
                prompt: String? = nil, spaceID: UUID? = nil) {
        self.cron = cron; self.runAt = runAt; self.domain = domain
        self.prompt = prompt; self.spaceID = spaceID
    }
}

public struct ColumnDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let rank: String
    public let cards: [CardDTO]   // pre-sorted by rank ascending

    public init(id: UUID, title: String, rank: String, cards: [CardDTO]) {
        self.id = id; self.title = title; self.rank = rank; self.cards = cards
    }
}

public struct BoardDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let version: Int64
    public let columns: [ColumnDTO]   // pre-sorted by rank ascending

    public init(id: UUID, title: String, version: Int64, columns: [ColumnDTO]) {
        self.id = id; self.title = title; self.version = version; self.columns = columns
    }
}

public struct BoardSummaryDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let version: Int64
    public let columnCount: Int
    public let cardCount: Int
    public let updatedAt: Date?

    public init(id: UUID, title: String, version: Int64, columnCount: Int, cardCount: Int, updatedAt: Date?) {
        self.id = id; self.title = title; self.version = version
        self.columnCount = columnCount; self.cardCount = cardCount; self.updatedAt = updatedAt
    }
}

public struct BoardVersionDTO: Codable, Sendable, Equatable {
    public let version: Int64
    public init(version: Int64) { self.version = version }
}

// Requests
public struct BoardCreateRequest: Codable, Sendable {
    public let title: String
    public init(title: String) { self.title = title }
}
public struct BoardPatchRequest: Codable, Sendable {
    public let title: String?
    public let archived: Bool?
    public init(title: String? = nil, archived: Bool? = nil) { self.title = title; self.archived = archived }
}
public struct ColumnCreateRequest: Codable, Sendable {
    public let title: String
    public init(title: String) { self.title = title }
}
public struct ColumnPatchRequest: Codable, Sendable {
    public let title: String
    public init(title: String) { self.title = title }
}
public struct ColumnReorderRequest: Codable, Sendable {
    public let columnID: UUID
    public let beforeID: UUID?
    public let afterID: UUID?
    public init(columnID: UUID, beforeID: UUID? = nil, afterID: UUID? = nil) {
        self.columnID = columnID; self.beforeID = beforeID; self.afterID = afterID
    }
}
public struct CardCreateRequest: Codable, Sendable {
    public let columnID: UUID
    public let title: String
    public let body: String?
    public let priority: CardPriority?
    public let dueAt: Date?
    public init(columnID: UUID, title: String, body: String? = nil,
                priority: CardPriority? = nil, dueAt: Date? = nil) {
        self.columnID = columnID; self.title = title; self.body = body
        self.priority = priority; self.dueAt = dueAt
    }
}
public struct CardPatchRequest: Codable, Sendable {
    public let title: String?
    public let body: String?
    public let priority: CardPriority?
    public let dueAt: Date?
    public init(title: String? = nil, body: String? = nil, priority: CardPriority? = nil, dueAt: Date? = nil) {
        self.title = title; self.body = body; self.priority = priority; self.dueAt = dueAt
    }
}
public struct CardMoveRequest: Codable, Sendable {
    public let toColumnID: UUID
    public let beforeID: UUID?
    public let afterID: UUID?
    public init(toColumnID: UUID, beforeID: UUID? = nil, afterID: UUID? = nil) {
        self.toColumnID = toColumnID; self.beforeID = beforeID; self.afterID = afterID
    }
}
