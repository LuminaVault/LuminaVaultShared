import Foundation

public struct RegisterRequest: Codable, Sendable {
    public let email: String
    public let username: String
    public let password: String

    public init(email: String, username: String, password: String) {
        self.email = email
        self.username = username
        self.password = password
    }
}