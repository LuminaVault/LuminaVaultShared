import Foundation

public enum ImprovementModelMode: String, Codable, Sendable, CaseIterable {
    case economy
    case main
}

public enum ImprovementAvailability: String, Codable, Sendable {
    case managed
    case compatibleBYO = "compatible_byo"
    case readOnly = "read_only"
    case unavailable
}

public enum ImprovementChangeKind: String, Codable, Sendable {
    case curator
    case soul
}

public enum ImprovementChangeState: String, Codable, Sendable {
    case pending
    case approved
    case rejected
    case applied
    case stale
    case failed
}

public enum ImprovementTrigger: String, Codable, Sendable {
    case manual
    case weekly
    case complexSession = "complex_session"
}

public enum ImprovementRunStatus: String, Codable, Sendable {
    case queued
    case running
    case succeeded
    case failed
    case rolledBack = "rolled_back"
}

public enum ImprovementResourceKind: String, Codable, Sendable {
    case skill
    case job
}

public enum ImprovementResourceState: String, Codable, Sendable {
    case active
    case stale
    case archived
}

public struct ImprovementSettingsDTO: Codable, Sendable, Equatable {
    public let enabled: Bool
    public let curatorEnabled: Bool
    public let intervalHours: Int
    public let minimumIdleHours: Int
    public let consolidate: Bool
    public let pruneBuiltins: Bool
    public let backupKeep: Int
    public let soulReviewEnabled: Bool
    public let reviewComplexSessions: Bool
    public let soulReviewWindowDays: Int
    public let soulReviewCooldownHours: Int
    public let modelMode: ImprovementModelMode

    public init(
        enabled: Bool = true,
        curatorEnabled: Bool = true,
        intervalHours: Int = 168,
        minimumIdleHours: Int = 2,
        consolidate: Bool = true,
        pruneBuiltins: Bool = false,
        backupKeep: Int = 5,
        soulReviewEnabled: Bool = true,
        reviewComplexSessions: Bool = true,
        soulReviewWindowDays: Int = 14,
        soulReviewCooldownHours: Int = 24,
        modelMode: ImprovementModelMode = .economy
    ) {
        self.enabled = enabled
        self.curatorEnabled = curatorEnabled
        self.intervalHours = intervalHours
        self.minimumIdleHours = minimumIdleHours
        self.consolidate = consolidate
        self.pruneBuiltins = pruneBuiltins
        self.backupKeep = backupKeep
        self.soulReviewEnabled = soulReviewEnabled
        self.reviewComplexSessions = reviewComplexSessions
        self.soulReviewWindowDays = soulReviewWindowDays
        self.soulReviewCooldownHours = soulReviewCooldownHours
        self.modelMode = modelMode
    }

    public static let safeDefault = ImprovementSettingsDTO()
}

public struct ImprovementSettingsUpdateRequest: Codable, Sendable {
    public let settings: ImprovementSettingsDTO

    public init(settings: ImprovementSettingsDTO) {
        self.settings = settings
    }
}

public struct ImprovementStatusDTO: Codable, Sendable {
    public let settings: ImprovementSettingsDTO
    public let availability: ImprovementAvailability
    public let economyModelAvailable: Bool
    public let pendingChanges: Int
    public let lastCuratorReviewAt: Date?
    public let lastSoulReviewAt: Date?
    public let nextReviewAt: Date?
    public let message: String?

    public init(
        settings: ImprovementSettingsDTO,
        availability: ImprovementAvailability,
        economyModelAvailable: Bool,
        pendingChanges: Int,
        lastCuratorReviewAt: Date? = nil,
        lastSoulReviewAt: Date? = nil,
        nextReviewAt: Date? = nil,
        message: String? = nil
    ) {
        self.settings = settings
        self.availability = availability
        self.economyModelAvailable = economyModelAvailable
        self.pendingChanges = pendingChanges
        self.lastCuratorReviewAt = lastCuratorReviewAt
        self.lastSoulReviewAt = lastSoulReviewAt
        self.nextReviewAt = nextReviewAt
        self.message = message
    }
}

public struct ImprovementRunDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let kind: ImprovementChangeKind
    public let status: ImprovementRunStatus
    public let trigger: ImprovementTrigger
    public let dryRun: Bool
    public let modelUsed: String?
    public let reportMarkdown: String?
    public let actionsApplied: Int
    public let actionsSkipped: Int
    public let startedAt: Date?
    public let endedAt: Date?
    public let createdAt: Date
    public let failureReason: String?

    public init(
        id: UUID,
        kind: ImprovementChangeKind,
        status: ImprovementRunStatus,
        trigger: ImprovementTrigger,
        dryRun: Bool,
        modelUsed: String? = nil,
        reportMarkdown: String? = nil,
        actionsApplied: Int = 0,
        actionsSkipped: Int = 0,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        createdAt: Date,
        failureReason: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.status = status
        self.trigger = trigger
        self.dryRun = dryRun
        self.modelUsed = modelUsed
        self.reportMarkdown = reportMarkdown
        self.actionsApplied = actionsApplied
        self.actionsSkipped = actionsSkipped
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = createdAt
        self.failureReason = failureReason
    }
}

public struct ImprovementRunsResponse: Codable, Sendable {
    public let runs: [ImprovementRunDTO]

    public init(runs: [ImprovementRunDTO]) {
        self.runs = runs
    }
}

public struct ImprovementChangeDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let kind: ImprovementChangeKind
    public let state: ImprovementChangeState
    public let trigger: ImprovementTrigger
    public let title: String
    public let summary: String
    public let patch: String?
    public let baseSHA256: String?
    public let reportMarkdown: String?
    public let failureReason: String?
    public let createdAt: Date
    public let decidedAt: Date?
    public let appliedAt: Date?

    public init(
        id: UUID,
        kind: ImprovementChangeKind,
        state: ImprovementChangeState,
        trigger: ImprovementTrigger,
        title: String,
        summary: String,
        patch: String? = nil,
        baseSHA256: String? = nil,
        reportMarkdown: String? = nil,
        failureReason: String? = nil,
        createdAt: Date,
        decidedAt: Date? = nil,
        appliedAt: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.state = state
        self.trigger = trigger
        self.title = title
        self.summary = summary
        self.patch = patch
        self.baseSHA256 = baseSHA256
        self.reportMarkdown = reportMarkdown
        self.failureReason = failureReason
        self.createdAt = createdAt
        self.decidedAt = decidedAt
        self.appliedAt = appliedAt
    }
}

public struct ImprovementChangesResponse: Codable, Sendable {
    public let changes: [ImprovementChangeDTO]

    public init(changes: [ImprovementChangeDTO]) {
        self.changes = changes
    }
}

public struct ImprovementRunRequest: Codable, Sendable {
    public let dryRun: Bool

    public init(dryRun: Bool = true) {
        self.dryRun = dryRun
    }
}

public struct ImprovementRunAcceptedResponse: Codable, Sendable {
    public let run: ImprovementRunDTO

    public init(run: ImprovementRunDTO) {
        self.run = run
    }
}

public struct SoulReviewRequest: Codable, Sendable {
    public let trigger: ImprovementTrigger

    public init(trigger: ImprovementTrigger = .manual) {
        self.trigger = trigger
    }
}

public struct ImprovementDecisionResponse: Codable, Sendable {
    public let change: ImprovementChangeDTO

    public init(change: ImprovementChangeDTO) {
        self.change = change
    }
}

public struct ImprovementSkillDTO: Codable, Sendable, Identifiable {
    public var id: String { "\(kind.rawValue):\(name)" }
    public let name: String
    public let title: String
    public let kind: ImprovementResourceKind
    public let state: ImprovementResourceState
    public let pinned: Bool
    public let curatorManaged: Bool
    public let lastActivityAt: Date?

    public init(
        name: String,
        title: String,
        kind: ImprovementResourceKind,
        state: ImprovementResourceState,
        pinned: Bool,
        curatorManaged: Bool,
        lastActivityAt: Date? = nil
    ) {
        self.name = name
        self.title = title
        self.kind = kind
        self.state = state
        self.pinned = pinned
        self.curatorManaged = curatorManaged
        self.lastActivityAt = lastActivityAt
    }
}

public struct ImprovementSkillsResponse: Codable, Sendable {
    public let skills: [ImprovementSkillDTO]

    public init(skills: [ImprovementSkillDTO]) {
        self.skills = skills
    }
}

public struct ImprovementSkillPinRequest: Codable, Sendable {
    public let pinned: Bool

    public init(pinned: Bool) {
        self.pinned = pinned
    }
}

public struct ImprovementRollbackResponse: Codable, Sendable {
    public let run: ImprovementRunDTO

    public init(run: ImprovementRunDTO) {
        self.run = run
    }
}
