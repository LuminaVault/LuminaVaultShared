import Foundation

public struct MeResponse: Codable, Sendable {
    public let userId: UUID
    public let email: String
    public let username: String
    public let isVerified: Bool

    public init(userId: UUID, email: String, username: String, isVerified: Bool) {
        self.userId = userId
        self.email = email
        self.username = username
        self.isVerified = isVerified
    }
}