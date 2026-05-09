import Foundation

public struct MFAVerifyRequest: Codable, Sendable {
    public let challengeId: UUID
    public let code: String

    public init(challengeId: UUID, code: String) {
        self.challengeId = challengeId
        self.code = code
    }
}