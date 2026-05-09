import Foundation

public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let mfaCode: String?

    public init(email: String, password: String, mfaCode: String? = nil) {
        self.email = email
        self.password = password
        self.mfaCode = mfaCode
    }
}