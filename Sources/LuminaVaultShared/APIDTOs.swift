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
    enum CodingKeys: String, CodingKey { case messages, model, temperature, stream, tools, tool_choice }
    public init(messages: [ChatMessage], model: String? = nil, temperature: Double? = nil, stream: Bool = false, tools: [ChatTool]? = nil, tool_choice: AnyJSONValue? = nil) {
        self.messages = messages; self.model = model; self.temperature = temperature
        self.stream = stream; self.tools = tools; self.tool_choice = tool_choice
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

// ─── Query ───────────────────────────────────────────────────────────────

public struct QueryHitDTO: Codable, Sendable {
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
    public init(summary: String, hits: [QueryHitDTO]) {
        self.summary = summary; self.hits = hits
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
    public init(
        id: UUID,
        headline: String,
        summary: String,
        section: InsightSection,
        createdAt: Date,
        sourceMemoryIDs: [UUID] = [],
        dismissed: Bool = false
    ) {
        self.id = id; self.headline = headline; self.summary = summary
        self.section = section; self.createdAt = createdAt
        self.sourceMemoryIDs = sourceMemoryIDs; self.dismissed = dismissed
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
