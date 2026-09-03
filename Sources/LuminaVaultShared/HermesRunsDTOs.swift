import Foundation

// ─── Hermes runs (Phase 1 — act from your pocket) ────────────────────────
//
// Contracts for `/v1/hermes/runs`: start an agent run on the tenant's
// Hermes, watch it live, approve or deny tool calls, stop it. LuminaVault
// persists runs and their events because the Hermes gateway forgets a run
// 300 s after it finishes.

/// Lifecycle of a run as LuminaVault tracks it. Hermes's own `cancelled`
/// maps to `stopped`; `lost` is LuminaVault-only — the watcher could not
/// re-attach after a restart (Hermes had already expired the run).
public enum HermesRunStatus: String, Codable, Sendable, CaseIterable {
    case queued
    case running
    case waitingForApproval = "waiting_for_approval"
    case completed
    case failed
    case stopped
    case lost

    /// `true` once no further events can arrive for the run.
    public var isTerminal: Bool {
        switch self {
        case .queued, .running, .waitingForApproval: false
        case .completed, .failed, .stopped, .lost: true
        }
    }
}

/// Answers Hermes accepts on `POST /v1/runs/{id}/approval`.
public enum HermesApprovalChoice: String, Codable, Sendable, CaseIterable {
    /// Allow this one command.
    case once
    /// Allow this command for the rest of the run's session.
    case session
    /// Allow this command permanently on that Hermes.
    case always
    case deny
}

/// The tool call Hermes is waiting on. `command` is already redacted by
/// Hermes; `extra` carries any other fields from the `approval.request`
/// event (tool name, risk hints) for clients that want to show them.
public struct HermesRunPendingApprovalDTO: Codable, Sendable, Equatable {
    public let command: String?
    public let choices: [HermesApprovalChoice]
    public let requestedAt: Date
    public let extra: [String: AnyJSONValue]?

    public init(
        command: String?,
        choices: [HermesApprovalChoice],
        requestedAt: Date,
        extra: [String: AnyJSONValue]? = nil
    ) {
        self.command = command
        self.choices = choices
        self.requestedAt = requestedAt
        self.extra = extra
    }
}

public struct HermesRunDTO: Codable, Sendable, Equatable, Identifiable {
    /// LuminaVault row id — the id used in every `/v1/hermes/runs/{id}` path.
    public let id: UUID
    /// Hermes-side `run_id` (`run_<hex>`), for cross-referencing Hermes logs.
    public let hermesRunID: String
    public let status: HermesRunStatus
    public let prompt: String
    public let sessionID: String?
    public let model: String?
    /// Conversation the run was started from, when any.
    public let conversationID: UUID?
    public let startedAt: Date
    public let finishedAt: Date?
    /// Name of the last Hermes event seen (`tool.started`, `approval.request`, …).
    public let lastEvent: String?
    /// Highest persisted event `seq`; pass as `?after=` to resume the SSE feed.
    public let lastSeq: Int
    public let pendingApproval: HermesRunPendingApprovalDTO?
    /// Final assistant output for completed runs.
    public let summary: String?
    /// Failure message for `failed` / `lost` runs.
    public let error: String?

    public init(
        id: UUID,
        hermesRunID: String,
        status: HermesRunStatus,
        prompt: String,
        sessionID: String? = nil,
        model: String? = nil,
        conversationID: UUID? = nil,
        startedAt: Date,
        finishedAt: Date? = nil,
        lastEvent: String? = nil,
        lastSeq: Int,
        pendingApproval: HermesRunPendingApprovalDTO? = nil,
        summary: String? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.hermesRunID = hermesRunID
        self.status = status
        self.prompt = prompt
        self.sessionID = sessionID
        self.model = model
        self.conversationID = conversationID
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.lastEvent = lastEvent
        self.lastSeq = lastSeq
        self.pendingApproval = pendingApproval
        self.summary = summary
        self.error = error
    }
}

/// One persisted Hermes event. `payload` is the event object exactly as
/// Hermes sent it (minus nothing — the `command` in `approval.request` is
/// redacted upstream). Delivered as the `data:` line of the run SSE feed.
public struct HermesRunEventDTO: Codable, Sendable, Equatable {
    public let runID: UUID
    /// Monotonic per run, starting at 1.
    public let seq: Int
    /// Hermes event name: `run.started`, `message.delta`, `tool.started`,
    /// `tool.completed`, `approval.request`, `approval.responded`,
    /// `run.completed`, `run.failed`, `run.cancelled`, `error`, …
    public let event: String
    public let payload: AnyJSONValue
    public let at: Date

    public init(runID: UUID, seq: Int, event: String, payload: AnyJSONValue, at: Date) {
        self.runID = runID
        self.seq = seq
        self.event = event
        self.payload = payload
        self.at = at
    }
}

/// `POST /v1/hermes/runs`.
public struct HermesRunStartRequest: Codable, Sendable, Equatable {
    public let prompt: String
    /// Hermes session to continue; a fresh one is created when absent.
    public let sessionID: String?
    public let model: String?
    /// When set, a system message linking to the run is appended to that
    /// conversation's transcript.
    public let conversationID: UUID?

    public init(prompt: String, sessionID: String? = nil, model: String? = nil, conversationID: UUID? = nil) {
        self.prompt = prompt
        self.sessionID = sessionID
        self.model = model
        self.conversationID = conversationID
    }
}

/// `POST /v1/hermes/runs/{id}/approval`.
public struct HermesRunApprovalRequest: Codable, Sendable, Equatable {
    public let choice: HermesApprovalChoice

    public init(choice: HermesApprovalChoice) {
        self.choice = choice
    }
}

/// `GET /v1/hermes/runs` — newest first.
public struct HermesRunListResponse: Codable, Sendable, Equatable {
    public let runs: [HermesRunDTO]

    public init(runs: [HermesRunDTO]) {
        self.runs = runs
    }
}

// ─── AnyJSONValue encoding ───────────────────────────────────────────────

/// `AnyJSONValue` declares a hand-written decoder that reads plain JSON, but
/// left encoding to synthesis, which emits the enum-case envelope
/// (`{"string":{"_0":"x"}}`) and cannot round-trip through that decoder.
/// Encode plain JSON so `HermesRunEventDTO.payload` (and every other user of
/// the type) writes what it reads.
extension AnyJSONValue {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case .null: try container.encodeNil()
        case let .object(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        }
    }
}
