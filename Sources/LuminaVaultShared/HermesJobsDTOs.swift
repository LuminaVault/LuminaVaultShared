import Foundation

// ─── Hermes Mirror — Phase 2 "Collect": job runs, full job control, push webhook ───

/// Outcome of one Hermes cron run as LuminaVault collected it.
public enum HermesJobRunStatus: String, Codable, Sendable, CaseIterable {
    /// Hermes was still producing output when the run was listed; the run is
    /// collected again once it finishes.
    case running
    case ok
    case error
}

/// Token usage Hermes reported for a run, when it did.
public struct HermesJobRunTokensDTO: Codable, Sendable, Equatable {
    public let input: Int?
    public let output: Int?
    public init(input: Int? = nil, output: Int? = nil) {
        self.input = input
        self.output = output
    }
}

/// One collected run of a mirrored Hermes cron job
/// (`GET /v1/hermes/mirror/jobs/{id}/runs`).
public struct HermesJobRunDTO: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let hermesJobID: String
    /// Stable key on the Hermes side (`cron_<job>_<timestamp>` session id on
    /// a dashboard, output file stem on a managed Hermes, `push:<key>` for
    /// webhook deliveries). Unique per tenant.
    public let runKey: String
    public let status: HermesJobRunStatus
    public let startedAt: Date
    public let finishedAt: Date?
    /// Markdown the run produced (≤ 256 KiB; longer outputs are truncated).
    public let output: String?
    public let error: String?
    public let tokens: HermesJobRunTokensDTO?
    /// Vault path of the file the output was written to (`raw/jobs/<job>/<stamp>.md`).
    public let vaultFilePath: String?
    /// `skill_run_log` row that surfaces this run on the Today feed.
    public let skillRunLogID: UUID?
    public let collectedAt: Date?
    public init(
        id: UUID,
        hermesJobID: String,
        runKey: String,
        status: HermesJobRunStatus,
        startedAt: Date,
        finishedAt: Date? = nil,
        output: String? = nil,
        error: String? = nil,
        tokens: HermesJobRunTokensDTO? = nil,
        vaultFilePath: String? = nil,
        skillRunLogID: UUID? = nil,
        collectedAt: Date? = nil
    ) {
        self.id = id
        self.hermesJobID = hermesJobID
        self.runKey = runKey
        self.status = status
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.output = output
        self.error = error
        self.tokens = tokens
        self.vaultFilePath = vaultFilePath
        self.skillRunLogID = skillRunLogID
        self.collectedAt = collectedAt
    }
}

/// `GET /v1/hermes/mirror/jobs/{id}/runs` — newest first.
public struct HermesJobRunsResponse: Codable, Sendable, Equatable {
    public let hermesJobID: String
    public let runs: [HermesJobRunDTO]
    /// When the collector last pulled runs for this job.
    public let collectedAt: Date?
    public init(hermesJobID: String, runs: [HermesJobRunDTO], collectedAt: Date? = nil) {
        self.hermesJobID = hermesJobID
        self.runs = runs
        self.collectedAt = collectedAt
    }
}

/// `POST /v1/hermes/mirror/jobs` — the full Hermes `CronJobCreate` body.
/// `schedule` is a cron expression, interval (`every 2h`) or one-shot time;
/// `deliver` follows Hermes' grammar (`origin`, `local`, `all`,
/// `platform[:chat_id[:thread]]`, comma-separated).
public struct HermesJobCreateRequest: Codable, Sendable, Equatable {
    public let name: String
    public let schedule: String
    public let prompt: String?
    public let deliver: String?
    public let skills: [String]?
    public let model: String?
    public let provider: String?
    public let baseURL: String?
    public let script: String?
    public let contextFrom: [String]?
    public let enabledToolsets: [String]?
    public let workdir: String?
    public let noAgent: Bool?
    public init(
        name: String,
        schedule: String,
        prompt: String? = nil,
        deliver: String? = nil,
        skills: [String]? = nil,
        model: String? = nil,
        provider: String? = nil,
        baseURL: String? = nil,
        script: String? = nil,
        contextFrom: [String]? = nil,
        enabledToolsets: [String]? = nil,
        workdir: String? = nil,
        noAgent: Bool? = nil
    ) {
        self.name = name
        self.schedule = schedule
        self.prompt = prompt
        self.deliver = deliver
        self.skills = skills
        self.model = model
        self.provider = provider
        self.baseURL = baseURL
        self.script = script
        self.contextFrom = contextFrom
        self.enabledToolsets = enabledToolsets
        self.workdir = workdir
        self.noAgent = noAgent
    }
}

/// `PUT /v1/hermes/mirror/jobs/{id}` — partial update; only present fields
/// are sent to Hermes as `updates`. `enabled: false` pauses without
/// clearing the schedule; prefer the `pause`/`resume` routes for that.
public struct HermesJobUpdateRequest: Codable, Sendable, Equatable {
    public let name: String?
    public let schedule: String?
    public let prompt: String?
    public let deliver: String?
    public let skills: [String]?
    public let model: String?
    public let provider: String?
    public let baseURL: String?
    public let script: String?
    public let contextFrom: [String]?
    public let enabledToolsets: [String]?
    public let workdir: String?
    public let noAgent: Bool?
    public let enabled: Bool?
    public init(
        name: String? = nil,
        schedule: String? = nil,
        prompt: String? = nil,
        deliver: String? = nil,
        skills: [String]? = nil,
        model: String? = nil,
        provider: String? = nil,
        baseURL: String? = nil,
        script: String? = nil,
        contextFrom: [String]? = nil,
        enabledToolsets: [String]? = nil,
        workdir: String? = nil,
        noAgent: Bool? = nil,
        enabled: Bool? = nil
    ) {
        self.name = name
        self.schedule = schedule
        self.prompt = prompt
        self.deliver = deliver
        self.skills = skills
        self.model = model
        self.provider = provider
        self.baseURL = baseURL
        self.script = script
        self.contextFrom = contextFrom
        self.enabledToolsets = enabledToolsets
        self.workdir = workdir
        self.noAgent = noAgent
        self.enabled = enabled
    }

    public var isEmpty: Bool {
        name == nil && schedule == nil && prompt == nil && deliver == nil && skills == nil && model == nil
            && provider == nil && baseURL == nil && script == nil && contextFrom == nil && enabledToolsets == nil
            && workdir == nil && noAgent == nil && enabled == nil
    }
}

/// `POST /v1/hermes/mirror/jobs/{id}/collect` and the webhook push path.
public struct HermesJobCollectResultDTO: Codable, Sendable, Equatable {
    public let hermesJobID: String
    /// Runs Hermes listed for this job (bounded by the per-tick cap).
    public let fetched: Int
    /// New `hermes_job_runs` rows written this call.
    public let inserted: Int
    /// Runs already collected (same run key) or still running.
    public let skipped: Int
    /// Vault files written under `raw/jobs/<job>/`.
    public let filesWritten: Int
    /// True when the cap stopped the pass early; call again to continue.
    public let truncated: Bool
    /// Newest finished run start time collected so far.
    public let highWaterMark: Date?
    public init(hermesJobID: String, fetched: Int, inserted: Int, skipped: Int, filesWritten: Int, truncated: Bool, highWaterMark: Date? = nil) {
        self.hermesJobID = hermesJobID
        self.fetched = fetched
        self.inserted = inserted
        self.skipped = skipped
        self.filesWritten = filesWritten
        self.truncated = truncated
        self.highWaterMark = highWaterMark
    }
}

/// Inbound push credential for the tenant's Hermes
/// (`GET /v1/hermes/mirror/webhook`, `POST /v1/hermes/mirror/webhook/rotate`).
/// `secret` is only present on the rotate response — store it on the Hermes
/// side; LuminaVault keeps it sealed and never returns it again.
public struct HermesMirrorWebhookDTO: Codable, Sendable, Equatable {
    /// Route path on the LuminaVault API, e.g. `/v1/hermes/mirror/webhook/<token>`.
    public let path: String
    public let token: String
    public let secret: String?
    /// Header carrying `hex(HMAC-SHA256(secret, "<timestamp>.<body>"))`.
    public let signatureHeader: String
    /// Header carrying the unix-seconds timestamp bound into the signature.
    public let timestampHeader: String
    /// Seconds a signed request stays valid.
    public let replayWindowSeconds: Int
    public let rotatedAt: Date?
    public init(
        path: String,
        token: String,
        secret: String? = nil,
        signatureHeader: String = "X-Webhook-Signature-V2",
        timestampHeader: String = "X-Webhook-Timestamp",
        replayWindowSeconds: Int = 300,
        rotatedAt: Date? = nil
    ) {
        self.path = path
        self.token = token
        self.secret = secret
        self.signatureHeader = signatureHeader
        self.timestampHeader = timestampHeader
        self.replayWindowSeconds = replayWindowSeconds
        self.rotatedAt = rotatedAt
    }
}

/// Body a Hermes-side sender posts to `POST /v1/hermes/mirror/webhook/{token}`.
/// `jobID` is required; when `output` is present the run is stored directly
/// (key `push:<runKey>`), and LuminaVault also pulls the job's run history.
public struct HermesJobWebhookPayload: Codable, Sendable, Equatable {
    public let jobID: String
    public let runKey: String?
    public let status: HermesJobRunStatus?
    public let output: String?
    public let error: String?
    public let startedAt: Date?
    public let finishedAt: Date?
    public init(
        jobID: String,
        runKey: String? = nil,
        status: HermesJobRunStatus? = nil,
        output: String? = nil,
        error: String? = nil,
        startedAt: Date? = nil,
        finishedAt: Date? = nil
    ) {
        self.jobID = jobID
        self.runKey = runKey
        self.status = status
        self.output = output
        self.error = error
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
        case runKey = "run_key"
        case status
        case output
        case error
        case startedAt = "started_at"
        case finishedAt = "finished_at"
    }
}
