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
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
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
    public init(email: String) {
        self.email = email
    }
}

public struct OAuthExchangeRequest: Codable, Sendable {
    public let idToken: String
    public init(idToken: String) {
        self.idToken = idToken
    }
}

/// HER-144: X (Twitter) OAuth 2.0 PKCE returns an access_token, not an
/// id_token, so its `/v1/auth/oauth/x/exchange` route decodes this body
/// shape instead of `OAuthExchangeRequest`. Mirrors the
/// `OAuthAccessTokenRequest` schema in `openapi.yaml`.
public struct OAuthAccessTokenRequest: Codable, Sendable {
    public let accessToken: String
    public init(accessToken: String) {
        self.accessToken = accessToken
    }
}

public struct ForgotPasswordRequest: Codable, Sendable {
    public let email: String
    public init(email: String) {
        self.email = email
    }
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
    public init(email: String) {
        self.email = email
    }
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
    /// Mnemosyne default-memory toggle for the tenant's managed Hermes.
    /// Default `true`: Mnemosyne is the memory layer and Hermes' native file
    /// memory is disabled. Toggle via `PUT /v1/me/privacy`; takes effect on the
    /// tenant container's next restart.
    public let mnemosyneEnabled: Bool
    public let isAdmin: Bool
    public init(
        userId: UUID,
        email: String,
        username: String,
        isVerified: Bool,
        privacyNoCNOrigin: Bool,
        contextRouting: Bool,
        autoSaveLinks: Bool = true,
        mnemosyneEnabled: Bool = true,
        isAdmin: Bool = false
    ) {
        self.userId = userId; self.email = email; self.username = username
        self.isVerified = isVerified; self.privacyNoCNOrigin = privacyNoCNOrigin
        self.contextRouting = contextRouting
        self.autoSaveLinks = autoSaveLinks
        self.mnemosyneEnabled = mnemosyneEnabled
        self.isAdmin = isAdmin
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
    /// Mnemosyne default-memory toggle. When `false`, the tenant's managed
    /// Hermes falls back to its native file memory; when `true`, Mnemosyne is
    /// the sole memory layer. Applied on the container's next restart.
    public let mnemosyneEnabled: Bool?
    public init(
        privacyNoCNOrigin: Bool?,
        contextRouting: Bool?,
        autoSaveLinks: Bool? = nil,
        mnemosyneEnabled: Bool? = nil
    ) {
        self.privacyNoCNOrigin = privacyNoCNOrigin
        self.contextRouting = contextRouting
        self.autoSaveLinks = autoSaveLinks
        self.mnemosyneEnabled = mnemosyneEnabled
    }
}

// ─── Phone Auth ──────────────────────────────────────────────────────────

public struct PhoneStartRequest: Codable, Sendable {
    public let phone: String
    public init(phone: String) {
        self.phone = phone
    }
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
    public init(email: String) {
        self.email = email
    }
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

public struct SoulResponse: Codable, Sendable {
    public let markdown: String
    public let updatedAt: Date?
    public init(markdown: String, updatedAt: Date? = nil) {
        self.markdown = markdown
        self.updatedAt = updatedAt
    }
}

public struct SoulPutRequest: Codable, Sendable {
    public let markdown: String
    public init(markdown: String) {
        self.markdown = markdown
    }
}

/// Superset of the server compose tones and the onboarding quiz tones.
/// Raw values are frozen: the client persists quiz answers in UserDefaults
/// and the server stores them in composed SOUL.md front-matter-adjacent text.
public enum SoulTone: String, Codable, Sendable, CaseIterable {
    case warm
    case conciseTechnical = "concise_technical"
    case playful
    case coach
    case formal
    case casual
    case dry
}

public enum SoulRole: String, Codable, Sendable, CaseIterable {
    case assistant
    case coworker
    case coach
    case secondBrain = "second_brain"
}

public enum SoulAutonomy: String, Codable, Sendable, CaseIterable {
    case askFirst = "ask_first"
    case suggest
    case act
}

/// Onboarding quiz priority chips ("What matters most to you?").
public enum SoulPriority: String, Codable, Sendable, CaseIterable {
    case focus
    case health
    case learning
    case family
    case money
    case creative
    case other
}

/// Reply format preference for the composed SOUL.md chat voice.
public enum SoulFormat: String, Codable, Sendable, CaseIterable {
    case bullets
    case prose
}

/// Reply length preference for the composed SOUL.md chat voice.
public enum SoulLength: String, Codable, Sendable, CaseIterable {
    case short
    case long
}

/// HER-100 — structured onboarding inputs the server renders into a filled
/// SOUL.md via `POST /v1/soul/compose`. Replaces the TODO-placeholder default.
///
/// v2: every field is optional so legacy 4-field clients keep decoding and the
/// server applies deterministic defaults for anything absent. `dryRun: true`
/// returns the composition without persisting (onboarding preview).
public struct SoulComposeRequest: Codable, Sendable {
    public let agentName: String?
    public let tone: SoulTone?
    public let role: SoulRole?
    public let autonomy: SoulAutonomy?
    public let priorities: [SoulPriority]?
    public let otherPriority: String?
    public let format: SoulFormat?
    public let length: SoulLength?
    public let emojis: Bool?
    public let voiceSamples: [String]?
    public let dryRun: Bool?

    enum CodingKeys: String, CodingKey {
        case agentName = "agent_name"
        case tone, role, autonomy, priorities
        case otherPriority = "other_priority"
        case format, length, emojis
        case voiceSamples = "voice_samples"
        case dryRun = "dry_run"
    }

    public init(
        agentName: String? = nil,
        tone: SoulTone? = nil,
        role: SoulRole? = nil,
        autonomy: SoulAutonomy? = nil,
        priorities: [SoulPriority]? = nil,
        otherPriority: String? = nil,
        format: SoulFormat? = nil,
        length: SoulLength? = nil,
        emojis: Bool? = nil,
        voiceSamples: [String]? = nil,
        dryRun: Bool? = nil
    ) {
        self.agentName = agentName
        self.tone = tone
        self.role = role
        self.autonomy = autonomy
        self.priorities = priorities
        self.otherPriority = otherPriority
        self.format = format
        self.length = length
        self.emojis = emojis
        self.voiceSamples = voiceSamples
        self.dryRun = dryRun
    }

    /// All-nil request — the server composes its canonical default SOUL.md.
    public static var defaults: SoulComposeRequest {
        SoulComposeRequest()
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
        if let v = try? c.decode(String.self) {
            self = .string(v)
        } else if let v = try? c.decode(Double.self) {
            self = .number(v)
        } else if let v = try? c.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? c.decode([String: AnyJSONValue].self) {
            self = .object(v)
        } else if let v = try? c.decode([AnyJSONValue].self) {
            self = .array(v)
        } else if c.decodeNil() {
            self = .null
        } else {
            self = .string("")
        }
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
        messages = try c.decode([ChatMessage].self, forKey: .messages)
        model = try c.decodeIfPresent(String.self, forKey: .model)
        temperature = try c.decodeIfPresent(Double.self, forKey: .temperature)
        stream = try c.decodeIfPresent(Bool.self, forKey: .stream) ?? false
        tools = try c.decodeIfPresent([ChatTool].self, forKey: .tools)
        tool_choice = try c.decodeIfPresent(AnyJSONValue.self, forKey: .tool_choice)
        sessionID = try c.decodeIfPresent(String.self, forKey: .sessionID)
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

public enum MemoryActorKindDTO: String, Codable, Sendable, CaseIterable {
    case user
    case model
    case system
}

public enum MemoryContributionOperationDTO: String, Codable, Sendable, CaseIterable {
    case create
    case update
}

public enum MemorySourceKindDTO: String, Codable, Sendable, CaseIterable {
    case manual
    case chat
    case query
    case knowledgeCompile = "knowledge_compile"
    case skill
    case vault
    case `import`
    case link
    case legacy
}

/// Historical model identity. Provider is intentionally a string rather than
/// `ProviderID`: managed/internal routes such as `hermesGateway` and `groq`
/// must remain attributable even though users cannot configure them directly.
public struct ModelProvenanceDTO: Codable, Sendable, Equatable, Hashable {
    public let provider: String
    public let model: String
    /// Optional Auto (Smart) explanation, e.g. "simple query → fast tier".
    public let reason: String?
    public let routingPolicy: LLMRoutingPolicy?
    public let complexity: RouterComplexity?
    public let taskType: RouterTaskType?

    public init(
        provider: String,
        model: String,
        reason: String? = nil,
        routingPolicy: LLMRoutingPolicy? = nil,
        complexity: RouterComplexity? = nil,
        taskType: RouterTaskType? = nil
    ) {
        self.provider = provider
        self.model = model
        self.reason = reason
        self.routingPolicy = routingPolicy
        self.complexity = complexity
        self.taskType = taskType
    }
}

/// Server → client summary of a single Auto/Cerberus routing decision.
public struct RoutingDecisionDTO: Codable, Sendable, Equatable {
    public let policy: LLMRoutingPolicy
    public let taskType: RouterTaskType
    public let complexity: RouterComplexity
    public let selected: ModelProvenanceDTO
    public let reason: String
    /// True when Auto was skipped (BYO Hermes, locked policy, single candidate).
    public let deferred: Bool

    public init(
        policy: LLMRoutingPolicy,
        taskType: RouterTaskType,
        complexity: RouterComplexity,
        selected: ModelProvenanceDTO,
        reason: String,
        deferred: Bool = false
    ) {
        self.policy = policy
        self.taskType = taskType
        self.complexity = complexity
        self.selected = selected
        self.reason = reason
        self.deferred = deferred
    }
}

public struct MemoryContributionDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let operation: MemoryContributionOperationDTO
    public let actor: MemoryActorKindDTO
    public let source: MemorySourceKindDTO
    public let model: ModelProvenanceDTO?
    public let sourceReference: String?
    public let createdAt: Date

    public init(
        id: UUID,
        operation: MemoryContributionOperationDTO,
        actor: MemoryActorKindDTO,
        source: MemorySourceKindDTO,
        model: ModelProvenanceDTO? = nil,
        sourceReference: String? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.operation = operation
        self.actor = actor
        self.source = source
        self.model = model
        self.sourceReference = sourceReference
        self.createdAt = createdAt
    }
}

public struct MemoryProvenanceSummaryDTO: Codable, Sendable, Equatable {
    public let createdBy: MemoryContributionDTO?
    public let lastUpdatedBy: MemoryContributionDTO?
    public let contributors: [ModelProvenanceDTO]

    public init(
        createdBy: MemoryContributionDTO? = nil,
        lastUpdatedBy: MemoryContributionDTO? = nil,
        contributors: [ModelProvenanceDTO] = []
    ) {
        self.createdBy = createdBy
        self.lastUpdatedBy = lastUpdatedBy
        self.contributors = contributors
    }
}

public struct MemoryProvenanceResponse: Codable, Sendable {
    public let memoryID: UUID
    public let contributions: [MemoryContributionDTO]

    public init(memoryID: UUID, contributions: [MemoryContributionDTO]) {
        self.memoryID = memoryID
        self.contributions = contributions
    }
}

public struct MemoryFacetDTO: Codable, Sendable, Equatable, Identifiable {
    public let value: String
    public let count: Int
    public var id: String {
        value
    }

    public init(value: String, count: Int) {
        self.value = value
        self.count = count
    }
}

public struct MemoryFacetsResponse: Codable, Sendable {
    public let providers: [MemoryFacetDTO]
    public let models: [MemoryFacetDTO]
    public let sources: [MemoryFacetDTO]
    public let oldestAt: Date?
    public let newestAt: Date?

    public init(
        providers: [MemoryFacetDTO],
        models: [MemoryFacetDTO],
        sources: [MemoryFacetDTO],
        oldestAt: Date? = nil,
        newestAt: Date? = nil
    ) {
        self.providers = providers
        self.models = models
        self.sources = sources
        self.oldestAt = oldestAt
        self.newestAt = newestAt
    }
}

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
    public let provenance: MemoryProvenanceSummaryDTO?
    public let createdByUserId: UUID?
    public let updatedByUserId: UUID?
    public init(
        id: UUID,
        content: String,
        tags: [String],
        createdAt: Date? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        accuracyM: Double? = nil,
        placeName: String? = nil,
        reviewState: String = "auto",
        provenance: MemoryProvenanceSummaryDTO? = nil,
        createdByUserId: UUID? = nil,
        updatedByUserId: UUID? = nil
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
        self.provenance = provenance
        self.createdByUserId = createdByUserId
        self.updatedByUserId = updatedByUserId
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

/// Precomputed, stable 3D layout coordinate for a graph node (HER-235 3D viz).
/// Derived server-side from note embeddings (PCA top-3) and normalized to a
/// bounded cube so the web + iOS clients render an identical, jitter-free
/// cluster. `nil` position on a node means "not yet laid out" — clients fall
/// back to their own force-directed placement for that node.
public struct GraphPosition3D: Codable, Sendable, Equatable {
    public let x: Double
    public let y: Double
    public let z: Double
    public init(x: Double, y: Double, z: Double) {
        self.x = x; self.y = y; self.z = z
    }
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
    /// HER-235 3D viz — normalized activity/heat in `[0, 1]` (recency of last
    /// access blended with `score`). Drives the cyan→amber color ramp on the
    /// clients. `nil` when the server predates the field → clients derive a
    /// fallback from `createdAt`.
    public let activity: Double?
    /// HER-235 3D viz — precomputed stable 3D layout coordinate. `nil` when not
    /// yet laid out (or older server) → client force-directed fallback.
    public let position: GraphPosition3D?
    /// Compact creator/updater information used for graph styling and filters.
    public let provenance: MemoryProvenanceSummaryDTO?

    public init(
        id: UUID,
        title: String,
        tags: [String],
        createdAt: Date,
        score: Double,
        kind: GraphNodeKindDTO = .memory,
        spaceID: UUID? = nil,
        activity: Double? = nil,
        position: GraphPosition3D? = nil,
        provenance: MemoryProvenanceSummaryDTO? = nil
    ) {
        self.id = id; self.title = title; self.tags = tags
        self.createdAt = createdAt; self.score = score
        self.kind = kind; self.spaceID = spaceID
        self.activity = activity; self.position = position
        self.provenance = provenance
    }

    /// Custom decode so a newer client stays robust against an older server
    /// that predates `kind`/`spaceID`/`activity`/`position`: missing keys fall
    /// back to defaults rather than failing the whole graph decode.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        score = try c.decode(Double.self, forKey: .score)
        kind = try c.decodeIfPresent(GraphNodeKindDTO.self, forKey: .kind) ?? .memory
        spaceID = try c.decodeIfPresent(UUID.self, forKey: .spaceID)
        activity = try c.decodeIfPresent(Double.self, forKey: .activity)
        position = try c.decodeIfPresent(GraphPosition3D.self, forKey: .position)
        provenance = try c.decodeIfPresent(MemoryProvenanceSummaryDTO.self, forKey: .provenance)
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

// ─── Knowledge Graph + Reasoning ────────────────────────────────────────

public enum KnowledgeNodeKindDTO: String, Codable, Sendable, CaseIterable {
    case claim
    case entity
    case event
}

public enum KnowledgeEdgePredicateDTO: String, Codable, Sendable, CaseIterable {
    case mentions
    case about
    case supports
    case contradicts
    case causes
    case precedes
    case relatedTo = "related_to"
    case derivedFrom = "derived_from"
}

public enum KnowledgeEdgeStateDTO: String, Codable, Sendable, CaseIterable {
    case asserted
    case suggested
    case confirmed
    case dismissed
    case stale
}

public struct KnowledgeEvidenceDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let memoryID: UUID
    public let sourceVaultFileID: UUID?
    public let quote: String
    public let startOffset: Int?
    public let endOffset: Int?

    public init(
        id: UUID,
        memoryID: UUID,
        sourceVaultFileID: UUID? = nil,
        quote: String,
        startOffset: Int? = nil,
        endOffset: Int? = nil
    ) {
        self.id = id
        self.memoryID = memoryID
        self.sourceVaultFileID = sourceVaultFileID
        self.quote = quote
        self.startOffset = startOffset
        self.endOffset = endOffset
    }
}

public struct KnowledgeNodeDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let kind: KnowledgeNodeKindDTO
    public let label: String
    public let summary: String?
    public let occurredAt: Date?
    public let confidence: Double
    public let evidence: [KnowledgeEvidenceDTO]

    public init(
        id: UUID,
        kind: KnowledgeNodeKindDTO,
        label: String,
        summary: String? = nil,
        occurredAt: Date? = nil,
        confidence: Double,
        evidence: [KnowledgeEvidenceDTO] = []
    ) {
        self.id = id
        self.kind = kind
        self.label = label
        self.summary = summary
        self.occurredAt = occurredAt
        self.confidence = confidence
        self.evidence = evidence
    }
}

public struct KnowledgeEdgeDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let from: UUID
    public let to: UUID
    public let predicate: KnowledgeEdgePredicateDTO
    public let state: KnowledgeEdgeStateDTO
    public let confidence: Double
    public let rationale: String?
    public let counterEvidence: String?
    public let evidence: [KnowledgeEvidenceDTO]

    public init(
        id: UUID,
        from: UUID,
        to: UUID,
        predicate: KnowledgeEdgePredicateDTO,
        state: KnowledgeEdgeStateDTO,
        confidence: Double,
        rationale: String? = nil,
        counterEvidence: String? = nil,
        evidence: [KnowledgeEvidenceDTO] = []
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.predicate = predicate
        self.state = state
        self.confidence = confidence
        self.rationale = rationale
        self.counterEvidence = counterEvidence
        self.evidence = evidence
    }
}

public struct KnowledgeGraphResponse: Codable, Sendable, Equatable {
    public let nodes: [KnowledgeNodeDTO]
    public let edges: [KnowledgeEdgeDTO]
    public let generatedAt: Date

    public init(nodes: [KnowledgeNodeDTO], edges: [KnowledgeEdgeDTO], generatedAt: Date) {
        self.nodes = nodes
        self.edges = edges
        self.generatedAt = generatedAt
    }
}

public struct KnowledgePathDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let nodes: [KnowledgeNodeDTO]
    public let edges: [KnowledgeEdgeDTO]
    public let confidence: Double

    public init(id: UUID = UUID(), nodes: [KnowledgeNodeDTO], edges: [KnowledgeEdgeDTO], confidence: Double) {
        self.id = id
        self.nodes = nodes
        self.edges = edges
        self.confidence = confidence
    }
}

public struct ConnectionExplanationRequest: Codable, Sendable, Equatable {
    public let fromNodeID: UUID
    public let toNodeID: UUID
    public let maxDepth: Int?

    public init(fromNodeID: UUID, toNodeID: UUID, maxDepth: Int? = nil) {
        self.fromNodeID = fromNodeID
        self.toNodeID = toNodeID
        self.maxDepth = maxDepth
    }
}

public struct ConnectionExplanationResponse: Codable, Sendable, Equatable {
    public let explanation: String
    public let paths: [KnowledgePathDTO]
    public let confidence: Double
    public let caveats: [String]

    public init(explanation: String, paths: [KnowledgePathDTO], confidence: Double, caveats: [String] = []) {
        self.explanation = explanation
        self.paths = paths
        self.confidence = confidence
        self.caveats = caveats
    }
}

public struct ReasoningQueryRequest: Codable, Sendable, Equatable {
    public let query: String
    public let maxDepth: Int?
    public let limit: Int?

    public init(query: String, maxDepth: Int? = nil, limit: Int? = nil) {
        self.query = query
        self.maxDepth = maxDepth
        self.limit = limit
    }
}

public struct ReasoningQueryResponse: Codable, Sendable, Equatable {
    public let answer: String
    public let paths: [KnowledgePathDTO]
    public let evidence: [KnowledgeEvidenceDTO]
    public let confidence: Double
    public let caveats: [String]
    public let suggestions: [KnowledgeEdgeDTO]

    public init(
        answer: String,
        paths: [KnowledgePathDTO],
        evidence: [KnowledgeEvidenceDTO],
        confidence: Double,
        caveats: [String] = [],
        suggestions: [KnowledgeEdgeDTO] = []
    ) {
        self.answer = answer
        self.paths = paths
        self.evidence = evidence
        self.confidence = confidence
        self.caveats = caveats
        self.suggestions = suggestions
    }
}

public struct ReasoningStreamEventDTO: Codable, Sendable, Equatable {
    public let type: String
    public let response: ReasoningQueryResponse?
    public let message: String?

    public init(type: String, response: ReasoningQueryResponse? = nil, message: String? = nil) {
        self.type = type
        self.response = response
        self.message = message
    }
}

public struct InferenceReviewRequest: Codable, Sendable, Equatable {
    public let note: String?
    public init(note: String? = nil) {
        self.note = note
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
    public init(memos: [MemoSummaryDTO]) {
        self.memos = memos
    }
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
        query = try c.decode(String.self, forKey: .query)
        limit = try c.decodeIfPresent(Int.self, forKey: .limit)
        sessionID = try c.decodeIfPresent(String.self, forKey: .sessionID)
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
    /// Cerberus route selection / attempt phase. Emitted before model tokens.
    case routing(RouterRoutingEventDTO)
    /// Final prompt-free token, cost, and latency metadata.
    case usage(RouterUsageDTO)
    /// Live progress from a multi-model execution. Candidate deltas are
    /// multiplexed by `outputID`; the synthesized answer continues to use
    /// ordinary `token` events so older clients still render it.
    case parallel(ParallelStreamEventDTO)
    /// HER-274 — emitted once per URL the server auto-captured to the
    /// user's vault while processing this chat turn. Sent AFTER tokens
    /// have streamed, BEFORE the `.done` terminator. Multiple events
    /// per turn possible when the user pastes several links.
    case linkSaved(LinkSavedDTO)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum EventType: String, Codable {
        case source, token, summary
        case followUps = "follow_ups"
        case done, error, fallback, routing, usage, parallel
        case linkSaved = "link_saved"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(EventType.self, forKey: .type)
        switch type {
        case .source: self = try .source(c.decode(QueryHitDTO.self, forKey: .payload))
        case .token: self = try .token(c.decode(String.self, forKey: .payload))
        case .summary: self = try .summary(c.decode(String.self, forKey: .payload))
        case .followUps: self = try .followUps(c.decode([String].self, forKey: .payload))
        case .done: self = .done
        case .error: self = try .error(c.decode(String.self, forKey: .payload))
        case .fallback: self = try .fallback(c.decode(ProviderFallbackNoticeDTO.self, forKey: .payload))
        case .routing: self = try .routing(c.decode(RouterRoutingEventDTO.self, forKey: .payload))
        case .usage: self = try .usage(c.decode(RouterUsageDTO.self, forKey: .payload))
        case .parallel: self = try .parallel(c.decode(ParallelStreamEventDTO.self, forKey: .payload))
        case .linkSaved: self = try .linkSaved(c.decode(LinkSavedDTO.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .source(h):
            try c.encode(EventType.source, forKey: .type)
            try c.encode(h, forKey: .payload)
        case let .token(s):
            try c.encode(EventType.token, forKey: .type)
            try c.encode(s, forKey: .payload)
        case let .summary(s):
            try c.encode(EventType.summary, forKey: .type)
            try c.encode(s, forKey: .payload)
        case let .followUps(arr):
            try c.encode(EventType.followUps, forKey: .type)
            try c.encode(arr, forKey: .payload)
        case .done:
            try c.encode(EventType.done, forKey: .type)
        case let .error(s):
            try c.encode(EventType.error, forKey: .type)
            try c.encode(s, forKey: .payload)
        case let .fallback(notice):
            try c.encode(EventType.fallback, forKey: .type)
            try c.encode(notice, forKey: .payload)
        case let .routing(event):
            try c.encode(EventType.routing, forKey: .type)
            try c.encode(event, forKey: .payload)
        case let .usage(usage):
            try c.encode(EventType.usage, forKey: .type)
            try c.encode(usage, forKey: .payload)
        case let .parallel(event):
            try c.encode(EventType.parallel, forKey: .type)
            try c.encode(event, forKey: .payload)
        case let .linkSaved(payload):
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
    public let pinnedMemoryIDs: [UUID]
    public let routeOverride: RouterModelRouteDTO?
    public init(
        id: UUID,
        title: String,
        spaceId: UUID? = nil,
        createdAt: Date,
        updatedAt: Date,
        pinnedMemoryIDs: [UUID] = [],
        routeOverride: RouterModelRouteDTO? = nil
    ) {
        self.id = id; self.title = title; self.spaceId = spaceId
        self.createdAt = createdAt; self.updatedAt = updatedAt
        self.pinnedMemoryIDs = pinnedMemoryIDs
        self.routeOverride = routeOverride
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
    /// Present for assistant turns produced by multi-model execution. Clients
    /// fetch the potentially large comparison payload only when expanded.
    public let parallelExecutionID: UUID?
    public let createdAt: Date
    public init(
        id: UUID,
        conversationId: UUID,
        role: ConversationMessageRole,
        content: String,
        sourceMemoryIDs: [UUID] = [],
        parallelExecutionID: UUID? = nil,
        createdAt: Date
    ) {
        self.id = id; self.conversationId = conversationId; self.role = role
        self.content = content; self.sourceMemoryIDs = sourceMemoryIDs
        self.parallelExecutionID = parallelExecutionID
        self.createdAt = createdAt
    }
}

/// Request body for `POST /v1/conversations`.
public struct ConversationCreateRequest: Codable, Sendable {
    public let title: String?
    public let spaceId: UUID?
    public let pinnedMemoryIDs: [UUID]
    public let routeOverride: RouterModelRouteDTO?
    public init(
        title: String? = nil,
        spaceId: UUID? = nil,
        pinnedMemoryIDs: [UUID] = [],
        routeOverride: RouterModelRouteDTO? = nil
    ) {
        self.title = title; self.spaceId = spaceId
        self.pinnedMemoryIDs = pinnedMemoryIDs
        self.routeOverride = routeOverride
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
    public let multiModel: ChatMultiModelOptionsDTO?
    public init(content: String, multiModel: ChatMultiModelOptionsDTO? = nil) {
        self.content = content
        self.multiModel = multiModel
    }
}

// ─── Hybrid local + cloud execution ─────────────────────────────────────

public enum HybridExecutionProfile: String, Codable, Sendable, CaseIterable {
    case `private`
    case balanced
    case quality
}

public enum ExecutionLocation: String, Codable, Sendable, CaseIterable {
    case onDevice = "on_device"
    case localEndpoint = "local_endpoint"
    case cloud
}

public enum LocalEndpointKind: String, Codable, Sendable, CaseIterable {
    case ollama
    case lmStudio = "lm_studio"
    case mlxServer = "mlx_server"
    case openAICompatible = "openai_compatible"
}

public struct HybridRoutingPreferencesDTO: Codable, Sendable, Equatable {
    public let profile: HybridExecutionProfile
    public let localFallbackEnabled: Bool
    public let cloudFallbackEnabled: Bool
    public let syncLocalConversations: Bool

    public init(
        profile: HybridExecutionProfile = .balanced,
        localFallbackEnabled: Bool = true,
        cloudFallbackEnabled: Bool = true,
        syncLocalConversations: Bool = true
    ) {
        self.profile = profile
        self.localFallbackEnabled = localFallbackEnabled
        self.cloudFallbackEnabled = cloudFallbackEnabled
        self.syncLocalConversations = syncLocalConversations
    }
}

public struct ConversationPrepareRequest: Codable, Sendable {
    public let content: String
    public init(content: String) {
        self.content = content
    }
}

public struct ConversationPrepareResponse: Codable, Sendable {
    public let executionID: UUID
    public let messages: [ChatMessage]
    public let sources: [QueryHitDTO]
    public let expiresAt: Date
    public let allowedTools: [LocalExecutionToolDTO]

    public init(
        executionID: UUID,
        messages: [ChatMessage],
        sources: [QueryHitDTO],
        expiresAt: Date,
        allowedTools: [LocalExecutionToolDTO] = []
    ) {
        self.executionID = executionID
        self.messages = messages
        self.sources = sources
        self.expiresAt = expiresAt
        self.allowedTools = allowedTools
    }
}

public enum LocalExecutionToolName: String, Codable, Sendable, CaseIterable {
    case memorySearch = "memory_search"
}

public struct LocalExecutionToolDTO: Codable, Sendable, Equatable {
    public let name: LocalExecutionToolName
    public let description: String

    public init(name: LocalExecutionToolName, description: String) {
        self.name = name
        self.description = description
    }
}

public struct LocalToolInvokeRequest: Codable, Sendable, Equatable {
    public let name: LocalExecutionToolName
    public let query: String
    public let limit: Int?

    public init(name: LocalExecutionToolName, query: String, limit: Int? = nil) {
        self.name = name
        self.query = query
        self.limit = limit
    }
}

public struct LocalToolInvokeResponse: Codable, Sendable {
    public let name: LocalExecutionToolName
    public let content: String
    public let sources: [QueryHitDTO]

    public init(name: LocalExecutionToolName, content: String, sources: [QueryHitDTO]) {
        self.name = name
        self.content = content
        self.sources = sources
    }
}

public struct LocalExecutionUsageDTO: Codable, Sendable, Equatable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let latencyMs: Int

    public init(inputTokens: Int = 0, outputTokens: Int = 0, latencyMs: Int = 0) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.latencyMs = latencyMs
    }
}

public struct ConversationCommitRequest: Codable, Sendable {
    public let executionID: UUID
    public let content: String
    public let location: ExecutionLocation
    public let provider: String
    public let model: String
    public let usage: LocalExecutionUsageDTO?

    public init(
        executionID: UUID,
        content: String,
        location: ExecutionLocation,
        provider: String,
        model: String,
        usage: LocalExecutionUsageDTO? = nil
    ) {
        self.executionID = executionID
        self.content = content
        self.location = location
        self.provider = provider
        self.model = model
        self.usage = usage
    }
}

public struct ConversationCommitResponse: Codable, Sendable {
    public let message: ConversationMessageDTO
    public let followUps: [String]

    public init(message: ConversationMessageDTO, followUps: [String] = []) {
        self.message = message
        self.followUps = followUps
    }
}

public struct LocalMemorySyncItemDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let content: String
    public let source: MemorySourceKindDTO
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: UUID, content: String, source: MemorySourceKindDTO, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.content = content
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct LocalMemorySyncResponse: Codable, Sendable {
    public let memories: [LocalMemorySyncItemDTO]
    public let deletedIDs: [UUID]
    public let nextCursor: String?

    public init(memories: [LocalMemorySyncItemDTO], deletedIDs: [UUID] = [], nextCursor: String? = nil) {
        self.memories = memories
        self.deletedIDs = deletedIDs
        self.nextCursor = nextCursor
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
    public init(spaces: [SpaceDTO]) {
        self.spaces = spaces
    }
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
    public let createdByUserId: UUID?
    public let updatedByUserId: UUID?
    public init(id: UUID, path: String, contentType: String, sizeBytes: Int64, sha256: String, spaceId: UUID? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, metadata: VaultNoteMetadataDTO? = nil, createdByUserId: UUID? = nil, updatedByUserId: UUID? = nil) {
        self.id = id; self.path = path; self.contentType = contentType
        self.sizeBytes = sizeBytes; self.sha256 = sha256; self.spaceId = spaceId
        self.createdAt = createdAt; self.updatedAt = updatedAt
        self.metadata = metadata
        self.createdByUserId = createdByUserId; self.updatedByUserId = updatedByUserId
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
        signupCompleted = try c.decode(Bool.self, forKey: .signupCompleted)
        signupCompletedAt = try c.decodeIfPresent(Date.self, forKey: .signupCompletedAt)
        emailVerifiedCompleted = try c.decode(Bool.self, forKey: .emailVerifiedCompleted)
        emailVerifiedCompletedAt = try c.decodeIfPresent(Date.self, forKey: .emailVerifiedCompletedAt)
        soulConfiguredCompleted = try c.decode(Bool.self, forKey: .soulConfiguredCompleted)
        soulConfiguredCompletedAt = try c.decodeIfPresent(Date.self, forKey: .soulConfiguredCompletedAt)
        firstCaptureCompleted = try c.decode(Bool.self, forKey: .firstCaptureCompleted)
        firstCaptureCompletedAt = try c.decodeIfPresent(Date.self, forKey: .firstCaptureCompletedAt)
        firstKBCompileCompleted = try c.decode(Bool.self, forKey: .firstKBCompileCompleted)
        firstKBCompileCompletedAt = try c.decodeIfPresent(Date.self, forKey: .firstKBCompileCompletedAt)
        firstQueryCompleted = try c.decode(Bool.self, forKey: .firstQueryCompleted)
        firstQueryCompletedAt = try c.decodeIfPresent(Date.self, forKey: .firstQueryCompletedAt)
        brainConfiguredCompleted = try c.decodeIfPresent(Bool.self, forKey: .brainConfiguredCompleted) ?? false
        brainConfiguredCompletedAt = try c.decodeIfPresent(Date.self, forKey: .brainConfiguredCompletedAt)
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
    public init(runId: UUID) {
        self.runId = runId
    }
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
            self = try .started(c.decode(KBCompileStartedDTO.self, forKey: .payload))
        case .preparing:
            self = try .preparing(c.decode(KBCompilePreparingDTO.self, forKey: .payload))
        case .thinking:
            self = try .thinking(c.decode(KBCompileThinkingDTO.self, forKey: .payload))
        case .memorySaved:
            self = try .memorySaved(c.decode(KBCompileMemorySavedDTO.self, forKey: .payload))
        case .completed:
            self = try .completed(c.decode(KBCompileCompletedDTO.self, forKey: .payload))
        case .error:
            self = try .error(c.decode(KBCompileErrorDTO.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .started(p):
            try c.encode(EventType.started, forKey: .type)
            try c.encode(p, forKey: .payload)
        case let .preparing(p):
            try c.encode(EventType.preparing, forKey: .type)
            try c.encode(p, forKey: .payload)
        case let .thinking(p):
            try c.encode(EventType.thinking, forKey: .type)
            try c.encode(p, forKey: .payload)
        case let .memorySaved(p):
            try c.encode(EventType.memorySaved, forKey: .type)
            try c.encode(p, forKey: .payload)
        case let .completed(p):
            try c.encode(EventType.completed, forKey: .type)
            try c.encode(p, forKey: .payload)
        case let .error(p):
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
    public init(unlocks: [UnlockDTO]) {
        self.unlocks = unlocks
    }
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
        source: String? = nil
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
    public init(suggestions: [String]) {
        self.suggestions = suggestions
    }
}

// ─── Hermes Config ───────────────────────────────────────────────────────

public struct HermesConfigGetResponse: Codable, Sendable {
    public let baseUrl: String
    public let hasAuthHeader: Bool
    public let verifiedAt: Date?
    /// User-chosen friendly name for this Hermes endpoint (e.g. "My VPS").
    public let name: String?
    public init(baseUrl: String, hasAuthHeader: Bool, verifiedAt: Date? = nil, name: String? = nil) {
        self.baseUrl = baseUrl; self.hasAuthHeader = hasAuthHeader
        self.verifiedAt = verifiedAt; self.name = name
    }
}

public struct HermesConfigPutRequest: Codable, Sendable {
    public let baseUrl: String
    public let authHeader: String?
    /// Optional friendly name for the endpoint.
    public let name: String?
    public init(baseUrl: String, authHeader: String? = nil, name: String? = nil) {
        self.baseUrl = baseUrl; self.authHeader = authHeader; self.name = name
    }
}

public struct HermesConfigTestResponse: Codable, Sendable {
    public let verifiedAt: Date
    public init(verifiedAt: Date) {
        self.verifiedAt = verifiedAt
    }
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
    case matrix
    case ntfy
    case mattermost
    case photon
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
    /// Photon iMessage setup (the free path): device-code login to the Photon
    /// dashboard, optional phone bind to provision a Spectrum user + iMessage
    /// line (assigned number is what contacts text). See the central Node
    /// sidecar + public webhook design in the Photon plan.
    case photonSetup
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
    public init(items: [HermesGatewayCatalogEntry]) {
        self.items = items
    }
}

public struct HermesGatewayPutRequest: Codable, Sendable {
    public let config: [String: String]
    public init(config: [String: String]) {
        self.config = config
    }
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
    public var id: UUID {
        jobID
    }

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
        case .step: self = try .step(c.decode(HermesGatewayApplyStep.self, forKey: .payload))
        case .status: self = try .status(c.decode(HermesGatewayApplyJobState.self, forKey: .payload))
        case .done: self = try .done(c.decode(HermesGatewayApplyJobStatus.self, forKey: .payload))
        case .error: self = try .error(c.decode(String.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .step(s):
            try c.encode(EventType.step, forKey: .type)
            try c.encode(s, forKey: .payload)
        case let .status(st):
            try c.encode(EventType.status, forKey: .type)
            try c.encode(st, forKey: .payload)
        case let .done(snapshot):
            try c.encode(EventType.done, forKey: .type)
            try c.encode(snapshot, forKey: .payload)
        case let .error(message):
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
        case .qr: self = try .qr(c.decode(String.self, forKey: .payload))
        case .status: self = try .status(c.decode(HermesWhatsAppPairStatus.self, forKey: .payload))
        case .linked: self = .linked
        case .error: self = try .error(c.decode(String.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .qr(art):
            try c.encode(EventType.qr, forKey: .type)
            try c.encode(art, forKey: .payload)
        case let .status(s):
            try c.encode(EventType.status, forKey: .type)
            try c.encode(s, forKey: .payload)
        case .linked:
            try c.encode(EventType.linked, forKey: .type)
        case let .error(message):
            try c.encode(EventType.error, forKey: .type)
            try c.encode(message, forKey: .payload)
        }
    }
}

/// Response body for `POST /v1/me/hermes-gateways/whatsapp/pair`. The client
/// then opens the SSE stream at `.../whatsapp/pair/{sessionID}/stream`.
public struct StartWhatsAppPairResponse: Codable, Sendable {
    public let sessionID: UUID
    public init(sessionID: UUID) {
        self.sessionID = sessionID
    }
}

// ─── Photon Setup (free iMessage path via central sidecar + webhook) ────
//
// Device-code login to Photon dashboard, then (optionally) bind a phone number
// to provision a Spectrum user and obtain the assigned iMessage line that
// contacts will text. The resulting spectrumProjectId + projectSecret are
// sealed and stored like other gateways; at runtime the central Node sidecar
// (spectrum-ts) is activated and inbound events arrive at the public webhook.

/// Live status during a Photon setup session.
public enum HermesPhotonSetupStatus: String, Codable, Sendable, CaseIterable {
    case starting
    case awaitingApproval // device code / verification URI shown to user
    case approved
    case provisioning // creating project, enabling Spectrum, registering phone
    case done
    case failed
}

/// SSE frame for the Photon setup stream (device approval + phone bind + line assignment).
/// Discriminated by `type` for client decoding (mirrors WhatsApp + apply events).
public enum HermesPhotonSetupEvent: Codable, Sendable, Equatable {
    case status(HermesPhotonSetupStatus)
    case deviceCode(verificationUri: String, userCode: String, expiresIn: Int)
    /// The iMessage number contacts should text to reach the agent.
    case assignedLine(String)
    case error(String)

    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum EventType: String, Codable {
        case status, deviceCode, assignedLine, error
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(EventType.self, forKey: .type)
        switch type {
        case .status: self = try .status(c.decode(HermesPhotonSetupStatus.self, forKey: .payload))
        case .deviceCode:
            let p = try c.decode(DeviceCodePayload.self, forKey: .payload)
            self = .deviceCode(verificationUri: p.verificationUri, userCode: p.userCode, expiresIn: p.expiresIn)
        case .assignedLine: self = try .assignedLine(c.decode(String.self, forKey: .payload))
        case .error: self = try .error(c.decode(String.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .status(s):
            try c.encode(EventType.status, forKey: .type)
            try c.encode(s, forKey: .payload)
        case let .deviceCode(uri, code, exp):
            try c.encode(EventType.deviceCode, forKey: .type)
            try c.encode(DeviceCodePayload(verificationUri: uri, userCode: code, expiresIn: exp), forKey: .payload)
        case let .assignedLine(line):
            try c.encode(EventType.assignedLine, forKey: .type)
            try c.encode(line, forKey: .payload)
        case let .error(msg):
            try c.encode(EventType.error, forKey: .type)
            try c.encode(msg, forKey: .payload)
        }
    }

    private struct DeviceCodePayload: Codable, Equatable {
        let verificationUri: String
        let userCode: String
        let expiresIn: Int
    }
}

/// Response for starting a Photon setup session. Client then subscribes to the
/// SSE stream and later submits the phone number.
public struct StartPhotonSetupResponse: Codable, Sendable {
    public let sessionID: UUID
    public init(sessionID: UUID) {
        self.sessionID = sessionID
    }
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
    public init(x: String, y: Double) {
        self.x = x; self.y = y
    }
}

public struct LuminaSeries: Codable, Sendable {
    public let name: String
    public let points: [LuminaChartPoint]
    public init(name: String, points: [LuminaChartPoint]) {
        self.name = name; self.points = points
    }
}

public struct LuminaKeyValue: Codable, Sendable {
    public let key: String
    public let value: String
    public init(key: String, value: String) {
        self.key = key; self.value = value
    }
}

public struct LuminaBlock: Codable, Sendable {
    /// Discriminator. Known: heading · paragraph · markdown · statCard ·
    /// lineChart · barChart · list · table · badge · keyValue · quote ·
    /// image · divider. Unknown values render a fallback client-side.
    public let type: String
    public let text: String? // heading/paragraph/markdown/quote/badge
    public let level: Int? // heading depth (1…3)
    public let label: String? // statCard caption
    public let value: String? // statCard primary value
    public let delta: String? // statCard change ("+1.2%")
    public let trend: String? // "up" | "down" | "flat"
    public let items: [String]? // list rows
    public let columns: [String]? // table header
    public let rows: [[String]]? // table body
    public let series: [LuminaSeries]? // lineChart/barChart
    public let pairs: [LuminaKeyValue]? // keyValue grid
    public let url: String? // image

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
    public init(skills: [SkillDTO]) {
        self.skills = skills
    }
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
    public var id: AppleDataDomain {
        domain
    }

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
    public init(consents: [AppleConsentDTO]) {
        self.consents = consents
    }
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
    case ping // round-trip health check
    case reminderCreate = "reminder_create" // EventKit write
    case calendarCreate = "calendar_create" // EventKit write
    case deviceFetch = "device_fetch" // fresh read of a domain
    case photoAnalyze = "photo_analyze" // on-demand single-asset analysis
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
    public init(command: DeviceCommand) {
        type = "device_command"; self.command = command
    }
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

// ─── Apple Selective-Sync Tier — derived data synced server-side ──────────
//
// Promotes Calendar / Reminders / Photos from on-demand device-RPC into a
// persisted server cache Hermes can reason over in the background (daily
// briefs, scheduled jobs, proactive nudges) without a live device round-trip.
// Principle: sync derived text + metadata + structured fields ONLY; never
// raw bytes (photo pixels stay on device). Mirrors the HealthKit ingest
// pattern (`HealthEventInput` → `HealthIngestResponse`). All ingest routes
// are consent-gated server-side via `AppleDataDomain`.

/// Shared result shape for every selective-sync ingest endpoint.
public struct AppleSyncResponse: Codable, Sendable {
    public let inserted: Int
    public let updated: Int
    public let skipped: Int
    public init(inserted: Int, updated: Int, skipped: Int) {
        self.inserted = inserted; self.updated = updated; self.skipped = skipped
    }
}

// ─── Calendar (EventKit) — reuses the HER-340 `calendar_events` table ─────
//
// Server stamps `source = "apple_eventkit"` (the table's `source` column
// already reserves this; HER-340 Google sync uses `"google"`). Upsert key is
// `(tenant_id, source, external_id)`, so EventKit deltas are idempotent and
// never collide with Google rows. `calendar_query` reads this cache.

public struct AppleCalendarEventInput: Codable, Sendable {
    /// EventKit `eventIdentifier` — stable per-event id used as the upsert key.
    public let externalID: String
    public let calendarID: String?
    public let title: String
    public let notes: String?
    public let location: String?
    public let startsAt: Date
    public let endsAt: Date
    public let allDay: Bool
    /// `"confirmed"` | `"cancelled"` — cancelled rows are tombstoned, not deleted.
    public let status: String?
    public let organizer: String?
    /// EventKit `lastModifiedDate`; drives last-writer-wins on upsert.
    public let remoteUpdatedAt: Date?
    public init(externalID: String, calendarID: String? = nil, title: String, notes: String? = nil, location: String? = nil, startsAt: Date, endsAt: Date, allDay: Bool = false, status: String? = nil, organizer: String? = nil, remoteUpdatedAt: Date? = nil) {
        self.externalID = externalID; self.calendarID = calendarID; self.title = title
        self.notes = notes; self.location = location; self.startsAt = startsAt
        self.endsAt = endsAt; self.allDay = allDay; self.status = status
        self.organizer = organizer; self.remoteUpdatedAt = remoteUpdatedAt
    }
}

/// Batch ingest body for `POST /v1/calendar/sync` (EventKit delta push).
public struct AppleCalendarSyncRequest: Codable, Sendable {
    public let events: [AppleCalendarEventInput]
    public init(events: [AppleCalendarEventInput]) {
        self.events = events
    }
}

// ─── Google Calendar (cloud OAuth source) — HER-340 ──────────────────────
//
// Server-owned OAuth + sync (tokens in `calendar_accounts`, events in the
// shared `calendar_events` table with `source = "google"`). These wire types
// back the iOS connect pane + the events read endpoint. The connect flow is a
// Web-client server-callback: iOS opens `authorizeURL` in
// ASWebAuthenticationSession; Google redirects to the server HTTPS callback;
// the server exchanges the code and 302s back to `luminavault://` to dismiss.
// Event creation is performed by the Hermes `calendar_create_event` tool, so
// there is no HTTP create DTO in Phase 1.

/// `GET /v1/calendar/status` — connection state for the settings pane.
public struct CalendarStatusResponse: Codable, Sendable {
    public let connected: Bool
    /// Refresh token rejected / externally revoked — pane should prompt a reconnect.
    public let needsReauth: Bool
    public let accountEmail: String?
    public let lastSyncedAt: Date?
    public init(connected: Bool, needsReauth: Bool, accountEmail: String? = nil, lastSyncedAt: Date? = nil) {
        self.connected = connected
        self.needsReauth = needsReauth
        self.accountEmail = accountEmail
        self.lastSyncedAt = lastSyncedAt
    }
}

/// `POST /v1/calendar/connect` — returns the Google consent URL for the app
/// to open in `ASWebAuthenticationSession`.
public struct CalendarConnectStartResponse: Codable, Sendable {
    public let authorizeURL: String
    public init(authorizeURL: String) {
        self.authorizeURL = authorizeURL
    }
}

/// Read shape for a cached calendar event (source-agnostic).
public struct CalendarEventDTO: Codable, Sendable {
    public let id: String
    public let source: String
    public let externalID: String
    public let title: String
    public let notes: String?
    public let location: String?
    public let startsAt: Date
    public let endsAt: Date
    public let allDay: Bool
    /// `"confirmed"` | `"tentative"` | `"cancelled"`.
    public let status: String
    public let organizer: String?
    public let htmlLink: String?
    public init(id: String, source: String, externalID: String, title: String, notes: String? = nil, location: String? = nil, startsAt: Date, endsAt: Date, allDay: Bool, status: String, organizer: String? = nil, htmlLink: String? = nil) {
        self.id = id; self.source = source; self.externalID = externalID
        self.title = title; self.notes = notes; self.location = location
        self.startsAt = startsAt; self.endsAt = endsAt; self.allDay = allDay
        self.status = status; self.organizer = organizer; self.htmlLink = htmlLink
    }
}

/// `GET /v1/calendar/events` — upcoming events for the pane / debugging.
public struct CalendarEventsResponse: Codable, Sendable {
    public let events: [CalendarEventDTO]
    public init(events: [CalendarEventDTO]) {
        self.events = events
    }
}

/// `POST /v1/calendar/events` — create an event on the user's Google
/// calendar (the app's explicit "Add to Calendar" action). The server writes
/// to Google live, caches the result, and returns it as `CalendarEventDTO`.
public struct CalendarCreateEventRequest: Codable, Sendable {
    public let title: String
    public let startsAt: Date
    public let endsAt: Date
    public let location: String?
    public let notes: String?
    public let attendees: [String]?
    public init(title: String, startsAt: Date, endsAt: Date, location: String? = nil, notes: String? = nil, attendees: [String]? = nil) {
        self.title = title
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.location = location
        self.notes = notes
        self.attendees = attendees
    }
}

// ─── Reminders (EventKit) — new `apple_reminders` table (≠ M63 reminders) ─

public struct AppleReminderInput: Codable, Sendable {
    /// EventKit `calendarItemIdentifier` — upsert key.
    public let externalID: String
    public let title: String
    public let notes: String?
    public let dueAt: Date?
    public let completed: Bool
    public let completedAt: Date?
    public let listName: String?
    /// EventKit priority 0–9 (0 = none).
    public let priority: Int?
    public let remoteUpdatedAt: Date?
    public init(externalID: String, title: String, notes: String? = nil, dueAt: Date? = nil, completed: Bool = false, completedAt: Date? = nil, listName: String? = nil, priority: Int? = nil, remoteUpdatedAt: Date? = nil) {
        self.externalID = externalID; self.title = title; self.notes = notes
        self.dueAt = dueAt; self.completed = completed; self.completedAt = completedAt
        self.listName = listName; self.priority = priority; self.remoteUpdatedAt = remoteUpdatedAt
    }
}

/// Batch ingest body for `POST /v1/reminders/sync` (EventKit delta push).
public struct AppleRemindersSyncRequest: Codable, Sendable {
    public let reminders: [AppleReminderInput]
    public init(reminders: [AppleReminderInput]) {
        self.reminders = reminders
    }
}

// ─── Photos — derived-text index (OCR + on-device scene tags; no pixels) ──
//
// Only OCR text + Vision scene labels + metadata leave the device. Server
// embeds `ocrText` into pgvector for semantic recall ("the screenshot about
// the flight"). De-dup key is `assetLocalID` (PHAsset localIdentifier).

public struct PhotoIndexInput: Codable, Sendable {
    /// `PHAsset.localIdentifier` — stable per-asset id, the upsert key.
    public let assetLocalID: String
    public let takenAt: Date?
    public let isScreenshot: Bool
    /// On-device `VNRecognizeTextRequest` output. Nil/empty if no text found.
    public let ocrText: String?
    /// On-device `VNClassifyImageRequest` labels (e.g. ["document","receipt"]).
    public let sceneTags: [String]?
    public init(assetLocalID: String, takenAt: Date? = nil, isScreenshot: Bool = false, ocrText: String? = nil, sceneTags: [String]? = nil) {
        self.assetLocalID = assetLocalID; self.takenAt = takenAt
        self.isScreenshot = isScreenshot; self.ocrText = ocrText; self.sceneTags = sceneTags
    }
}

/// Batch ingest body for `POST /v1/photos/index` (derived-text push).
public struct PhotoIndexSyncRequest: Codable, Sendable {
    public let items: [PhotoIndexInput]
    public init(items: [PhotoIndexInput]) {
        self.items = items
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

// ─── Visual Workflows (Automation 2.0) ──────────────────────────────────

public enum WorkflowTriggerKind: String, Codable, Sendable, CaseIterable {
    case manual, chat, schedule, webhook
}

public enum WorkflowNodeKind: String, Codable, Sendable, CaseIterable {
    case trigger, llm, skill, memorySearch, memoryWrite, template, condition, approval, parallel, forEach, whileLoop, output
}

public enum WorkflowRunStatus: String, Codable, Sendable, CaseIterable {
    case queued, running, waitingForApproval, paused, succeeded, failed, cancelled, timedOut
}

public enum WorkflowNodeRunStatus: String, Codable, Sendable, CaseIterable {
    case pending, running, waitingForApproval, succeeded, failed, skipped, cancelled
}

public enum WorkflowPauseReason: String, Codable, Sendable, CaseIterable {
    case runSpendLimit
    case dailySpendLimit
    case monthlySpendLimit
    case globalSpendLimit
    case providerUnavailable
}

public enum WorkflowRunEventKind: String, Codable, Sendable, CaseIterable {
    case runQueued
    case runStarted
    case nodeStarted
    case nodeOutput
    case nodeCompleted
    case approvalRequired
    case runPaused
    case runCompleted
    case runFailed
    case runCancelled
}

/// A canvas node. `configuration` is intentionally string-valued in v1:
/// prompts and mappings use the restricted `{{path.to.value}}` expression
/// syntax, while numeric and boolean settings use their canonical strings.
public struct WorkflowNodeDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let kind: WorkflowNodeKind
    public let name: String
    public let x: Double
    public let y: Double
    public let configuration: [String: String]

    public init(id: UUID = UUID(), kind: WorkflowNodeKind, name: String, x: Double, y: Double, configuration: [String: String] = [:]) {
        self.id = id; self.kind = kind; self.name = name
        self.x = x; self.y = y; self.configuration = configuration
    }
}

public struct WorkflowEdgeDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let sourceNodeID: UUID
    public let sourcePort: String
    public let targetNodeID: UUID
    public let targetPort: String

    public init(id: UUID = UUID(), sourceNodeID: UUID, sourcePort: String = "output", targetNodeID: UUID, targetPort: String = "input") {
        self.id = id; self.sourceNodeID = sourceNodeID; self.sourcePort = sourcePort
        self.targetNodeID = targetNodeID; self.targetPort = targetPort
    }
}

public struct WorkflowDefinitionDTO: Codable, Sendable, Equatable {
    public let schemaVersion: Int
    public let trigger: WorkflowTriggerKind
    public let triggerConfiguration: [String: String]
    public let nodes: [WorkflowNodeDTO]
    public let edges: [WorkflowEdgeDTO]

    public init(schemaVersion: Int = 1, trigger: WorkflowTriggerKind, triggerConfiguration: [String: String] = [:], nodes: [WorkflowNodeDTO], edges: [WorkflowEdgeDTO]) {
        self.schemaVersion = schemaVersion; self.trigger = trigger; self.triggerConfiguration = triggerConfiguration
        self.nodes = nodes; self.edges = edges
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, trigger, triggerConfiguration, nodes, edges
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        trigger = try container.decode(WorkflowTriggerKind.self, forKey: .trigger)
        triggerConfiguration = try container.decodeIfPresent([String: String].self, forKey: .triggerConfiguration) ?? [:]
        nodes = try container.decode([WorkflowNodeDTO].self, forKey: .nodes)
        edges = try container.decode([WorkflowEdgeDTO].self, forKey: .edges)
    }
}

public struct WorkflowSummaryDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let descriptionText: String?
    public let enabled: Bool
    public let trigger: WorkflowTriggerKind
    public let draftRevision: Int
    public let publishedVersion: Int?
    public let lastRunStatus: WorkflowRunStatus?
    public let lastRunAt: Date?
    public let pendingApprovalCount: Int
    public let isLegacyJob: Bool
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: UUID, name: String, descriptionText: String? = nil, enabled: Bool, trigger: WorkflowTriggerKind, draftRevision: Int, publishedVersion: Int? = nil, lastRunStatus: WorkflowRunStatus? = nil, lastRunAt: Date? = nil, pendingApprovalCount: Int = 0, isLegacyJob: Bool = false, createdAt: Date, updatedAt: Date) {
        self.id = id; self.name = name; self.descriptionText = descriptionText
        self.enabled = enabled; self.trigger = trigger; self.draftRevision = draftRevision
        self.publishedVersion = publishedVersion; self.lastRunStatus = lastRunStatus
        self.lastRunAt = lastRunAt; self.pendingApprovalCount = pendingApprovalCount
        self.isLegacyJob = isLegacyJob; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

public struct WorkflowDetailDTO: Codable, Sendable, Equatable {
    public let workflow: WorkflowSummaryDTO
    public let definition: WorkflowDefinitionDTO
    public init(workflow: WorkflowSummaryDTO, definition: WorkflowDefinitionDTO) {
        self.workflow = workflow; self.definition = definition
    }
}

public struct WorkflowListResponse: Codable, Sendable {
    public let workflows: [WorkflowSummaryDTO]
    public init(workflows: [WorkflowSummaryDTO]) {
        self.workflows = workflows
    }
}

public struct WorkflowCreateRequest: Codable, Sendable {
    public let name: String
    public let descriptionText: String?
    public let definition: WorkflowDefinitionDTO
    public init(name: String, descriptionText: String? = nil, definition: WorkflowDefinitionDTO) {
        self.name = name; self.descriptionText = descriptionText; self.definition = definition
    }
}

public struct WorkflowDraftUpdateRequest: Codable, Sendable {
    public let name: String?
    public let descriptionText: String?
    public let enabled: Bool?
    public let expectedRevision: Int
    public let definition: WorkflowDefinitionDTO
    public init(name: String? = nil, descriptionText: String? = nil, enabled: Bool? = nil, expectedRevision: Int, definition: WorkflowDefinitionDTO) {
        self.name = name; self.descriptionText = descriptionText; self.enabled = enabled
        self.expectedRevision = expectedRevision; self.definition = definition
    }
}

public struct WorkflowRunRequest: Codable, Sendable {
    public let input: [String: String]
    public let conversationID: UUID?
    public init(input: [String: String] = [:], conversationID: UUID? = nil) {
        self.input = input; self.conversationID = conversationID
    }
}

public struct WorkflowNodeRunDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let nodeID: UUID
    public let nodeName: String
    public let status: WorkflowNodeRunStatus
    public let attempt: Int
    public let startedAt: Date?
    public let endedAt: Date?
    public let outputPreview: String?
    public let error: String?
    public let provider: ProviderID?
    public let model: String?
    public let tokensIn: Int?
    public let tokensOut: Int?
    public let managedCostUsdMicros: Int64?
    public init(id: UUID, nodeID: UUID, nodeName: String, status: WorkflowNodeRunStatus, attempt: Int, startedAt: Date? = nil, endedAt: Date? = nil, outputPreview: String? = nil, error: String? = nil, provider: ProviderID? = nil, model: String? = nil, tokensIn: Int? = nil, tokensOut: Int? = nil, managedCostUsdMicros: Int64? = nil) {
        self.id = id; self.nodeID = nodeID; self.nodeName = nodeName; self.status = status
        self.attempt = attempt; self.startedAt = startedAt; self.endedAt = endedAt
        self.outputPreview = outputPreview; self.error = error; self.provider = provider
        self.model = model; self.tokensIn = tokensIn; self.tokensOut = tokensOut
        self.managedCostUsdMicros = managedCostUsdMicros
    }
}

public struct WorkflowRunDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let workflowID: UUID
    public let workflowName: String
    public let version: Int
    public let status: WorkflowRunStatus
    public let trigger: WorkflowTriggerKind
    public let startedAt: Date?
    public let endedAt: Date?
    public let createdAt: Date
    public let error: String?
    public let pauseReason: WorkflowPauseReason?
    public let managedSpendUsdMicros: Int64?
    public let managedSpendLimitUsdMicros: Int64?
    public let nodeRuns: [WorkflowNodeRunDTO]
    public init(id: UUID, workflowID: UUID, workflowName: String, version: Int, status: WorkflowRunStatus, trigger: WorkflowTriggerKind, startedAt: Date? = nil, endedAt: Date? = nil, createdAt: Date, error: String? = nil, pauseReason: WorkflowPauseReason? = nil, managedSpendUsdMicros: Int64? = nil, managedSpendLimitUsdMicros: Int64? = nil, nodeRuns: [WorkflowNodeRunDTO] = []) {
        self.id = id; self.workflowID = workflowID; self.workflowName = workflowName
        self.version = version; self.status = status; self.trigger = trigger
        self.startedAt = startedAt; self.endedAt = endedAt; self.createdAt = createdAt
        self.error = error; self.pauseReason = pauseReason
        self.managedSpendUsdMicros = managedSpendUsdMicros
        self.managedSpendLimitUsdMicros = managedSpendLimitUsdMicros
        self.nodeRuns = nodeRuns
    }
}

public struct WorkflowRunsResponse: Codable, Sendable {
    public let runs: [WorkflowRunDTO]
    public init(runs: [WorkflowRunDTO]) {
        self.runs = runs
    }
}

public struct WorkflowApprovalDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let runID: UUID
    public let workflowID: UUID
    public let workflowName: String
    public let nodeID: UUID
    public let title: String
    public let message: String?
    public let expiresAt: Date
    public let createdAt: Date
    public init(id: UUID, runID: UUID, workflowID: UUID, workflowName: String, nodeID: UUID, title: String, message: String? = nil, expiresAt: Date, createdAt: Date) {
        self.id = id; self.runID = runID; self.workflowID = workflowID
        self.workflowName = workflowName; self.nodeID = nodeID; self.title = title
        self.message = message; self.expiresAt = expiresAt; self.createdAt = createdAt
    }
}

public struct WorkflowApprovalsResponse: Codable, Sendable {
    public let approvals: [WorkflowApprovalDTO]
    public init(approvals: [WorkflowApprovalDTO]) {
        self.approvals = approvals
    }
}

public struct WorkflowApprovalDecisionRequest: Codable, Sendable {
    public let approved: Bool
    public let note: String?
    public let memoryIDs: [UUID]?
    public init(approved: Bool, note: String? = nil, memoryIDs: [UUID]? = nil) {
        self.approved = approved; self.note = note; self.memoryIDs = memoryIDs
    }
}

public struct WorkflowRunEventDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: Int64
    public let runID: UUID
    public let kind: WorkflowRunEventKind
    public let nodeID: UUID?
    public let message: String?
    public let data: [String: String]
    public let createdAt: Date

    public init(id: Int64, runID: UUID, kind: WorkflowRunEventKind, nodeID: UUID? = nil, message: String? = nil, data: [String: String] = [:], createdAt: Date) {
        self.id = id; self.runID = runID; self.kind = kind; self.nodeID = nodeID
        self.message = message; self.data = data; self.createdAt = createdAt
    }
}

public struct WorkflowRunEventsResponse: Codable, Sendable, Equatable {
    public let events: [WorkflowRunEventDTO]
    public init(events: [WorkflowRunEventDTO]) { self.events = events }
}

public struct WorkflowVersionDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let workflowID: UUID
    public let version: Int
    public let definition: WorkflowDefinitionDTO
    public let createdAt: Date

    public init(id: UUID, workflowID: UUID, version: Int, definition: WorkflowDefinitionDTO, createdAt: Date) {
        self.id = id; self.workflowID = workflowID; self.version = version
        self.definition = definition; self.createdAt = createdAt
    }
}

public struct WorkflowVersionsResponse: Codable, Sendable, Equatable {
    public let versions: [WorkflowVersionDTO]
    public init(versions: [WorkflowVersionDTO]) { self.versions = versions }
}

public struct WorkflowValidationIssueDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let code: String
    public let message: String
    public let nodeID: UUID?

    public init(id: UUID = UUID(), code: String, message: String, nodeID: UUID? = nil) {
        self.id = id; self.code = code; self.message = message; self.nodeID = nodeID
    }
}

public struct WorkflowValidationResponse: Codable, Sendable, Equatable {
    public let valid: Bool
    public let issues: [WorkflowValidationIssueDTO]
    public init(valid: Bool, issues: [WorkflowValidationIssueDTO] = []) {
        self.valid = valid; self.issues = issues
    }
}

public struct WorkflowTemplateDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let descriptionText: String
    public let category: String
    public let definition: WorkflowDefinitionDTO

    public init(id: String, name: String, descriptionText: String, category: String, definition: WorkflowDefinitionDTO) {
        self.id = id; self.name = name; self.descriptionText = descriptionText
        self.category = category; self.definition = definition
    }
}

public struct WorkflowTemplatesResponse: Codable, Sendable, Equatable {
    public let templates: [WorkflowTemplateDTO]
    public init(templates: [WorkflowTemplateDTO]) { self.templates = templates }
}

public struct WorkflowTemplateInstantiateRequest: Codable, Sendable, Equatable {
    public let name: String?
    public init(name: String? = nil) { self.name = name }
}

public struct WorkflowLimitsDTO: Codable, Sendable, Equatable {
    public let tier: UserTier
    public let canAuthor: Bool
    public let activeRuns: Int
    public let activeRunLimit: Int
    public let minimumScheduleMinutes: Int
    public let perRunLimitUsdMicros: Int64
    public let dailyLimitUsdMicros: Int64
    public let dailySpentUsdMicros: Int64
    public let monthlyLimitUsdMicros: Int64
    public let monthlySpentUsdMicros: Int64
    public let managedInferenceAvailable: Bool
    public let freeFallbackActive: Bool

    public init(tier: UserTier, canAuthor: Bool, activeRuns: Int, activeRunLimit: Int, minimumScheduleMinutes: Int, perRunLimitUsdMicros: Int64, dailyLimitUsdMicros: Int64, dailySpentUsdMicros: Int64, monthlyLimitUsdMicros: Int64, monthlySpentUsdMicros: Int64, managedInferenceAvailable: Bool, freeFallbackActive: Bool) {
        self.tier = tier; self.canAuthor = canAuthor; self.activeRuns = activeRuns
        self.activeRunLimit = activeRunLimit; self.minimumScheduleMinutes = minimumScheduleMinutes
        self.perRunLimitUsdMicros = perRunLimitUsdMicros; self.dailyLimitUsdMicros = dailyLimitUsdMicros
        self.dailySpentUsdMicros = dailySpentUsdMicros; self.monthlyLimitUsdMicros = monthlyLimitUsdMicros
        self.monthlySpentUsdMicros = monthlySpentUsdMicros
        self.managedInferenceAvailable = managedInferenceAvailable; self.freeFallbackActive = freeFallbackActive
    }
}

/// Returned only when a webhook credential is created or rotated. The secret
/// is write-only and cannot be fetched again.
public struct WorkflowWebhookCredentialDTO: Codable, Sendable, Equatable {
    public let hookID: UUID
    public let path: String
    public let secret: String
    public init(hookID: UUID, path: String, secret: String) {
        self.hookID = hookID; self.path = path; self.secret = secret
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

// ─── Chat Inbox + Preferences ────────────────────────────────────────────

/// Cross-platform summary row for the primary Chats inbox. This is richer than
/// `ConversationDTO` so clients can render an inbox without fetching each
/// transcript, and intentionally close to `SessionDTO` so the backend can reuse
/// the existing conversation-message summary query.
public struct ChatInboxItemDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let preview: String
    public let messageCount: Int
    public let lastMessageAt: Date
    public let workspaceID: UUID?
    public let sourceLabel: String?
    public let providerID: ProviderID?
    public let model: String?
    public let pinned: Bool
    public let archived: Bool

    public init(
        id: UUID,
        title: String,
        preview: String,
        messageCount: Int,
        lastMessageAt: Date,
        workspaceID: UUID? = nil,
        sourceLabel: String? = nil,
        providerID: ProviderID? = nil,
        model: String? = nil,
        pinned: Bool = false,
        archived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.preview = preview
        self.messageCount = messageCount
        self.lastMessageAt = lastMessageAt
        self.workspaceID = workspaceID
        self.sourceLabel = sourceLabel
        self.providerID = providerID
        self.model = model
        self.pinned = pinned
        self.archived = archived
    }
}

/// Response body for `GET /v1/chat/inbox`.
public struct ChatInboxResponse: Codable, Sendable, Equatable {
    public let items: [ChatInboxItemDTO]
    public let nextCursor: String?

    public init(items: [ChatInboxItemDTO], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

/// Cross-device chat behavior preferences. Platform-local behavior, such as
/// iOS haptics, stays outside this contract.
public struct ChatPreferencesDTO: Codable, Sendable, Equatable {
    public let autoExpandThinking: Bool
    public let sendOnReturn: Bool

    public init(autoExpandThinking: Bool = true, sendOnReturn: Bool = false) {
        self.autoExpandThinking = autoExpandThinking
        self.sendOnReturn = sendOnReturn
    }
}

/// Response body for `GET /v1/me/chat-preferences`.
public struct ChatPreferencesGetResponse: Codable, Sendable, Equatable {
    public let preferences: ChatPreferencesDTO

    public init(preferences: ChatPreferencesDTO = ChatPreferencesDTO()) {
        self.preferences = preferences
    }
}

/// Request body for `PUT /v1/me/chat-preferences`.
public struct ChatPreferencesPutRequest: Codable, Sendable, Equatable {
    public let preferences: ChatPreferencesDTO

    public init(preferences: ChatPreferencesDTO) {
        self.preferences = preferences
    }
}

// ─── Connections + Diagnostics Summary ───────────────────────────────────

/// User-facing connection buckets for the task-based Settings surface.
public enum ConnectionKind: String, Codable, Sendable, CaseIterable {
    case llmProvider = "llm_provider"
    case hermesServer = "hermes_server"
    case hermesGateway = "hermes_gateway"
    case linkedAccount = "linked_account"
    case calendar
    case nous
    case plugin
    case server
}

/// Normalized health state for connection rows and diagnostics checks.
public enum ConnectionHealth: String, Codable, Sendable, CaseIterable {
    case connected
    case needsSetup = "needs_setup"
    case degraded
    case error
    case unknown
    case testing
}

/// Hint clients can use to choose the correct detail flow without re-deriving
/// intent from a title or status string.
public enum ConnectionActionHint: String, Codable, Sendable, CaseIterable {
    case configureProvider = "configure_provider"
    case configureHermes = "configure_hermes"
    case configureGateway = "configure_gateway"
    case connectAccount = "connect_account"
    case openPlugin = "open_plugin"
    case openServerSettings = "open_server_settings"
    case viewDiagnostics = "view_diagnostics"
}

public struct ConnectionSummaryDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let kind: ConnectionKind
    public let title: String
    public let subtitle: String?
    public let health: ConnectionHealth
    public let providerID: ProviderID?
    public let gatewayID: HermesGatewayID?
    public let lastCheckedAt: Date?
    public let statusDetail: String?
    public let actionHint: ConnectionActionHint?

    public init(
        id: String,
        kind: ConnectionKind,
        title: String,
        subtitle: String? = nil,
        health: ConnectionHealth,
        providerID: ProviderID? = nil,
        gatewayID: HermesGatewayID? = nil,
        lastCheckedAt: Date? = nil,
        statusDetail: String? = nil,
        actionHint: ConnectionActionHint? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.health = health
        self.providerID = providerID
        self.gatewayID = gatewayID
        self.lastCheckedAt = lastCheckedAt
        self.statusDetail = statusDetail
        self.actionHint = actionHint
    }
}

/// Response body for `GET /v1/me/connections`.
public struct ConnectionsSummaryResponse: Codable, Sendable, Equatable {
    public let connections: [ConnectionSummaryDTO]
    public let checkedAt: Date?

    public init(connections: [ConnectionSummaryDTO], checkedAt: Date? = nil) {
        self.connections = connections
        self.checkedAt = checkedAt
    }
}

public struct ConnectionTestResultDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let kind: ConnectionKind
    public let title: String
    public let health: ConnectionHealth
    public let ok: Bool
    public let checkedAt: Date
    public let statusDetail: String?
    public let errorCode: String?
    public let errorMessage: String?

    public init(
        id: String,
        kind: ConnectionKind,
        title: String,
        health: ConnectionHealth,
        ok: Bool,
        checkedAt: Date,
        statusDetail: String? = nil,
        errorCode: String? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.health = health
        self.ok = ok
        self.checkedAt = checkedAt
        self.statusDetail = statusDetail
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
}

/// Response body for `POST /v1/me/connections/test-all`.
public struct ConnectionsTestAllResponse: Codable, Sendable, Equatable {
    public let results: [ConnectionTestResultDTO]
    public let checkedAt: Date

    public init(results: [ConnectionTestResultDTO], checkedAt: Date) {
        self.results = results
        self.checkedAt = checkedAt
    }
}

public enum ConnectionDiagnosticSeverity: String, Codable, Sendable, CaseIterable {
    case info
    case warning
    case error
}

public struct ConnectionDiagnosticEventDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let occurredAt: Date
    public let kind: ConnectionKind
    public let connectionID: String?
    public let connectionTitle: String?
    public let severity: ConnectionDiagnosticSeverity
    public let message: String
    public let code: String?

    public init(
        id: UUID,
        occurredAt: Date,
        kind: ConnectionKind,
        connectionID: String? = nil,
        connectionTitle: String? = nil,
        severity: ConnectionDiagnosticSeverity,
        message: String,
        code: String? = nil
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.kind = kind
        self.connectionID = connectionID
        self.connectionTitle = connectionTitle
        self.severity = severity
        self.message = message
        self.code = code
    }
}

/// Response body for `GET /v1/me/connections/events`.
public struct ConnectionDiagnosticEventsResponse: Codable, Sendable, Equatable {
    public let events: [ConnectionDiagnosticEventDTO]
    public let nextCursor: String?

    public init(events: [ConnectionDiagnosticEventDTO], nextCursor: String? = nil) {
        self.events = events
        self.nextCursor = nextCursor
    }
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
    /// Google Gemini — native `generateContent` API (not OpenAI-compatible).
    /// Per-user `GEMINI_API_KEY` in `user_provider_credentials`; routed via
    /// `GeminiContentsAdapter`. Free tier handles large prompts that the
    /// managed OpenRouter free tier rejects (402 prompt-token cap).
    case gemini
    /// Nous Research portal inference API
    /// (`https://inference-api.nousresearch.com/v1`). OpenAI-compatible;
    /// per-user key in `user_provider_credentials`, routed via the
    /// OpenAI-compatible adapter. Aggregates many upstreams OpenRouter-style
    /// and exposes rotating free models (e.g. `stepfun/step-3.7-flash:free`),
    /// so its model list is fetched live rather than hardcoded. Separate from
    /// the container-scoped Nous OAuth ("Connect Nous") flow.
    case nous
    /// P2 — generic OpenAI-compatible endpoint: any base URL + optional
    /// API key. Covers Groq, Together, LM Studio, vLLM, LiteLLM proxies,
    /// llama.cpp server — anything speaking `POST /v1/chat/completions`.
    /// `baseUrl` is required for this provider; model list is fetched live
    /// from `<base>/v1/models` with a free-text fallback.
    case custom
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

// ─── BYO-Hermes capabilities (P3 live proxy) ─────────────────────────────

/// Per-settings-domain availability against a connected BYO Hermes.
/// Derived from the remote `GET /v1/capabilities` contract. Clients gate
/// each pane on this: `live` panes read/write the remote box directly,
/// `readOnly` panes display remote state but can't mutate it, `unsupported`
/// panes are hidden or shown with a "your Hermes doesn't expose this"
/// explainer. `managed` means the LuminaVault-managed container owns it
/// (the tenant isn't on BYO Hermes at all).
public enum HermesDomainAvailability: String, Codable, Sendable {
    case live
    case readOnly = "read_only"
    case unsupported
    case managed
}

/// Feature availability of a tenant's connected Hermes, per settings domain.
/// A managed tenant (no BYO override) reports every domain as `.managed`.
/// A BYO tenant reports what its remote `api_server` actually exposes —
/// hermes-agent ≥0.18 serves chat/sessions/jobs/skills over HTTP but keeps
/// SOUL/config/gateways/memory file-on-disk (see docs/hermes-api-server-surface.md).
public struct HermesCapabilities: Codable, Sendable {
    /// True when routing against a user-hosted Hermes (`user_hermes_config`).
    public let isUserOverride: Bool
    /// Remote `api_server` version string when known (from `/health`).
    public let remoteVersion: String?
    public let chat: HermesDomainAvailability
    public let sessions: HermesDomainAvailability
    public let jobs: HermesDomainAvailability
    public let skills: HermesDomainAvailability
    public let soul: HermesDomainAvailability
    public let gateways: HermesDomainAvailability
    public let memory: HermesDomainAvailability
    public let providers: HermesDomainAvailability
    /// Availability of the structured document/image/audio/video ingestion API.
    public let multimodalIngestion: HermesDomainAvailability?
    /// MIME types advertised by a remote Hermes. Nil means the gateway did not advertise a list.
    public let ingestionSupportedMimeTypes: [String]?
    /// Maximum source size accepted by the remote gateway, when advertised.
    public let ingestionMaxSourceBytes: Int64?
    /// Whether the remote gateway can fetch a short-lived HTTPS source URL.
    public let ingestionRemoteSourceURL: Bool?
    public init(
        isUserOverride: Bool,
        remoteVersion: String? = nil,
        chat: HermesDomainAvailability,
        sessions: HermesDomainAvailability,
        jobs: HermesDomainAvailability,
        skills: HermesDomainAvailability,
        soul: HermesDomainAvailability,
        gateways: HermesDomainAvailability,
        memory: HermesDomainAvailability,
        providers: HermesDomainAvailability,
        multimodalIngestion: HermesDomainAvailability? = nil,
        ingestionSupportedMimeTypes: [String]? = nil,
        ingestionMaxSourceBytes: Int64? = nil,
        ingestionRemoteSourceURL: Bool? = nil
    ) {
        self.isUserOverride = isUserOverride
        self.remoteVersion = remoteVersion
        self.chat = chat
        self.sessions = sessions
        self.jobs = jobs
        self.skills = skills
        self.soul = soul
        self.gateways = gateways
        self.memory = memory
        self.providers = providers
        self.multimodalIngestion = multimodalIngestion
        self.ingestionSupportedMimeTypes = ingestionSupportedMimeTypes
        self.ingestionMaxSourceBytes = ingestionMaxSourceBytes
        self.ingestionRemoteSourceURL = ingestionRemoteSourceURL
    }

    /// Every domain owned by the managed container — the default for tenants
    /// with no BYO Hermes override.
    public static let managedDefault = HermesCapabilities(
        isUserOverride: false,
        chat: .managed, sessions: .managed, jobs: .managed, skills: .managed,
        soul: .managed, gateways: .managed, memory: .managed, providers: .managed,
        multimodalIngestion: .managed,
        ingestionSupportedMimeTypes: ["application/pdf", "image/*", "audio/*", "video/*", "text/html"],
        ingestionMaxSourceBytes: 2 * 1024 * 1024 * 1024,
        ingestionRemoteSourceURL: false
    )
}

/// `GET /v1/me/hermes/capabilities` response. `checkedAt` reflects when the
/// remote probe last ran (nil for managed tenants / never-probed).
public struct HermesCapabilitiesResponse: Codable, Sendable {
    public let capabilities: HermesCapabilities
    public let checkedAt: Date?
    public init(capabilities: HermesCapabilities, checkedAt: Date? = nil) {
        self.capabilities = capabilities
        self.checkedAt = checkedAt
    }
}

/// Response for `GET /v1/me/providers/{provider}/models`. The server
/// fetches the provider's live `/v1/models` listing with the user's stored
/// credential (OpenAI-compatible providers like Nous/OpenRouter/xAI/NVIDIA);
/// `fetchedLive` is `true` when that succeeded, `false` when it fell back to
/// the offline `LLMModelCatalog`. Lets the client picker stay current with
/// providers whose model lists rotate (e.g. Nous free models).
public struct ProviderModelsResponse: Codable, Sendable {
    public let provider: ProviderID
    public let models: [LLMModelInfo]
    public let fetchedLive: Bool
    public init(provider: ProviderID, models: [LLMModelInfo], fetchedLive: Bool) {
        self.provider = provider
        self.models = models
        self.fetchedLive = fetchedLive
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

// ─── Provider credential pools (round-robin) ─────────────────────────────

/// One additional API key in a provider's round-robin pool. The plaintext
/// key is never echoed — only id/label/createdAt.
public struct ProviderPoolKeyDTO: Codable, Sendable {
    public let id: UUID
    public let label: String?
    public let createdAt: Date?
    public init(id: UUID, label: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.label = label
        self.createdAt = createdAt
    }
}

public struct ProviderPoolListResponse: Codable, Sendable {
    public let provider: ProviderID
    public let keys: [ProviderPoolKeyDTO]
    public init(provider: ProviderID, keys: [ProviderPoolKeyDTO]) {
        self.provider = provider
        self.keys = keys
    }
}

public struct ProviderPoolAddRequest: Codable, Sendable {
    public let apiKey: String
    public let label: String?
    public init(apiKey: String, label: String? = nil) {
        self.apiKey = apiKey
        self.label = label
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

/// Task-aware routing policy. Orthogonal to `LLMBrainMode` (who pays / which keys).
///
/// - `locked` — always the configured primary (or forced route)
/// - `autoSmart` — complexity + task type pick the smallest sufficient model
/// - `fastCheap` / `balanced` / `maxQuality` — objective weight presets
public enum LLMRoutingPolicy: String, Codable, Sendable, CaseIterable {
    case locked
    case autoSmart
    case fastCheap
    case balanced
    case maxQuality

    /// Default objective weights for preset policies. `autoSmart` and `locked`
    /// return `nil` so the profile's stored weights apply.
    public var presetObjective: RouterObjectiveWeightsDTO? {
        switch self {
        case .locked, .autoSmart:
            return nil
        case .fastCheap:
            return RouterObjectiveWeightsDTO(quality: 20, cost: 50, latency: 30)
        case .balanced:
            return RouterObjectiveWeightsDTO(quality: 50, cost: 25, latency: 25)
        case .maxQuality:
            return RouterObjectiveWeightsDTO(quality: 80, cost: 10, latency: 10)
        }
    }

    public var displayName: String {
        switch self {
        case .locked: return "Locked to primary"
        case .autoSmart: return "Auto (Smart)"
        case .fastCheap: return "Fast & Cheap"
        case .balanced: return "Balanced"
        case .maxQuality: return "Max Quality"
        }
    }
}

// ─── Cerberus Router ───────────────────────────────────────

/// How hard a turn is — drives the minimum model tier Auto may pick.
public enum RouterComplexity: String, Codable, Sendable, CaseIterable, Comparable {
    case low
    case medium
    case high

    private var rank: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }

    public static func < (lhs: RouterComplexity, rhs: RouterComplexity) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// Capability band of a concrete model in the routing catalog.
public enum RouterModelTier: String, Codable, Sendable, CaseIterable, Comparable {
    /// Haiku / Flash / mini class — cheap and fast.
    case fast
    /// Sonnet / GPT-4o / mid-tier workhorses.
    case balanced
    /// Opus / Fable / frontier reasoning.
    case max

    private var rank: Int {
        switch self {
        case .fast: return 0
        case .balanced: return 1
        case .max: return 2
        }
    }

    public static func < (lhs: RouterModelTier, rhs: RouterModelTier) -> Bool {
        lhs.rank < rhs.rank
    }

    /// Minimum tier allowed for a complexity floor.
    public static func minimum(for complexity: RouterComplexity) -> RouterModelTier {
        switch complexity {
        case .low: return .fast
        case .medium: return .balanced
        case .high: return .max
        }
    }
}

public enum RouterTaskType: String, Codable, Sendable, CaseIterable {
    case general
    case reasoning
    case coding
    case search
    case summarization
    case extraction
    case creative
    case automation
}

public enum RouterSurface: String, Codable, Sendable, CaseIterable {
    case chat
    case query
    case knowledgeCompile
    case job
    case workflow
    case skill
    case memo
    case system
}

public enum RouterActionKind: String, Codable, Sendable, CaseIterable {
    case sequential
    case ensemble
}

public enum RouterRetryPolicy: String, Codable, Sendable, CaseIterable {
    case fast
    case resilient
}

/// User-facing orchestration semantics layered on top of Cerberus routing.
public enum ParallelStrategyDTO: String, Codable, Sendable, CaseIterable, Hashable {
    case auto
    case bestOfN
    case debate
    case consensus
    case specialist
}

public enum ParallelExecutionStatusDTO: String, Codable, Sendable, Hashable {
    case running
    case completed
    case degraded
    case failed
    case cancelled
}

public enum ParallelOutputStageDTO: String, Codable, Sendable, Hashable {
    case answer
    case revision
    case synthesis
}

public enum ParallelStreamEventKindDTO: String, Codable, Sendable, Hashable {
    case executionStarted
    case outputStarted
    case outputDelta
    case outputCompleted
    case outputFailed
    case synthesisStarted
    case executionCompleted
}

public struct RouterObjectiveWeightsDTO: Codable, Sendable, Equatable {
    public let quality: Int
    public let cost: Int
    public let latency: Int

    public init(quality: Int = 50, cost: Int = 25, latency: Int = 25) {
        self.quality = quality
        self.cost = cost
        self.latency = latency
    }
}

public struct RouterBudgetPolicyDTO: Codable, Sendable, Equatable {
    public let softLimitUsdMicros: Int64?
    public let hardLimitUsdMicros: Int64?

    public init(softLimitUsdMicros: Int64? = nil, hardLimitUsdMicros: Int64? = nil) {
        self.softLimitUsdMicros = softLimitUsdMicros
        self.hardLimitUsdMicros = hardLimitUsdMicros
    }
}

public struct RouterModelRouteDTO: Codable, Sendable, Hashable, Identifiable {
    public let provider: ProviderID
    public let model: String
    public let inputPerMillionUsdMicros: Int64?
    public let outputPerMillionUsdMicros: Int64?

    public var id: String {
        "\(provider.rawValue):\(model)"
    }

    public init(
        provider: ProviderID,
        model: String,
        inputPerMillionUsdMicros: Int64? = nil,
        outputPerMillionUsdMicros: Int64? = nil
    ) {
        self.provider = provider
        self.model = model
        self.inputPerMillionUsdMicros = inputPerMillionUsdMicros
        self.outputPerMillionUsdMicros = outputPerMillionUsdMicros
    }
}

public struct ParallelParticipantDTO: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let role: String
    public let instructions: String?
    public let route: RouterModelRouteDTO

    public init(
        id: UUID = UUID(),
        role: String,
        instructions: String? = nil,
        route: RouterModelRouteDTO
    ) {
        self.id = id
        self.role = role
        self.instructions = instructions
        self.route = route
    }
}

public struct ChatMultiModelOptionsDTO: Codable, Sendable, Equatable {
    public let enabled: Bool
    public let strategy: ParallelStrategyDTO

    public init(enabled: Bool, strategy: ParallelStrategyDTO = .auto) {
        self.enabled = enabled
        self.strategy = strategy
    }
}

public struct ParallelExecutionRequestDTO: Codable, Sendable {
    public let prompt: String
    public let strategy: ParallelStrategyDTO
    public let participants: [ParallelParticipantDTO]?
    public let synthesisRoute: RouterModelRouteDTO?
    public let synthesisPrompt: String?
    public let synthesisPresetID: UUID?
    public let spaceID: UUID?

    public init(
        prompt: String,
        strategy: ParallelStrategyDTO = .auto,
        participants: [ParallelParticipantDTO]? = nil,
        synthesisRoute: RouterModelRouteDTO? = nil,
        synthesisPrompt: String? = nil,
        synthesisPresetID: UUID? = nil,
        spaceID: UUID? = nil
    ) {
        self.prompt = prompt
        self.strategy = strategy
        self.participants = participants
        self.synthesisRoute = synthesisRoute
        self.synthesisPrompt = synthesisPrompt
        self.synthesisPresetID = synthesisPresetID
        self.spaceID = spaceID
    }
}

public struct ParallelStreamEventDTO: Codable, Sendable, Equatable {
    public let executionID: UUID
    public let kind: ParallelStreamEventKindDTO
    public let strategy: ParallelStrategyDTO?
    public let outputID: UUID?
    public let participantID: UUID?
    public let role: String?
    public let route: RouterModelRouteDTO?
    public let stage: ParallelOutputStageDTO?
    public let round: Int?
    public let delta: String?
    public let errorCode: String?
    public let status: ParallelExecutionStatusDTO?

    public init(
        executionID: UUID,
        kind: ParallelStreamEventKindDTO,
        strategy: ParallelStrategyDTO? = nil,
        outputID: UUID? = nil,
        participantID: UUID? = nil,
        role: String? = nil,
        route: RouterModelRouteDTO? = nil,
        stage: ParallelOutputStageDTO? = nil,
        round: Int? = nil,
        delta: String? = nil,
        errorCode: String? = nil,
        status: ParallelExecutionStatusDTO? = nil
    ) {
        self.executionID = executionID
        self.kind = kind
        self.strategy = strategy
        self.outputID = outputID
        self.participantID = participantID
        self.role = role
        self.route = route
        self.stage = stage
        self.round = round
        self.delta = delta
        self.errorCode = errorCode
        self.status = status
    }
}

public struct ParallelOutputDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let participantID: UUID?
    public let role: String
    public let route: RouterModelRouteDTO
    public let stage: ParallelOutputStageDTO
    public let round: Int
    public let content: String
    public let status: String
    public let tokensIn: Int
    public let tokensOut: Int
    public let estimatedCostUsdMicros: Int64
    public let latencyMs: Int

    public init(
        id: UUID,
        participantID: UUID? = nil,
        role: String,
        route: RouterModelRouteDTO,
        stage: ParallelOutputStageDTO,
        round: Int,
        content: String,
        status: String,
        tokensIn: Int,
        tokensOut: Int,
        estimatedCostUsdMicros: Int64,
        latencyMs: Int
    ) {
        self.id = id
        self.participantID = participantID
        self.role = role
        self.route = route
        self.stage = stage
        self.round = round
        self.content = content
        self.status = status
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.estimatedCostUsdMicros = estimatedCostUsdMicros
        self.latencyMs = latencyMs
    }
}

public struct ParallelExecutionSummaryDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let strategy: ParallelStrategyDTO
    public let status: ParallelExecutionStatusDTO
    public let promptPreview: String
    public let participantCount: Int
    public let estimatedCostUsdMicros: Int64
    public let latencyMs: Int
    public let createdAt: Date

    public init(
        id: UUID,
        strategy: ParallelStrategyDTO,
        status: ParallelExecutionStatusDTO,
        promptPreview: String,
        participantCount: Int,
        estimatedCostUsdMicros: Int64,
        latencyMs: Int,
        createdAt: Date
    ) {
        self.id = id
        self.strategy = strategy
        self.status = status
        self.promptPreview = promptPreview
        self.participantCount = participantCount
        self.estimatedCostUsdMicros = estimatedCostUsdMicros
        self.latencyMs = latencyMs
        self.createdAt = createdAt
    }
}

public struct ParallelExecutionDetailDTO: Codable, Sendable {
    public let summary: ParallelExecutionSummaryDTO
    public let prompt: String
    public let outputs: [ParallelOutputDTO]
    public let synthesizedAnswer: String?

    public init(
        summary: ParallelExecutionSummaryDTO,
        prompt: String,
        outputs: [ParallelOutputDTO],
        synthesizedAnswer: String? = nil
    ) {
        self.summary = summary
        self.prompt = prompt
        self.outputs = outputs
        self.synthesizedAnswer = synthesizedAnswer
    }
}

public struct ParallelExecutionsResponse: Codable, Sendable {
    public let executions: [ParallelExecutionSummaryDTO]
    public init(executions: [ParallelExecutionSummaryDTO]) {
        self.executions = executions
    }
}

public struct SynthesisPresetDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let prompt: String
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: UUID, name: String, prompt: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct SynthesisPresetWriteRequest: Codable, Sendable {
    public let name: String
    public let prompt: String
    public init(name: String, prompt: String) {
        self.name = name; self.prompt = prompt
    }
}

public struct SynthesisPresetsResponse: Codable, Sendable {
    public let presets: [SynthesisPresetDTO]
    public init(presets: [SynthesisPresetDTO]) {
        self.presets = presets
    }
}

/// Both sequential and ensemble actions use one wire shape. Sequential actions
/// consume `routes` as an ordered fallback chain. Ensemble actions run 2–4
/// routes concurrently and use `synthesisRoute` for the final answer.
public struct RouterActionDTO: Codable, Sendable, Equatable {
    public let kind: RouterActionKind
    public let routes: [RouterModelRouteDTO]
    public let synthesisRoute: RouterModelRouteDTO?
    public let minimumSuccessfulResults: Int?
    public let retryPolicy: RouterRetryPolicy
    public let parallelStrategy: ParallelStrategyDTO?
    public let participants: [ParallelParticipantDTO]?

    public init(
        kind: RouterActionKind = .sequential,
        routes: [RouterModelRouteDTO],
        synthesisRoute: RouterModelRouteDTO? = nil,
        minimumSuccessfulResults: Int? = nil,
        retryPolicy: RouterRetryPolicy = .fast,
        parallelStrategy: ParallelStrategyDTO? = nil,
        participants: [ParallelParticipantDTO]? = nil
    ) {
        self.kind = kind
        self.routes = routes
        self.synthesisRoute = synthesisRoute
        self.minimumSuccessfulResults = minimumSuccessfulResults
        self.retryPolicy = retryPolicy
        self.parallelStrategy = parallelStrategy
        self.participants = participants
    }
}

public struct RouterRuleDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let enabled: Bool
    public let priority: Int
    public let taskTypes: [RouterTaskType]
    public let surfaces: [RouterSurface]
    public let action: RouterActionDTO

    public init(
        id: UUID = UUID(),
        name: String,
        enabled: Bool = true,
        priority: Int,
        taskTypes: [RouterTaskType],
        surfaces: [RouterSurface] = [],
        action: RouterActionDTO
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.priority = priority
        self.taskTypes = taskTypes
        self.surfaces = surfaces
        self.action = action
    }
}

public struct RouterProfileDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let mode: LLMBrainMode
    public let isPreset: Bool
    public let objective: RouterObjectiveWeightsDTO
    public let budget: RouterBudgetPolicyDTO
    public let allowedProviders: [ProviderID]
    public let blockedProviders: [ProviderID]
    public let defaultAction: RouterActionDTO
    public let rules: [RouterRuleDTO]
    /// Task-aware routing policy. Defaults to `autoSmart` for new profiles.
    public let routingPolicy: LLMRoutingPolicy
    public let revision: Int
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        name: String,
        mode: LLMBrainMode,
        isPreset: Bool = false,
        objective: RouterObjectiveWeightsDTO = .init(),
        budget: RouterBudgetPolicyDTO = .init(),
        allowedProviders: [ProviderID] = [],
        blockedProviders: [ProviderID] = [],
        defaultAction: RouterActionDTO,
        rules: [RouterRuleDTO] = [],
        routingPolicy: LLMRoutingPolicy = .autoSmart,
        revision: Int = 1,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.isPreset = isPreset
        self.objective = objective
        self.budget = budget
        self.allowedProviders = allowedProviders
        self.blockedProviders = blockedProviders
        self.defaultAction = defaultAction
        self.rules = rules
        self.routingPolicy = routingPolicy
        self.revision = revision
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, mode, isPreset, objective, budget
        case allowedProviders, blockedProviders, defaultAction, rules
        case routingPolicy, revision, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        mode = try c.decode(LLMBrainMode.self, forKey: .mode)
        isPreset = try c.decodeIfPresent(Bool.self, forKey: .isPreset) ?? false
        objective = try c.decodeIfPresent(RouterObjectiveWeightsDTO.self, forKey: .objective) ?? .init()
        budget = try c.decodeIfPresent(RouterBudgetPolicyDTO.self, forKey: .budget) ?? .init()
        allowedProviders = try c.decodeIfPresent([ProviderID].self, forKey: .allowedProviders) ?? []
        blockedProviders = try c.decodeIfPresent([ProviderID].self, forKey: .blockedProviders) ?? []
        defaultAction = try c.decode(RouterActionDTO.self, forKey: .defaultAction)
        rules = try c.decodeIfPresent([RouterRuleDTO].self, forKey: .rules) ?? []
        routingPolicy = try c.decodeIfPresent(LLMRoutingPolicy.self, forKey: .routingPolicy) ?? .autoSmart
        revision = try c.decodeIfPresent(Int.self, forKey: .revision) ?? 1
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct RouterProfileWriteRequest: Codable, Sendable {
    public let name: String
    public let mode: LLMBrainMode
    public let objective: RouterObjectiveWeightsDTO
    public let budget: RouterBudgetPolicyDTO
    public let allowedProviders: [ProviderID]
    public let blockedProviders: [ProviderID]
    public let defaultAction: RouterActionDTO
    public let rules: [RouterRuleDTO]
    public let routingPolicy: LLMRoutingPolicy
    public let expectedRevision: Int?

    public init(
        name: String,
        mode: LLMBrainMode,
        objective: RouterObjectiveWeightsDTO,
        budget: RouterBudgetPolicyDTO,
        allowedProviders: [ProviderID] = [],
        blockedProviders: [ProviderID] = [],
        defaultAction: RouterActionDTO,
        rules: [RouterRuleDTO] = [],
        routingPolicy: LLMRoutingPolicy = .autoSmart,
        expectedRevision: Int? = nil
    ) {
        self.name = name
        self.mode = mode
        self.objective = objective
        self.budget = budget
        self.allowedProviders = allowedProviders
        self.blockedProviders = blockedProviders
        self.defaultAction = defaultAction
        self.rules = rules
        self.routingPolicy = routingPolicy
        self.expectedRevision = expectedRevision
    }

    private enum CodingKeys: String, CodingKey {
        case name, mode, objective, budget, allowedProviders, blockedProviders
        case defaultAction, rules, routingPolicy, expectedRevision
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        mode = try c.decode(LLMBrainMode.self, forKey: .mode)
        objective = try c.decode(RouterObjectiveWeightsDTO.self, forKey: .objective)
        budget = try c.decode(RouterBudgetPolicyDTO.self, forKey: .budget)
        allowedProviders = try c.decodeIfPresent([ProviderID].self, forKey: .allowedProviders) ?? []
        blockedProviders = try c.decodeIfPresent([ProviderID].self, forKey: .blockedProviders) ?? []
        defaultAction = try c.decode(RouterActionDTO.self, forKey: .defaultAction)
        rules = try c.decodeIfPresent([RouterRuleDTO].self, forKey: .rules) ?? []
        routingPolicy = try c.decodeIfPresent(LLMRoutingPolicy.self, forKey: .routingPolicy) ?? .autoSmart
        expectedRevision = try c.decodeIfPresent(Int.self, forKey: .expectedRevision)
    }
}

public struct RouterProfilesResponse: Codable, Sendable {
    public let profiles: [RouterProfileDTO]
    public let defaultProfileID: UUID

    public init(profiles: [RouterProfileDTO], defaultProfileID: UUID) {
        self.profiles = profiles
        self.defaultProfileID = defaultProfileID
    }
}

public enum RouterBindingScope: String, Codable, Sendable, CaseIterable {
    case user
    case space
    case job
    case workflow
}

public struct RouterBindingDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let scope: RouterBindingScope
    public let scopeID: String
    public let profileID: UUID

    public init(id: UUID, scope: RouterBindingScope, scopeID: String, profileID: UUID) {
        self.id = id
        self.scope = scope
        self.scopeID = scopeID
        self.profileID = profileID
    }
}

public struct RouterBindingPutRequest: Codable, Sendable {
    public let profileID: UUID
    public init(profileID: UUID) {
        self.profileID = profileID
    }
}

public struct RouterBindingsResponse: Codable, Sendable {
    public let bindings: [RouterBindingDTO]
    public init(bindings: [RouterBindingDTO]) {
        self.bindings = bindings
    }
}

public struct RouterModelCatalogEntryDTO: Codable, Sendable, Equatable, Identifiable {
    public let provider: ProviderID
    public let model: String
    public let displayName: String
    public let taskQuality: [String: Int]
    public let inputPerMillionUsdMicros: Int64?
    public let outputPerMillionUsdMicros: Int64?
    public let defaultLatencyMs: Int
    public let capabilities: [String]
    /// Capability band used by Auto (Smart) tier floors. Defaults to `.balanced`.
    public let tier: RouterModelTier

    public var id: String {
        "\(provider.rawValue):\(model)"
    }

    public init(
        provider: ProviderID,
        model: String,
        displayName: String,
        taskQuality: [String: Int],
        inputPerMillionUsdMicros: Int64? = nil,
        outputPerMillionUsdMicros: Int64? = nil,
        defaultLatencyMs: Int,
        capabilities: [String] = [],
        tier: RouterModelTier = .balanced
    ) {
        self.provider = provider
        self.model = model
        self.displayName = displayName
        self.taskQuality = taskQuality
        self.inputPerMillionUsdMicros = inputPerMillionUsdMicros
        self.outputPerMillionUsdMicros = outputPerMillionUsdMicros
        self.defaultLatencyMs = defaultLatencyMs
        self.capabilities = capabilities
        self.tier = tier
    }

    private enum CodingKeys: String, CodingKey {
        case provider, model, displayName, taskQuality
        case inputPerMillionUsdMicros, outputPerMillionUsdMicros
        case defaultLatencyMs, capabilities, tier
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        provider = try c.decode(ProviderID.self, forKey: .provider)
        model = try c.decode(String.self, forKey: .model)
        displayName = try c.decode(String.self, forKey: .displayName)
        taskQuality = try c.decode([String: Int].self, forKey: .taskQuality)
        inputPerMillionUsdMicros = try c.decodeIfPresent(Int64.self, forKey: .inputPerMillionUsdMicros)
        outputPerMillionUsdMicros = try c.decodeIfPresent(Int64.self, forKey: .outputPerMillionUsdMicros)
        defaultLatencyMs = try c.decode(Int.self, forKey: .defaultLatencyMs)
        capabilities = try c.decodeIfPresent([String].self, forKey: .capabilities) ?? []
        tier = try c.decodeIfPresent(RouterModelTier.self, forKey: .tier) ?? .balanced
    }
}

public struct RouterCatalogResponse: Codable, Sendable {
    public let models: [RouterModelCatalogEntryDTO]
    public let taskTypes: [RouterTaskType]
    public let surfaces: [RouterSurface]
    public let customProfilesAllowed: Bool
    public let ensemblesAllowed: Bool

    public init(
        models: [RouterModelCatalogEntryDTO],
        taskTypes: [RouterTaskType] = RouterTaskType.allCases,
        surfaces: [RouterSurface] = RouterSurface.allCases,
        customProfilesAllowed: Bool,
        ensemblesAllowed: Bool
    ) {
        self.models = models
        self.taskTypes = taskTypes
        self.surfaces = surfaces
        self.customProfilesAllowed = customProfilesAllowed
        self.ensemblesAllowed = ensemblesAllowed
    }
}

public enum RouterEventPhase: String, Codable, Sendable {
    case selected
    case attemptStarted
    case synthesisStarted
    case completed
}

public struct RouterRoutingEventDTO: Codable, Sendable, Equatable {
    public let executionID: UUID
    public let phase: RouterEventPhase
    public let profileID: UUID
    public let profileName: String
    public let taskType: RouterTaskType
    public let strategy: RouterActionKind
    public let activeRoutes: [RouterModelRouteDTO]

    public init(
        executionID: UUID,
        phase: RouterEventPhase,
        profileID: UUID,
        profileName: String,
        taskType: RouterTaskType,
        strategy: RouterActionKind,
        activeRoutes: [RouterModelRouteDTO]
    ) {
        self.executionID = executionID
        self.phase = phase
        self.profileID = profileID
        self.profileName = profileName
        self.taskType = taskType
        self.strategy = strategy
        self.activeRoutes = activeRoutes
    }
}

public struct RouterUsageDTO: Codable, Sendable, Equatable {
    public let executionID: UUID
    public let provider: ProviderID?
    public let model: String?
    public let tokensIn: Int
    public let tokensOut: Int
    public let estimatedCostUsdMicros: Int64
    public let latencyMs: Int
    public let usageEstimated: Bool

    public init(
        executionID: UUID,
        provider: ProviderID? = nil,
        model: String? = nil,
        tokensIn: Int,
        tokensOut: Int,
        estimatedCostUsdMicros: Int64,
        latencyMs: Int,
        usageEstimated: Bool
    ) {
        self.executionID = executionID
        self.provider = provider
        self.model = model
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.estimatedCostUsdMicros = estimatedCostUsdMicros
        self.latencyMs = latencyMs
        self.usageEstimated = usageEstimated
    }
}

public struct RouterDashboardResponse: Codable, Sendable {
    public let periodStart: Date
    public let periodEnd: Date
    public let requests: Int
    public let successfulRequests: Int
    public let fallbackCount: Int
    public let tokensIn: Int
    public let tokensOut: Int
    public let estimatedCostUsdMicros: Int64
    public let averageLatencyMs: Int
    public let monthlySoftLimitUsdMicros: Int64?
    public let monthlyHardLimitUsdMicros: Int64?

    public init(
        periodStart: Date,
        periodEnd: Date,
        requests: Int,
        successfulRequests: Int,
        fallbackCount: Int,
        tokensIn: Int,
        tokensOut: Int,
        estimatedCostUsdMicros: Int64,
        averageLatencyMs: Int,
        monthlySoftLimitUsdMicros: Int64? = nil,
        monthlyHardLimitUsdMicros: Int64? = nil
    ) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.requests = requests
        self.successfulRequests = successfulRequests
        self.fallbackCount = fallbackCount
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.estimatedCostUsdMicros = estimatedCostUsdMicros
        self.averageLatencyMs = averageLatencyMs
        self.monthlySoftLimitUsdMicros = monthlySoftLimitUsdMicros
        self.monthlyHardLimitUsdMicros = monthlyHardLimitUsdMicros
    }
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
    /// Provider allow-list. Empty = all allowed; when non-empty the router
    /// only routes to providers in this set.
    public let allowedProviders: [ProviderID]
    /// Provider deny-list. The router never routes to these providers.
    public let blockedProviders: [ProviderID]
    /// Task-aware routing policy. Source of truth is the bound router profile;
    /// this field mirrors it for Settings UI convenience.
    public let routingPolicy: LLMRoutingPolicy
    public init(
        mode: LLMBrainMode = .managed,
        primaryProvider: ProviderID,
        primaryModel: String,
        fallbackChain: [ModelRouteDTO],
        allowedProviders: [ProviderID] = [],
        blockedProviders: [ProviderID] = [],
        routingPolicy: LLMRoutingPolicy = .autoSmart
    ) {
        self.mode = mode
        self.primaryProvider = primaryProvider
        self.primaryModel = primaryModel
        self.fallbackChain = fallbackChain
        self.allowedProviders = allowedProviders
        self.blockedProviders = blockedProviders
        self.routingPolicy = routingPolicy
    }

    private enum CodingKeys: String, CodingKey {
        case mode, primaryProvider, primaryModel, fallbackChain
        case allowedProviders, blockedProviders, routingPolicy
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decodeIfPresent(LLMBrainMode.self, forKey: .mode) ?? .managed
        primaryProvider = try c.decode(ProviderID.self, forKey: .primaryProvider)
        primaryModel = try c.decode(String.self, forKey: .primaryModel)
        fallbackChain = try c.decode([ModelRouteDTO].self, forKey: .fallbackChain)
        allowedProviders = try c.decodeIfPresent([ProviderID].self, forKey: .allowedProviders) ?? []
        blockedProviders = try c.decodeIfPresent([ProviderID].self, forKey: .blockedProviders) ?? []
        routingPolicy = try c.decodeIfPresent(LLMRoutingPolicy.self, forKey: .routingPolicy) ?? .autoSmart
    }
}

public struct LLMPreferencesPutRequest: Codable, Sendable {
    public let mode: LLMBrainMode
    public let primaryProvider: ProviderID
    public let primaryModel: String
    public let fallbackChain: [ModelRouteDTO]
    public let allowedProviders: [ProviderID]
    public let blockedProviders: [ProviderID]
    public let routingPolicy: LLMRoutingPolicy
    public init(
        mode: LLMBrainMode = .managed,
        primaryProvider: ProviderID,
        primaryModel: String,
        fallbackChain: [ModelRouteDTO],
        allowedProviders: [ProviderID] = [],
        blockedProviders: [ProviderID] = [],
        routingPolicy: LLMRoutingPolicy = .autoSmart
    ) {
        self.mode = mode
        self.primaryProvider = primaryProvider
        self.primaryModel = primaryModel
        self.fallbackChain = fallbackChain
        self.allowedProviders = allowedProviders
        self.blockedProviders = blockedProviders
        self.routingPolicy = routingPolicy
    }

    private enum CodingKeys: String, CodingKey {
        case mode, primaryProvider, primaryModel, fallbackChain
        case allowedProviders, blockedProviders, routingPolicy
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decodeIfPresent(LLMBrainMode.self, forKey: .mode) ?? .managed
        primaryProvider = try c.decode(ProviderID.self, forKey: .primaryProvider)
        primaryModel = try c.decode(String.self, forKey: .primaryModel)
        fallbackChain = try c.decode([ModelRouteDTO].self, forKey: .fallbackChain)
        allowedProviders = try c.decodeIfPresent([ProviderID].self, forKey: .allowedProviders) ?? []
        blockedProviders = try c.decodeIfPresent([ProviderID].self, forKey: .blockedProviders) ?? []
        routingPolicy = try c.decodeIfPresent(LLMRoutingPolicy.self, forKey: .routingPolicy) ?? .autoSmart
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
    public init(options: AnyJSONValue) {
        self.options = options
    }
}

public struct WebAuthnAttestationResponseDTO: Codable, Sendable {
    public let attestationObject: String // base64url
    public let clientDataJSON: String // base64url
    public init(attestationObject: String, clientDataJSON: String) {
        self.attestationObject = attestationObject
        self.clientDataJSON = clientDataJSON
    }
}

public struct WebAuthnRegistrationCredentialDTO: Codable, Sendable {
    public let id: String // base64url credential ID
    public let rawId: String // base64url credential ID (raw bytes)
    public let type: String // "public-key"
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
    public init(credentialID: String) {
        self.credentialID = credentialID
    }
}

public struct WebAuthnBeginAuthenticationRequest: Codable, Sendable {
    public let username: String
    public init(username: String) {
        self.username = username
    }
}

public struct WebAuthnBeginAuthenticationResponse: Codable, Sendable {
    public let options: AnyJSONValue
    public init(options: AnyJSONValue) {
        self.options = options
    }
}

public struct WebAuthnAssertionResponseDTO: Codable, Sendable {
    public let authenticatorData: String // base64url
    public let clientDataJSON: String // base64url
    public let signature: String // base64url
    public let userHandle: String? // base64url, optional

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
    public let id: String // base64url credential ID
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
    public var id: UUID {
        jobID
    }

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
        case .step: self = try .step(c.decode(HermesUpdateStep.self, forKey: .payload))
        case .status: self = try .status(c.decode(HermesUpdateJobState.self, forKey: .payload))
        case .done: self = try .done(c.decode(HermesUpdateJobStatus.self, forKey: .payload))
        case .error: self = try .error(c.decode(String.self, forKey: .payload))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .step(s):
            try c.encode(EventType.step, forKey: .type)
            try c.encode(s, forKey: .payload)
        case let .status(st):
            try c.encode(EventType.status, forKey: .type)
            try c.encode(st, forKey: .payload)
        case let .done(snapshot):
            try c.encode(EventType.done, forKey: .type)
            try c.encode(snapshot, forKey: .payload)
        case let .error(message):
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
    public var id: String {
        slug
    }

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
    public init(items: [PluginCatalogEntryDTO]) {
        self.items = items
    }
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
    public let marketplaceVersionId: UUID?
    public let grantedPermissions: [PluginPermission]

    public init(
        id: UUID,
        pluginSlug: String,
        status: PluginInstallStatus,
        hasConfig: Bool,
        createdAt: Date? = nil,
        lastSyncAt: Date? = nil,
        marketplaceVersionId: UUID? = nil,
        grantedPermissions: [PluginPermission] = []
    ) {
        self.id = id
        self.pluginSlug = pluginSlug
        self.status = status
        self.hasConfig = hasConfig
        self.createdAt = createdAt
        self.lastSyncAt = lastSyncAt
        self.marketplaceVersionId = marketplaceVersionId
        self.grantedPermissions = grantedPermissions
    }
}

public struct PluginInstallsListResponse: Codable, Sendable {
    public let items: [PluginInstallDTO]
    public init(items: [PluginInstallDTO]) {
        self.items = items
    }
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

// ─── Marketplace (HER-43 public ecosystem) ──────────────────────────────────

public enum MarketplacePluginStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case inReview = "in_review"
    case published
    case suspended
}

public enum MarketplaceVersionStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case validating
    case inReview = "in_review"
    case approved
    case rejected
    case revoked
}

public enum MarketplaceRuntimeKind: String, Codable, Sendable, CaseIterable {
    case native
    case declarative
    case wasm
}

public enum PluginPermission: String, Codable, Sendable, CaseIterable, Hashable {
    case memoryRead = "memory.read"
    case memoryWrite = "memory.write"
    case vaultRead = "vault.read"
    case vaultWrite = "vault.write"
    case networkFetch = "network.fetch"
    case outputEmit = "output.emit"
}

public struct MarketplacePublisherDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let handle: String
    public let displayName: String
    public let bio: String?
    public let websiteURL: String?
    public let verified: Bool
    public let status: String?

    public init(id: UUID, handle: String, displayName: String, bio: String? = nil, websiteURL: String? = nil, verified: Bool, status: String? = nil) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.bio = bio
        self.websiteURL = websiteURL
        self.verified = verified
        self.status = status
    }
}

public struct MarketplacePublishersResponse: Codable, Sendable {
    public let items: [MarketplacePublisherDTO]
    public init(items: [MarketplacePublisherDTO]) {
        self.items = items
    }
}

public struct MarketplaceToolManifest: Codable, Sendable, Identifiable, Equatable {
    public var id: String {
        name
    }

    public let name: String
    public let description: String
    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

public struct MarketplacePluginManifest: Codable, Sendable, Equatable {
    public let schemaVersion: Int
    public let tools: [MarketplaceToolManifest]
    public init(schemaVersion: Int = 1, tools: [MarketplaceToolManifest]) {
        self.schemaVersion = schemaVersion
        self.tools = tools
    }
}

public struct MarketplaceVersionDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let version: String
    public let status: MarketplaceVersionStatus
    public let runtimeKind: MarketplaceRuntimeKind
    public let permissions: [PluginPermission]
    public let networkHosts: [String]
    public let changelog: String?
    public let publishedAt: Date?
    public let tools: [MarketplaceToolManifest]?

    public init(id: UUID, version: String, status: MarketplaceVersionStatus, runtimeKind: MarketplaceRuntimeKind, permissions: [PluginPermission], networkHosts: [String] = [], changelog: String? = nil, publishedAt: Date? = nil, tools: [MarketplaceToolManifest]? = nil) {
        self.id = id
        self.version = version
        self.status = status
        self.runtimeKind = runtimeKind
        self.permissions = permissions
        self.networkHosts = networkHosts
        self.changelog = changelog
        self.publishedAt = publishedAt
        self.tools = tools
    }
}

public struct MarketplaceRevokeVersionRequest: Codable, Sendable {
    public let reason: String
    public init(reason: String) {
        self.reason = reason
    }
}

public struct MarketplacePluginDTO: Codable, Sendable, Identifiable, Equatable {
    public var id: String {
        slug
    }

    public let slug: String
    public let name: String
    public let summary: String
    public let description: String
    public let category: PluginCategory
    public let iconURL: String?
    public let screenshots: [String]
    public let publisher: MarketplacePublisherDTO
    public let latestVersion: MarketplaceVersionDTO
    public let featured: Bool
    public let ratingAverage: Double
    public let ratingCount: Int
    public let installCount: Int
    public let configFields: [PluginConfigField]

    public init(slug: String, name: String, summary: String, description: String, category: PluginCategory, iconURL: String? = nil, screenshots: [String] = [], publisher: MarketplacePublisherDTO, latestVersion: MarketplaceVersionDTO, featured: Bool = false, ratingAverage: Double = 0, ratingCount: Int = 0, installCount: Int = 0, configFields: [PluginConfigField] = []) {
        self.slug = slug
        self.name = name
        self.summary = summary
        self.description = description
        self.category = category
        self.iconURL = iconURL
        self.screenshots = screenshots
        self.publisher = publisher
        self.latestVersion = latestVersion
        self.featured = featured
        self.ratingAverage = ratingAverage
        self.ratingCount = ratingCount
        self.installCount = installCount
        self.configFields = configFields
    }
}

public struct MarketplaceListResponse: Codable, Sendable {
    public let items: [MarketplacePluginDTO]
    public let nextCursor: String?
    public init(items: [MarketplacePluginDTO], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public struct MarketplaceReviewDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let rating: Int
    public let body: String?
    public let authorUsername: String
    public let verifiedInstall: Bool
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(id: UUID, rating: Int, body: String? = nil, authorUsername: String, verifiedInstall: Bool, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.rating = rating
        self.body = body
        self.authorUsername = authorUsername
        self.verifiedInstall = verifiedInstall
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MarketplaceReviewsResponse: Codable, Sendable {
    public let items: [MarketplaceReviewDTO]
    public init(items: [MarketplaceReviewDTO]) {
        self.items = items
    }
}

public struct MarketplaceRatingRequest: Codable, Sendable {
    public let rating: Int
    public let body: String?
    public init(rating: Int, body: String? = nil) {
        self.rating = rating
        self.body = body
    }
}

public struct MarketplaceInstallRequest: Codable, Sendable {
    public let versionId: UUID
    public let grantedPermissions: [PluginPermission]
    public let config: [String: String]
    public init(versionId: UUID, grantedPermissions: [PluginPermission], config: [String: String] = [:]) {
        self.versionId = versionId
        self.grantedPermissions = grantedPermissions
        self.config = config
    }
}

public struct MarketplaceUpgradeRequest: Codable, Sendable {
    public let fromVersionId: UUID
    public let toVersionId: UUID
    public let grantedPermissions: [PluginPermission]
    public let config: [String: String]

    public init(
        fromVersionId: UUID,
        toVersionId: UUID,
        grantedPermissions: [PluginPermission],
        config: [String: String] = [:]
    ) {
        self.fromVersionId = fromVersionId
        self.toVersionId = toVersionId
        self.grantedPermissions = grantedPermissions
        self.config = config
    }
}

public struct PublisherApplicationRequest: Codable, Sendable {
    public let handle: String
    public let displayName: String
    public let bio: String?
    public let websiteURL: String?
    public init(handle: String, displayName: String, bio: String? = nil, websiteURL: String? = nil) {
        self.handle = handle
        self.displayName = displayName
        self.bio = bio
        self.websiteURL = websiteURL
    }
}

public struct MarketplaceSubmissionDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let pluginSlug: String
    public let versionId: UUID
    public let status: MarketplaceVersionStatus
    public let validationErrors: [String]
    public let reviewNote: String?
    public let submittedAt: Date?
    public let reviewedAt: Date?

    public init(id: UUID, pluginSlug: String, versionId: UUID, status: MarketplaceVersionStatus, validationErrors: [String] = [], reviewNote: String? = nil, submittedAt: Date? = nil, reviewedAt: Date? = nil) {
        self.id = id
        self.pluginSlug = pluginSlug
        self.versionId = versionId
        self.status = status
        self.validationErrors = validationErrors
        self.reviewNote = reviewNote
        self.submittedAt = submittedAt
        self.reviewedAt = reviewedAt
    }
}

public struct MarketplaceModerationRequest: Codable, Sendable {
    public let approved: Bool
    public let note: String?
    public init(approved: Bool, note: String? = nil) {
        self.approved = approved
        self.note = note
    }
}

public struct PluginToolRunRequest: Codable, Sendable {
    public let input: [String: String]
    public init(input: [String: String] = [:]) {
        self.input = input
    }
}

public struct PluginToolRunResponse: Codable, Sendable {
    public let runId: UUID
    public let output: [String: String]
    public let fuelConsumed: Int
    public init(runId: UUID, output: [String: String], fuelConsumed: Int) {
        self.runId = runId
        self.output = output
        self.fuelConsumed = fuelConsumed
    }
}

public struct MarketplaceArtifactUploadRequest: Codable, Sendable {
    public let fileName: String
    public let bytesBase64: String
    public init(fileName: String, bytesBase64: String) {
        self.fileName = fileName
        self.bytesBase64 = bytesBase64
    }
}

public struct MarketplaceArtifactUploadResponse: Codable, Sendable {
    public let artifactKey: String
    public let sha256: String
    public let sizeBytes: Int
    public let signature: String

    public init(artifactKey: String, sha256: String, sizeBytes: Int, signature: String) {
        self.artifactKey = artifactKey
        self.sha256 = sha256
        self.sizeBytes = sizeBytes
        self.signature = signature
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

/// HER-55 — chat→reminder detection. The server classifier inspects a chat
/// turn for "remind me…" intent and, when present, returns a structured
/// proposal the client surfaces as a confirm card (mirrors `JobProposalDTO`).
/// Fails closed: `isReminder == false` means "this was not a reminder request".
public struct ReminderProposalDTO: Codable, Sendable {
    public let isReminder: Bool
    public let title: String?
    public let body: String?
    /// Absolute fire time the classifier resolved from natural language
    /// (e.g. "tomorrow at 5pm"), in UTC. Nil when not a reminder.
    public let fireAt: Date?
    /// Optional cron for recurring reminders (nil = one-shot).
    public let recurrenceCron: String?
    /// Human-readable schedule for the card, e.g. "Tomorrow at 5:00 PM".
    public let scheduleHuman: String?

    public init(
        isReminder: Bool,
        title: String? = nil,
        body: String? = nil,
        fireAt: Date? = nil,
        recurrenceCron: String? = nil,
        scheduleHuman: String? = nil
    ) {
        self.isReminder = isReminder; self.title = title; self.body = body
        self.fireAt = fireAt; self.recurrenceCron = recurrenceCron
        self.scheduleHuman = scheduleHuman
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

// ─── Usage intelligence dashboard ─────────────────────────────────────────

public enum AnalyticsRange: String, Codable, Sendable, CaseIterable {
    case week = "7d"
    case month = "30d"
    case quarter = "90d"

    public var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        }
    }
}

public enum AnalyticsScope: String, Codable, Sendable, CaseIterable {
    case personal
    case active
}

public struct AnalyticsDailyPointDTO: Codable, Sendable, Equatable {
    public let date: Date
    public let sessions: Int
    public let aiRequests: Int
    public let tokens: Int
    public let captures: Int
    public let retrievals: Int
    public let estimatedCostUsdMicros: Int64

    public init(date: Date, sessions: Int = 0, aiRequests: Int = 0, tokens: Int = 0,
                captures: Int = 0, retrievals: Int = 0, estimatedCostUsdMicros: Int64 = 0)
    {
        self.date = date
        self.sessions = sessions
        self.aiRequests = aiRequests
        self.tokens = tokens
        self.captures = captures
        self.retrievals = retrievals
        self.estimatedCostUsdMicros = estimatedCostUsdMicros
    }
}

public struct AnalyticsSummaryDTO: Codable, Sendable, Equatable {
    public let sessions: Int
    public let aiRequests: Int
    public let tokensIn: Int
    public let tokensOut: Int
    public let captures: Int
    public let retrievals: Int
    public let estimatedCostUsdMicros: Int64

    public init(sessions: Int = 0, aiRequests: Int = 0, tokensIn: Int = 0, tokensOut: Int = 0,
                captures: Int = 0, retrievals: Int = 0, estimatedCostUsdMicros: Int64 = 0)
    {
        self.sessions = sessions
        self.aiRequests = aiRequests
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.captures = captures
        self.retrievals = retrievals
        self.estimatedCostUsdMicros = estimatedCostUsdMicros
    }
}

public struct MemoryHealthComponentDTO: Codable, Sendable, Equatable {
    public let key: String
    public let title: String
    public let score: Int
    public let weight: Int

    public init(key: String, title: String, score: Int, weight: Int) {
        self.key = key
        self.title = title
        self.score = score
        self.weight = weight
    }
}

public struct MemoryHealthDTO: Codable, Sendable, Equatable {
    public let score: Int
    public let totalMemories: Int
    public let staleCount: Int
    public let neverRetrievedCount: Int
    public let unorganizedCount: Int
    public let pendingReviewCount: Int
    public let components: [MemoryHealthComponentDTO]

    public init(score: Int, totalMemories: Int, staleCount: Int, neverRetrievedCount: Int,
                unorganizedCount: Int, pendingReviewCount: Int,
                components: [MemoryHealthComponentDTO])
    {
        self.score = score
        self.totalMemories = totalMemories
        self.staleCount = staleCount
        self.neverRetrievedCount = neverRetrievedCount
        self.unorganizedCount = unorganizedCount
        self.pendingReviewCount = pendingReviewCount
        self.components = components
    }
}

public enum AnalyticsRecommendationSeverity: String, Codable, Sendable {
    case info, attention, important
}

public struct AnalyticsRecommendationDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let severity: AnalyticsRecommendationSeverity
    public let actionTitle: String
    public let deepLink: String

    public init(id: String, title: String, detail: String, severity: AnalyticsRecommendationSeverity,
                actionTitle: String, deepLink: String)
    {
        self.id = id
        self.title = title
        self.detail = detail
        self.severity = severity
        self.actionTitle = actionTitle
        self.deepLink = deepLink
    }
}

public struct AnalyticsOverviewResponse: Codable, Sendable {
    public let scope: AnalyticsScope
    public let vaultId: UUID
    public let range: AnalyticsRange
    public let periodStart: Date
    public let periodEnd: Date
    public let summary: AnalyticsSummaryDTO
    public let daily: [AnalyticsDailyPointDTO]
    public let memoryHealth: MemoryHealthDTO
    public let recommendations: [AnalyticsRecommendationDTO]

    public init(scope: AnalyticsScope, vaultId: UUID, range: AnalyticsRange, periodStart: Date,
                periodEnd: Date, summary: AnalyticsSummaryDTO, daily: [AnalyticsDailyPointDTO],
                memoryHealth: MemoryHealthDTO, recommendations: [AnalyticsRecommendationDTO])
    {
        self.scope = scope
        self.vaultId = vaultId
        self.range = range
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.summary = summary
        self.daily = daily
        self.memoryHealth = memoryHealth
        self.recommendations = recommendations
    }
}

public struct ModelEffectivenessDTO: Codable, Sendable, Equatable, Identifiable {
    public var id: String {
        "\(provider):\(model)"
    }

    public let provider: String
    public let model: String
    public let requests: Int
    public let successRate: Double
    public let fallbackRate: Double
    public let averageLatencyMs: Int
    public let p95LatencyMs: Int
    public let tokens: Int
    public let estimatedCostUsdMicros: Int64
    public let positiveFeedback: Int?
    public let negativeFeedback: Int?
    public let satisfactionRate: Double?

    public init(provider: String, model: String, requests: Int, successRate: Double,
                fallbackRate: Double, averageLatencyMs: Int, p95LatencyMs: Int,
                tokens: Int, estimatedCostUsdMicros: Int64,
                positiveFeedback: Int? = nil, negativeFeedback: Int? = nil,
                satisfactionRate: Double? = nil)
    {
        self.provider = provider
        self.model = model
        self.requests = requests
        self.successRate = successRate
        self.fallbackRate = fallbackRate
        self.averageLatencyMs = averageLatencyMs
        self.p95LatencyMs = p95LatencyMs
        self.tokens = tokens
        self.estimatedCostUsdMicros = estimatedCostUsdMicros
        self.positiveFeedback = positiveFeedback
        self.negativeFeedback = negativeFeedback
        self.satisfactionRate = satisfactionRate
    }
}

public struct ModelEffectivenessResponse: Codable, Sendable {
    public let range: AnalyticsRange
    public let models: [ModelEffectivenessDTO]
    public init(range: AnalyticsRange, models: [ModelEffectivenessDTO]) {
        self.range = range
        self.models = models
    }
}

public enum ModelFeedbackRating: String, Codable, Sendable {
    case positive, negative
}

public struct ModelFeedbackRequest: Codable, Sendable {
    public let provider: String
    public let model: String
    public let rating: ModelFeedbackRating
    public let idempotencyKey: String?

    public init(provider: String, model: String, rating: ModelFeedbackRating,
                idempotencyKey: String? = nil)
    {
        self.provider = provider
        self.model = model
        self.rating = rating
        self.idempotencyKey = idempotencyKey
    }
}

public struct TeamMemberAnalyticsDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let displayName: String
    public let captures: Int
    public let retrievals: Int
    public let aiRequests: Int
    public let tokens: Int
    public let estimatedCostUsdMicros: Int64

    public init(id: UUID, displayName: String, captures: Int, retrievals: Int,
                aiRequests: Int, tokens: Int, estimatedCostUsdMicros: Int64)
    {
        self.id = id
        self.displayName = displayName
        self.captures = captures
        self.retrievals = retrievals
        self.aiRequests = aiRequests
        self.tokens = tokens
        self.estimatedCostUsdMicros = estimatedCostUsdMicros
    }
}

public struct TeamAnalyticsResponse: Codable, Sendable {
    public let vaultId: UUID
    public let range: AnalyticsRange
    public let summary: AnalyticsSummaryDTO
    /// Present only for team owners/admins; omitted for ordinary members.
    public let members: [TeamMemberAnalyticsDTO]?

    public init(vaultId: UUID, range: AnalyticsRange, summary: AnalyticsSummaryDTO,
                members: [TeamMemberAnalyticsDTO]? = nil)
    {
        self.vaultId = vaultId
        self.range = range
        self.summary = summary
        self.members = members
    }
}

public enum AnalyticsClientEventName: String, Codable, Sendable, CaseIterable {
    case dashboardViewed = "analytics_dashboard_viewed"
    case rangeChanged = "analytics_range_changed"
    case recommendationOpened = "analytics_recommendation_opened"
    case recommendationDismissed = "analytics_recommendation_dismissed"
    case recommendationSnoozed = "analytics_recommendation_snoozed"
}

public enum AnalyticsEventSource: String, Codable, Sendable {
    case ios, web
}

public struct AnalyticsEventRequest: Codable, Sendable {
    public let name: AnalyticsClientEventName
    public let source: AnalyticsEventSource
    public let range: AnalyticsRange?
    public let recommendationId: String?
    public let idempotencyKey: String?

    public init(name: AnalyticsClientEventName, source: AnalyticsEventSource,
                range: AnalyticsRange? = nil, recommendationId: String? = nil,
                idempotencyKey: String? = nil)
    {
        self.name = name
        self.source = source
        self.range = range
        self.recommendationId = recommendationId
        self.idempotencyKey = idempotencyKey
    }
}

public enum AnalyticsRecommendationDisposition: String, Codable, Sendable {
    case dismiss, snooze7, snooze30
}

public struct AnalyticsRecommendationStateRequest: Codable, Sendable {
    public let recommendationId: String
    public let disposition: AnalyticsRecommendationDisposition
    public init(recommendationId: String, disposition: AnalyticsRecommendationDisposition) {
        self.recommendationId = recommendationId
        self.disposition = disposition
    }
}

public struct AnalyticsMutationResponse: Codable, Sendable {
    public let accepted: Bool
    public init(accepted: Bool = true) {
        self.accepted = accepted
    }
}

public struct MemoryReviewResponse: Codable, Sendable {
    public let memoryId: UUID
    public let reviewedAt: Date
    public let reviewCount: Int
    public init(memoryId: UUID, reviewedAt: Date, reviewCount: Int) {
        self.memoryId = memoryId
        self.reviewedAt = reviewedAt
        self.reviewCount = reviewCount
    }
}

// ─── Home aggregate (HER-Home / Command Center) ───────────────────────────
// One-shot payload for the Home Command Center: counts, active model, power
// progress, skill names, and live active jobs. Avoids N round-trips.

public struct HomeSummaryResponse: Codable, Sendable {
    public let skillsCount: Int
    /// Lifetime skill-run count (historical). Prefer `activeJobsCount` for live work.
    public let jobsCount: Int
    public let remindersCount: Int
    public let todosCount: Int
    public let projectsCount: Int
    public let insightsCount: Int
    public let activeProfileName: String?
    public let activeProfileSlug: String?
    /// Active brain model (e.g. `openRouter`). Nil when using deploy defaults with no row.
    public let primaryProvider: String?
    /// Active model id (e.g. `qwen/qwen-2.5-72b-instruct`).
    public let primaryModel: String?
    /// Whether the tenant has a usable agent profile / recent activity signal.
    public let agentOnline: Bool
    public let memoriesToday: Int
    public let memoriesTotal: Int
    public let sessionsCount: Int
    /// Running + queued agent work (workflows, gateway apply, …).
    public let activeJobsCount: Int
    public let activeJobs: [TaskDTO]
    /// Enabled skill names (preview, capped server-side).
    public let skills: [String]
    public let powerLevel: Int
    public let powerXP: Int
    public let badgesEarned: Int
    public let streakDays: Int
    /// Small brain-graph sample (top nodes by activity, capped server-side)
    /// for the Home hero preview. Nil when no layout has been computed yet.
    public let graphPreview: [GraphPreviewNodeDTO]?

    public init(
        skillsCount: Int,
        jobsCount: Int,
        remindersCount: Int,
        todosCount: Int,
        projectsCount: Int,
        insightsCount: Int,
        activeProfileName: String? = nil,
        activeProfileSlug: String? = nil,
        primaryProvider: String? = nil,
        primaryModel: String? = nil,
        agentOnline: Bool = true,
        memoriesToday: Int = 0,
        memoriesTotal: Int = 0,
        sessionsCount: Int = 0,
        activeJobsCount: Int = 0,
        activeJobs: [TaskDTO] = [],
        skills: [String] = [],
        powerLevel: Int = 1,
        powerXP: Int = 0,
        badgesEarned: Int = 0,
        streakDays: Int = 0,
        graphPreview: [GraphPreviewNodeDTO]? = nil
    ) {
        self.skillsCount = skillsCount
        self.jobsCount = jobsCount
        self.remindersCount = remindersCount
        self.todosCount = todosCount
        self.projectsCount = projectsCount
        self.insightsCount = insightsCount
        self.activeProfileName = activeProfileName
        self.activeProfileSlug = activeProfileSlug
        self.primaryProvider = primaryProvider
        self.primaryModel = primaryModel
        self.agentOnline = agentOnline
        self.memoriesToday = memoriesToday
        self.memoriesTotal = memoriesTotal
        self.sessionsCount = sessionsCount
        self.activeJobsCount = activeJobsCount
        self.activeJobs = activeJobs
        self.skills = skills
        self.powerLevel = powerLevel
        self.powerXP = powerXP
        self.badgesEarned = badgesEarned
        self.streakDays = streakDays
        self.graphPreview = graphPreview
    }

    /// Decode-tolerant: older servers omit Command Center fields; fill defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        skillsCount = try c.decode(Int.self, forKey: .skillsCount)
        jobsCount = try c.decode(Int.self, forKey: .jobsCount)
        remindersCount = try c.decode(Int.self, forKey: .remindersCount)
        todosCount = try c.decode(Int.self, forKey: .todosCount)
        projectsCount = try c.decode(Int.self, forKey: .projectsCount)
        insightsCount = try c.decode(Int.self, forKey: .insightsCount)
        activeProfileName = try c.decodeIfPresent(String.self, forKey: .activeProfileName)
        activeProfileSlug = try c.decodeIfPresent(String.self, forKey: .activeProfileSlug)
        primaryProvider = try c.decodeIfPresent(String.self, forKey: .primaryProvider)
        primaryModel = try c.decodeIfPresent(String.self, forKey: .primaryModel)
        agentOnline = try c.decodeIfPresent(Bool.self, forKey: .agentOnline) ?? true
        memoriesToday = try c.decodeIfPresent(Int.self, forKey: .memoriesToday) ?? 0
        memoriesTotal = try c.decodeIfPresent(Int.self, forKey: .memoriesTotal) ?? 0
        sessionsCount = try c.decodeIfPresent(Int.self, forKey: .sessionsCount) ?? 0
        activeJobsCount = try c.decodeIfPresent(Int.self, forKey: .activeJobsCount) ?? 0
        activeJobs = try c.decodeIfPresent([TaskDTO].self, forKey: .activeJobs) ?? []
        skills = try c.decodeIfPresent([String].self, forKey: .skills) ?? []
        powerLevel = try c.decodeIfPresent(Int.self, forKey: .powerLevel) ?? 1
        powerXP = try c.decodeIfPresent(Int.self, forKey: .powerXP) ?? 0
        badgesEarned = try c.decodeIfPresent(Int.self, forKey: .badgesEarned) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        graphPreview = try c.decodeIfPresent([GraphPreviewNodeDTO].self, forKey: .graphPreview)
    }
}

/// One node of the Home brain-graph preview. Positions come from the
/// precomputed layout (`GraphLayoutWorker`, M85), normalized to roughly [-1, 1].
public struct GraphPreviewNodeDTO: Codable, Sendable, Equatable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        case memory, concept
    }

    public let id: UUID
    public let label: String
    public let x: Double
    public let y: Double
    public let z: Double
    /// Relative recall/activity weight in [0, 1]; drives node size/glow.
    public let activity: Double
    public let kind: Kind

    public init(id: UUID, label: String, x: Double, y: Double, z: Double,
                activity: Double, kind: Kind = .memory)
    {
        self.id = id; self.label = label
        self.x = x; self.y = y; self.z = z
        self.activity = activity; self.kind = kind
    }
}

// ─── Home activity feed (HER-Home / Command Center) ───────────────────────
// Unified recent-activity stream: conversations, memories, achievements,
// skill runs. Read-only union; each item deep-links by kind client-side.

public enum ActivityFeedItemKind: String, Codable, Sendable, CaseIterable {
    case conversation
    case memory
    case achievement
    case skillRun
}

public struct ActivityFeedItemDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let kind: ActivityFeedItemKind
    public let title: String
    public let subtitle: String?
    public let occurredAt: Date

    public init(id: UUID, kind: ActivityFeedItemKind, title: String,
                subtitle: String? = nil, occurredAt: Date)
    {
        self.id = id; self.kind = kind; self.title = title
        self.subtitle = subtitle; self.occurredAt = occurredAt
    }
}

public struct ActivityFeedResponse: Codable, Sendable {
    public let items: [ActivityFeedItemDTO]

    public init(items: [ActivityFeedItemDTO]) {
        self.items = items
    }
}

// ─── Retrieval health (M107/M108 read surface) ────────────────────────────
// Aggregate recall-quality stats for the dashboard "recall health" tile.

public struct RetrievalHealthResponse: Codable, Sendable {
    public enum Trend: String, Codable, Sendable {
        case improving, steady, declining
    }

    /// Share of retrieval events (last 7 days) whose results were actually
    /// used/grounded, in [0, 1]. Nil when no events were recorded.
    public let hitRate: Double?
    /// Mean cosine distance of the best hit per retrieval (lower = closer).
    public let meanTopDistance: Double?
    /// Events recorded over the window.
    public let eventsCount: Int
    /// Open leaks from the latest weekly leak report.
    public let leakCount: Int
    public let trend: Trend

    public init(hitRate: Double? = nil, meanTopDistance: Double? = nil,
                eventsCount: Int = 0, leakCount: Int = 0, trend: Trend = .steady)
    {
        self.hitRate = hitRate; self.meanTopDistance = meanTopDistance
        self.eventsCount = eventsCount; self.leakCount = leakCount
        self.trend = trend
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
    public let createdByUserId: UUID?
    public let updatedByUserId: UUID?

    public init(id: UUID, columnID: UUID, title: String, body: String?,
                priority: CardPriority?, dueAt: Date?, rank: String, updatedAt: Date?,
                jobConfig: CardJobConfigDTO? = nil,
                createdByUserId: UUID? = nil, updatedByUserId: UUID? = nil)
    {
        self.id = id; self.columnID = columnID; self.title = title; self.body = body
        self.priority = priority; self.dueAt = dueAt; self.rank = rank; self.updatedAt = updatedAt
        self.jobConfig = jobConfig
        self.createdByUserId = createdByUserId; self.updatedByUserId = updatedByUserId
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
                jobSlug: String? = nil, promotedAt: Date? = nil)
    {
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
                prompt: String? = nil, spaceID: UUID? = nil)
    {
        self.cron = cron; self.runAt = runAt; self.domain = domain
        self.prompt = prompt; self.spaceID = spaceID
    }
}

public struct ColumnDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let rank: String
    public let cards: [CardDTO] // pre-sorted by rank ascending

    public init(id: UUID, title: String, rank: String, cards: [CardDTO]) {
        self.id = id; self.title = title; self.rank = rank; self.cards = cards
    }
}

public struct BoardDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let version: Int64
    public let columns: [ColumnDTO] // pre-sorted by rank ascending
    public let createdByUserId: UUID?
    public let updatedByUserId: UUID?

    public init(id: UUID, title: String, version: Int64, columns: [ColumnDTO], createdByUserId: UUID? = nil, updatedByUserId: UUID? = nil) {
        self.id = id; self.title = title; self.version = version; self.columns = columns
        self.createdByUserId = createdByUserId; self.updatedByUserId = updatedByUserId
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
    public init(version: Int64) {
        self.version = version
    }
}

// MARK: - Teams and shared vaults

public enum TeamRole: String, Codable, Sendable, CaseIterable {
    case owner, admin, member
}

public enum VaultRole: String, Codable, Sendable, CaseIterable {
    case viewer, editor, admin
}

public struct VaultPermissionsDTO: Codable, Sendable, Equatable {
    public let canRead: Bool
    public let canWrite: Bool
    public let canAdmin: Bool
    public let canUseAI: Bool

    public init(canRead: Bool, canWrite: Bool, canAdmin: Bool, canUseAI: Bool) {
        self.canRead = canRead
        self.canWrite = canWrite
        self.canAdmin = canAdmin
        self.canUseAI = canUseAI
    }
}

public struct TeamDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let role: TeamRole
    public let archivedAt: Date?
    public let createdAt: Date?

    public init(id: UUID, name: String, role: TeamRole, archivedAt: Date? = nil, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.role = role
        self.archivedAt = archivedAt
        self.createdAt = createdAt
    }
}

public struct VaultSummaryDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let teamId: UUID?
    public let name: String
    public let isPersonal: Bool
    public let role: VaultRole
    public let permissions: VaultPermissionsDTO
    public let archivedAt: Date?

    public init(id: UUID, teamId: UUID? = nil, name: String, isPersonal: Bool,
                role: VaultRole, permissions: VaultPermissionsDTO, archivedAt: Date? = nil)
    {
        self.id = id
        self.teamId = teamId
        self.name = name
        self.isPersonal = isPersonal
        self.role = role
        self.permissions = permissions
        self.archivedAt = archivedAt
    }
}

public struct VaultMemberDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let username: String
    public let email: String?
    public let role: VaultRole
    public let canUseAI: Bool

    public init(id: UUID, userId: UUID, username: String, email: String? = nil,
                role: VaultRole, canUseAI: Bool)
    {
        self.id = id
        self.userId = userId
        self.username = username
        self.email = email
        self.role = role
        self.canUseAI = canUseAI
    }
}

public struct TeamCreateRequest: Codable, Sendable {
    public let name: String
    public init(name: String) {
        self.name = name
    }
}

public struct SharedVaultCreateRequest: Codable, Sendable {
    public let name: String
    public init(name: String) {
        self.name = name
    }
}

public struct VaultMembershipUpdateRequest: Codable, Sendable {
    public let role: VaultRole
    public let canUseAI: Bool
    public init(role: VaultRole, canUseAI: Bool) {
        self.role = role
        self.canUseAI = canUseAI
    }
}

public struct TeamInviteRequest: Codable, Sendable {
    public let email: String
    public let vaultGrants: [UUID: VaultMembershipUpdateRequest]
    public init(email: String, vaultGrants: [UUID: VaultMembershipUpdateRequest]) {
        self.email = email
        self.vaultGrants = vaultGrants
    }
}

public struct TeamInvitationDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let teamId: UUID
    public let teamName: String
    public let email: String
    public let expiresAt: Date
    public let acceptedAt: Date?

    public init(id: UUID, teamId: UUID, teamName: String, email: String,
                expiresAt: Date, acceptedAt: Date? = nil)
    {
        self.id = id
        self.teamId = teamId
        self.teamName = teamName
        self.email = email
        self.expiresAt = expiresAt
        self.acceptedAt = acceptedAt
    }
}

public struct ActorSummaryDTO: Codable, Sendable, Equatable {
    public let userId: UUID?
    public let username: String
    public init(userId: UUID?, username: String) {
        self.userId = userId
        self.username = username
    }
}

public struct VaultActivityEventDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let vaultId: UUID
    public let actor: ActorSummaryDTO
    public let action: String
    public let targetType: String
    public let targetId: UUID?
    public let targetTitle: String?
    public let createdAt: Date

    public init(id: UUID, vaultId: UUID, actor: ActorSummaryDTO, action: String,
                targetType: String, targetId: UUID? = nil, targetTitle: String? = nil,
                createdAt: Date)
    {
        self.id = id
        self.vaultId = vaultId
        self.actor = actor
        self.action = action
        self.targetType = targetType
        self.targetId = targetId
        self.targetTitle = targetTitle
        self.createdAt = createdAt
    }
}

public struct VaultActivityListResponse: Codable, Sendable, Equatable {
    public let events: [VaultActivityEventDTO]
    public let nextCursor: UUID?
    public init(events: [VaultActivityEventDTO], nextCursor: UUID? = nil) {
        self.events = events
        self.nextCursor = nextCursor
    }
}

/// Requests
public struct BoardCreateRequest: Codable, Sendable {
    public let title: String
    public init(title: String) {
        self.title = title
    }
}

public struct BoardPatchRequest: Codable, Sendable {
    public let title: String?
    public let archived: Bool?
    public init(title: String? = nil, archived: Bool? = nil) {
        self.title = title; self.archived = archived
    }
}

public struct ColumnCreateRequest: Codable, Sendable {
    public let title: String
    public init(title: String) {
        self.title = title
    }
}

public struct ColumnPatchRequest: Codable, Sendable {
    public let title: String
    public init(title: String) {
        self.title = title
    }
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
                priority: CardPriority? = nil, dueAt: Date? = nil)
    {
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

// MARK: - Multimodal ingestion

public enum IngestionSourceKindDTO: String, Codable, Sendable, CaseIterable {
    case file
    case url
}

public enum IngestionItemStateDTO: String, Codable, Sendable, CaseIterable {
    case awaitingUpload = "awaiting_upload"
    case queued
    case extracting
    case analyzing
    case saving
    case blockedCapability = "blocked_capability"
    case completed
    case failed
    case cancelled
}

public struct IngestionCreateItemRequest: Codable, Sendable {
    public let kind: IngestionSourceKindDTO
    public let fileName: String?
    public let contentType: String?
    public let sizeBytes: Int64?
    public let sha256: String?
    public let url: String?

    public init(
        kind: IngestionSourceKindDTO,
        fileName: String? = nil,
        contentType: String? = nil,
        sizeBytes: Int64? = nil,
        sha256: String? = nil,
        url: String? = nil
    ) {
        self.kind = kind
        self.fileName = fileName
        self.contentType = contentType
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
        self.url = url
    }
}

public struct IngestionCreateRequest: Codable, Sendable {
    public let spaceID: UUID?
    public let items: [IngestionCreateItemRequest]

    public init(spaceID: UUID? = nil, items: [IngestionCreateItemRequest]) {
        self.spaceID = spaceID
        self.items = items
    }
}

public struct IngestionCredibilityDTO: Codable, Sendable, Equatable {
    public let score: Int?
    public let confidence: Double
    public let signals: [String]
    public let rationale: String
    public let version: String

    public init(score: Int?, confidence: Double, signals: [String], rationale: String, version: String) {
        self.score = score
        self.confidence = confidence
        self.signals = signals
        self.rationale = rationale
        self.version = version
    }
}

public struct IngestionEntityDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: String
    public let confidence: Double

    public init(id: UUID, name: String, type: String, confidence: Double) {
        self.id = id
        self.name = name
        self.type = type
        self.confidence = confidence
    }
}

public struct IngestionRelationshipDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let subjectEntityID: UUID
    public let predicate: String
    public let objectEntityID: UUID
    public let confidence: Double
    public let evidence: String?

    public init(
        id: UUID,
        subjectEntityID: UUID,
        predicate: String,
        objectEntityID: UUID,
        confidence: Double,
        evidence: String? = nil
    ) {
        self.id = id
        self.subjectEntityID = subjectEntityID
        self.predicate = predicate
        self.objectEntityID = objectEntityID
        self.confidence = confidence
        self.evidence = evidence
    }
}

public struct IngestionItemDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let batchID: UUID
    public let kind: IngestionSourceKindDTO
    public let state: IngestionItemStateDTO
    public let fileName: String?
    public let contentType: String?
    public let sizeBytes: Int64?
    public let uploadedBytes: Int64
    public let url: String?
    public let vaultFileID: UUID?
    public let memoryID: UUID?
    public let summary: String?
    public let error: String?
    public let credibility: IngestionCredibilityDTO?
    public let entities: [IngestionEntityDTO]
    public let relationships: [IngestionRelationshipDTO]
    public let contentSHA256: String?
    public let pipelineVersion: String?
    public let reusedFromItemID: UUID?
    public let graphReadyAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        batchID: UUID,
        kind: IngestionSourceKindDTO,
        state: IngestionItemStateDTO,
        fileName: String? = nil,
        contentType: String? = nil,
        sizeBytes: Int64? = nil,
        uploadedBytes: Int64 = 0,
        url: String? = nil,
        vaultFileID: UUID? = nil,
        memoryID: UUID? = nil,
        summary: String? = nil,
        error: String? = nil,
        credibility: IngestionCredibilityDTO? = nil,
        entities: [IngestionEntityDTO] = [],
        relationships: [IngestionRelationshipDTO] = [],
        contentSHA256: String? = nil,
        pipelineVersion: String? = nil,
        reusedFromItemID: UUID? = nil,
        graphReadyAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.batchID = batchID
        self.kind = kind
        self.state = state
        self.fileName = fileName
        self.contentType = contentType
        self.sizeBytes = sizeBytes
        self.uploadedBytes = uploadedBytes
        self.url = url
        self.vaultFileID = vaultFileID
        self.memoryID = memoryID
        self.summary = summary
        self.error = error
        self.credibility = credibility
        self.entities = entities
        self.relationships = relationships
        self.contentSHA256 = contentSHA256
        self.pipelineVersion = pipelineVersion
        self.reusedFromItemID = reusedFromItemID
        self.graphReadyAt = graphReadyAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum IngestionEventTypeDTO: String, Codable, Sendable {
    case snapshot
    case stateChanged = "state_changed"
    case progress
    case terminal
    case heartbeat
}

public struct IngestionEventDTO: Codable, Sendable, Identifiable {
    public let id: Int64
    public let batchID: UUID
    public let itemID: UUID?
    public let type: IngestionEventTypeDTO
    public let state: IngestionItemStateDTO?
    public let uploadedBytes: Int64?
    public let createdAt: Date

    public init(id: Int64, batchID: UUID, itemID: UUID? = nil, type: IngestionEventTypeDTO, state: IngestionItemStateDTO? = nil, uploadedBytes: Int64? = nil, createdAt: Date) {
        self.id = id
        self.batchID = batchID
        self.itemID = itemID
        self.type = type
        self.state = state
        self.uploadedBytes = uploadedBytes
        self.createdAt = createdAt
    }
}

public struct IngestionBatchDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let state: String
    public let total: Int
    public let completed: Int
    public let failed: Int
    public let chunkSizeBytes: Int
    public let items: [IngestionItemDTO]
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: UUID,
        state: String,
        total: Int,
        completed: Int,
        failed: Int,
        chunkSizeBytes: Int,
        items: [IngestionItemDTO],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.state = state
        self.total = total
        self.completed = completed
        self.failed = failed
        self.chunkSizeBytes = chunkSizeBytes
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct IngestionBatchListDTO: Codable, Sendable {
    public let batches: [IngestionBatchDTO]
    public init(batches: [IngestionBatchDTO]) {
        self.batches = batches
    }
}
