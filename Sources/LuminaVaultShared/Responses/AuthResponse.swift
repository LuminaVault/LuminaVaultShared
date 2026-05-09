import Foundation

public struct AuthResponse: Codable, Sendable {
    public let userId: UUID
    public let email: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let mfaRequired: Bool?
    public let mfaChallengeId: UUID?

    public init(
        userId: UUID,
        email: String,
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        mfaRequired: Bool? = nil,
        mfaChallengeId: UUID? = nil
    ) {
        self.userId = userId
        self.email = email
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.mfaRequired = mfaRequired
        self.mfaChallengeId = mfaChallengeId
    }
}