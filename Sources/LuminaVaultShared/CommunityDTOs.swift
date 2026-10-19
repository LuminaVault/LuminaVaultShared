import Foundation

// ─── Community board ─────────────────────────────────────────────────────
//
// Contracts for `/v1/community`: one board every signed-in user shares,
// across vaults. Members post threads and one level of replies; the server
// publishes one AI-written Daily Post a day. Authors appear only through
// their community profile (handle + display name) — never by account
// username, email or user id.

/// Who wrote a post. `ai` posts carry no profile.
public enum CommunityAuthorKind: String, Codable, Sendable, CaseIterable {
    case user
    case ai
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? .unknown
    }
}

/// Where a post is in moderation. Lists only ever return `visible` posts,
/// plus the caller's own `pending` ones ("awaiting review").
public enum CommunityPostStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case visible
    case rejected
    case hidden
    case deleted
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? .unknown
    }
}

public struct CommunityAuthorDTO: Codable, Sendable, Equatable {
    public let kind: CommunityAuthorKind
    /// Public community profile id; `nil` for `ai`.
    public let profileId: UUID?
    public let handle: String?
    public let displayName: String?

    public init(kind: CommunityAuthorKind, profileId: UUID? = nil, handle: String? = nil, displayName: String? = nil) {
        self.kind = kind
        self.profileId = profileId
        self.handle = handle
        self.displayName = displayName
    }
}

/// A thread (`parentId == nil`, has a `title`) or a reply.
public struct CommunityPostDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let parentId: UUID?
    public let title: String?
    public let body: String
    public let author: CommunityAuthorDTO
    /// `true` for the server's AI-written Daily Post.
    public let isDailyPost: Bool
    /// Server-chosen caption for AI posts ("AI-generated · Daily Post").
    /// Clients show it verbatim so the wording lives in one place.
    public let aiLabel: String?
    public let status: CommunityPostStatus
    public let replyCount: Int
    public let reactionCount: Int
    public let viewerReacted: Bool
    /// `true` when the caller wrote it — enables delete, hides report/block.
    public let isOwn: Bool
    public let createdAt: Date
    public let lastActivityAt: Date

    public init(
        id: UUID,
        parentId: UUID? = nil,
        title: String?,
        body: String,
        author: CommunityAuthorDTO,
        isDailyPost: Bool = false,
        aiLabel: String? = nil,
        status: CommunityPostStatus,
        replyCount: Int = 0,
        reactionCount: Int = 0,
        viewerReacted: Bool = false,
        isOwn: Bool = false,
        createdAt: Date,
        lastActivityAt: Date
    ) {
        self.id = id
        self.parentId = parentId
        self.title = title
        self.body = body
        self.author = author
        self.isDailyPost = isDailyPost
        self.aiLabel = aiLabel
        self.status = status
        self.replyCount = replyCount
        self.reactionCount = reactionCount
        self.viewerReacted = viewerReacted
        self.isOwn = isOwn
        self.createdAt = createdAt
        self.lastActivityAt = lastActivityAt
    }
}

/// One page of `GET /v1/community/posts` or `…/posts/{id}/replies`.
/// Pass `nextCursor` back as `?cursor=`; `nil` means the end.
public struct CommunityPostPageDTO: Codable, Sendable, Equatable {
    public let items: [CommunityPostDTO]
    public let nextCursor: String?

    public init(items: [CommunityPostDTO], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public struct CommunityProfileDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let handle: String
    public let displayName: String
    public let termsVersion: Int
    public let termsAcceptedAt: Date
    /// Set while a moderator has suspended posting.
    public let postingSuspendedUntil: Date?

    public init(
        id: UUID,
        handle: String,
        displayName: String,
        termsVersion: Int,
        termsAcceptedAt: Date,
        postingSuspendedUntil: Date? = nil
    ) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.termsVersion = termsVersion
        self.termsAcceptedAt = termsAcceptedAt
        self.postingSuspendedUntil = postingSuspendedUntil
    }
}

/// `GET /v1/community/me`. Clients show the board only when `enabled`, and
/// the composer only when `postingEnabled` and the profile has accepted
/// `termsVersionRequired`.
public struct CommunityMeDTO: Codable, Sendable, Equatable {
    public let enabled: Bool
    public let postingEnabled: Bool
    public let profile: CommunityProfileDTO?
    public let termsVersionRequired: Int
    public let isModerator: Bool

    public init(
        enabled: Bool,
        postingEnabled: Bool,
        profile: CommunityProfileDTO?,
        termsVersionRequired: Int,
        isModerator: Bool
    ) {
        self.enabled = enabled
        self.postingEnabled = postingEnabled
        self.profile = profile
        self.termsVersionRequired = termsVersionRequired
        self.isModerator = isModerator
    }
}

/// `PUT /v1/community/profile`. `acceptTerms` must be `true` and
/// `termsVersion` must match `CommunityMeDTO.termsVersionRequired`.
public struct CommunityProfileUpsertRequest: Codable, Sendable, Equatable {
    public let handle: String
    public let displayName: String
    public let acceptTerms: Bool
    public let termsVersion: Int

    public init(handle: String, displayName: String, acceptTerms: Bool, termsVersion: Int) {
        self.handle = handle
        self.displayName = displayName
        self.acceptTerms = acceptTerms
        self.termsVersion = termsVersion
    }
}

/// `POST /v1/community/posts`.
public struct CommunityPostCreateRequest: Codable, Sendable, Equatable {
    public let title: String
    public let body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}

/// `POST /v1/community/posts/{id}/replies`.
public struct CommunityReplyCreateRequest: Codable, Sendable, Equatable {
    public let body: String

    public init(body: String) {
        self.body = body
    }
}

public enum CommunityReportReason: String, Codable, Sendable, CaseIterable {
    case spam
    case harassment
    case hate
    case sexual
    case violence
    case selfHarm = "self_harm"
    case misinformation
    case other

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? .other
    }
}

/// `POST /v1/community/posts/{id}/report`.
public struct CommunityReportRequest: Codable, Sendable, Equatable {
    public let reason: CommunityReportReason
    /// Optional free text, at most 500 characters.
    public let note: String?

    public init(reason: CommunityReportReason, note: String? = nil) {
        self.reason = reason
        self.note = note
    }
}

/// `POST /v1/community/blocks`.
public struct CommunityBlockRequest: Codable, Sendable, Equatable {
    public let profileId: UUID

    public init(profileId: UUID) {
        self.profileId = profileId
    }
}

/// One row of `GET /v1/community/blocks`.
public struct CommunityBlockedProfileDTO: Codable, Sendable, Equatable, Identifiable {
    public let profileId: UUID
    public let handle: String
    public let displayName: String
    public let blockedAt: Date

    public var id: UUID {
        profileId
    }

    public init(profileId: UUID, handle: String, displayName: String, blockedAt: Date) {
        self.profileId = profileId
        self.handle = handle
        self.displayName = displayName
        self.blockedAt = blockedAt
    }
}

public struct CommunityBlockListDTO: Codable, Sendable, Equatable {
    public let items: [CommunityBlockedProfileDTO]

    public init(items: [CommunityBlockedProfileDTO]) {
        self.items = items
    }
}

// ─── Moderator surface (`User.isAdmin` only) ─────────────────────────────

/// A post waiting for a moderator: reported, held `pending`, or `hidden`.
public struct CommunityAdminQueueItemDTO: Codable, Sendable, Equatable, Identifiable {
    public let post: CommunityPostDTO
    /// Category the automatic check gave, when it gave one.
    public let moderationCategory: String?
    public let hiddenReason: String?
    public let openReports: Int
    public let reportReasons: [CommunityReportReason]
    public let latestReportAt: Date?

    public var id: UUID {
        post.id
    }

    public init(
        post: CommunityPostDTO,
        moderationCategory: String? = nil,
        hiddenReason: String? = nil,
        openReports: Int = 0,
        reportReasons: [CommunityReportReason] = [],
        latestReportAt: Date? = nil
    ) {
        self.post = post
        self.moderationCategory = moderationCategory
        self.hiddenReason = hiddenReason
        self.openReports = openReports
        self.reportReasons = reportReasons
        self.latestReportAt = latestReportAt
    }
}

public struct CommunityAdminQueueDTO: Codable, Sendable, Equatable {
    public let items: [CommunityAdminQueueItemDTO]

    public init(items: [CommunityAdminQueueItemDTO]) {
        self.items = items
    }
}

public enum CommunityAdminDecisionAction: String, Codable, Sendable, CaseIterable {
    /// Take it off the board; reversible with `restore`.
    case hide
    /// Make it visible again and dismiss open reports.
    case restore
    /// Remove for good (status `deleted`, body replaced).
    case remove
}

/// `POST /v1/community/admin/posts/{id}/decision`.
public struct CommunityAdminDecisionRequest: Codable, Sendable, Equatable {
    public let action: CommunityAdminDecisionAction
    public let reason: String?

    public init(action: CommunityAdminDecisionAction, reason: String? = nil) {
        self.action = action
        self.reason = reason
    }
}

/// `POST /v1/community/admin/profiles/{id}/suspend`. `until == nil` lifts
/// a suspension.
public struct CommunityProfileSuspendRequest: Codable, Sendable, Equatable {
    public let until: Date?

    public init(until: Date?) {
        self.until = until
    }
}
