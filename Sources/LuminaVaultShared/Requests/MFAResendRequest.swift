import Foundation

public struct MFAResendRequest: Codable, Sendable {
    public let email: String

    public init(email: String) {
        self.email = email
    }
}