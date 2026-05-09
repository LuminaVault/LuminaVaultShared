import Foundation

public struct OAuthExchangeRequest: Codable, Sendable {
    public let idToken: String

    public init(idToken: String) {
        self.idToken = idToken
    }
}