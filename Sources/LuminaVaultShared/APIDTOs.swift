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
    public init(userId: UUID, email: String, username: String, isVerified: Bool, privacyNoCNOrigin: Bool, contextRouting: Bool) {
        self.userId = userId; self.email = email; self.username = username
        self.isVerified = isVerified; self.privacyNoCNOrigin = privacyNoCNOrigin
        self.contextRouting = contextRouting
    }
}

public struct UpdatePrivacyRequest: Codable {
    public let privacyNoCNOrigin: Bool?
    public let contextRouting: Bool?
    public init(privacyNoCNOrigin: Bool?, contextRouting: Bool?) {
        self.privacyNoCNOrigin = privacyNoCNOrigin; self.contextRouting = contextRouting
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

public struct MemoryDTO: Codable, Sendable {
    public let id: UUID
    public let content: String
    public let tags: [String]
    public let createdAt: Date?
    /// HER-207 geo anchor (see `MemoryUpsertRequest` for field semantics).
    public let lat: Double?
    public let lng: Double?
    public let accuracyM: Double?
    public let placeName: String?
    public init(
        id: UUID,
        content: String,
        tags: [String],
        createdAt: Date? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        accuracyM: Double? = nil,
        placeName: String? = nil
    ) {
        self.id = id
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.lat = lat
        self.lng = lng
        self.accuracyM = accuracyM
        self.placeName = placeName
    }
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
    public init(content: String? = nil, tags: [String]? = nil) {
        self.content = content; self.tags = tags
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
// Read-only derived graph view of a tenant's memories. Nodes are memories;
// edges are derived on read from shared tags + pgvector cosine similarity.
// No edges are persisted server-side in v1.

public struct MemoryGraphNodeDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let tags: [String]
    public let createdAt: Date
    public let score: Double
    public init(id: UUID, title: String, tags: [String], createdAt: Date, score: Double) {
        self.id = id; self.title = title; self.tags = tags
        self.createdAt = createdAt; self.score = score
    }
}

public enum MemoryEdgeKindDTO: String, Codable, Sendable {
    case tag
    case semantic
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

    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum EventType: String, Codable {
        case source, token, summary
        case followUps = "follow_ups"
        case done, error, fallback
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
        }
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

public struct VaultFileDTO: Codable, Sendable {
    public let id: UUID
    public let path: String
    public let contentType: String
    public let sizeBytes: Int64
    public let sha256: String
    public let spaceId: UUID?
    public let createdAt: Date?
    public let updatedAt: Date?
    public init(id: UUID, path: String, contentType: String, sizeBytes: Int64, sha256: String, spaceId: UUID? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id; self.path = path; self.contentType = contentType
        self.sizeBytes = sizeBytes; self.sha256 = sha256; self.spaceId = spaceId
        self.createdAt = createdAt; self.updatedAt = updatedAt
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
    public init(signupCompleted: Bool, signupCompletedAt: Date?, emailVerifiedCompleted: Bool, emailVerifiedCompletedAt: Date?, soulConfiguredCompleted: Bool, soulConfiguredCompletedAt: Date?, firstCaptureCompleted: Bool, firstCaptureCompletedAt: Date?, firstKBCompileCompleted: Bool, firstKBCompileCompletedAt: Date?, firstQueryCompleted: Bool, firstQueryCompletedAt: Date?) {
        self.signupCompleted = signupCompleted; self.signupCompletedAt = signupCompletedAt
        self.emailVerifiedCompleted = emailVerifiedCompleted; self.emailVerifiedCompletedAt = emailVerifiedCompletedAt
        self.soulConfiguredCompleted = soulConfiguredCompleted; self.soulConfiguredCompletedAt = soulConfiguredCompletedAt
        self.firstCaptureCompleted = firstCaptureCompleted; self.firstCaptureCompletedAt = firstCaptureCompletedAt
        self.firstKBCompileCompleted = firstKBCompileCompleted; self.firstKBCompileCompletedAt = firstKBCompileCompletedAt
        self.firstQueryCompleted = firstQueryCompleted; self.firstQueryCompletedAt = firstQueryCompletedAt
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
    public init(
        signupCompleted: Bool? = nil,
        emailVerifiedCompleted: Bool? = nil,
        soulConfiguredCompleted: Bool? = nil,
        firstCaptureCompleted: Bool? = nil,
        firstKBCompileCompleted: Bool? = nil,
        firstQueryCompleted: Bool? = nil
    ) {
        self.signupCompleted = signupCompleted
        self.emailVerifiedCompleted = emailVerifiedCompleted
        self.soulConfiguredCompleted = soulConfiguredCompleted
        self.firstCaptureCompleted = firstCaptureCompleted
        self.firstKBCompileCompleted = firstKBCompileCompleted
        self.firstQueryCompleted = firstQueryCompleted
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

public struct KBCompileResponse: Codable, Sendable {
    public let memoriesIngested: Int
    public let memoriesUpdated: Int?
    public let durationMs: Int?
    public init(memoriesIngested: Int, memoriesUpdated: Int? = nil, durationMs: Int? = nil) {
        self.memoriesIngested = memoriesIngested
        self.memoriesUpdated = memoriesUpdated
        self.durationMs = durationMs
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

// ─── Hermes Gateways (HER-241) ──────────────────────────────────────────

public enum HermesGatewayID: String, Codable, Sendable, CaseIterable {
    case telegram
    case discord
    case slack
    case whatsapp
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

    public init(
        id: HermesGatewayID,
        displayName: String,
        iconSlug: String,
        description: String,
        requiredFields: [HermesGatewayField],
        status: HermesGatewayStatus,
        hasConfig: Bool,
        verifiedAt: Date? = nil,
        lastFailureCode: String? = nil
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

public struct SkillRunDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let status: SkillRunStatus
    public let error: String?
    public let modelUsed: String?
    public let mtokIn: Int?
    public let mtokOut: Int?

    public init(
        id: UUID,
        startedAt: Date,
        endedAt: Date? = nil,
        status: SkillRunStatus,
        error: String? = nil,
        modelUsed: String? = nil,
        mtokIn: Int? = nil,
        mtokOut: Int? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.status = status
        self.error = error
        self.modelUsed = modelUsed
        self.mtokIn = mtokIn
        self.mtokOut = mtokOut
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
    public let primaryProvider: ProviderID
    public let primaryModel: String
    public let fallbackChain: [ModelRouteDTO]
    public init(
        primaryProvider: ProviderID,
        primaryModel: String,
        fallbackChain: [ModelRouteDTO]
    ) {
        self.primaryProvider = primaryProvider
        self.primaryModel = primaryModel
        self.fallbackChain = fallbackChain
    }
}

public struct LLMPreferencesPutRequest: Codable, Sendable {
    public let primaryProvider: ProviderID
    public let primaryModel: String
    public let fallbackChain: [ModelRouteDTO]
    public init(
        primaryProvider: ProviderID,
        primaryModel: String,
        fallbackChain: [ModelRouteDTO]
    ) {
        self.primaryProvider = primaryProvider
        self.primaryModel = primaryModel
        self.fallbackChain = fallbackChain
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
