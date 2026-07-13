import Foundation
import Testing
@testable import LuminaVaultShared

struct MarketplaceDTOTests {
    @Test("Marketplace listing round-trips all trust and permission metadata")
    func listingRoundTrip() throws {
        let publisher = MarketplacePublisherDTO(
            id: UUID(), handle: "paper-trail", displayName: "Paper Trail", verified: true
        )
        let version = MarketplaceVersionDTO(
            id: UUID(), version: "1.2.3", status: .approved, runtimeKind: .wasm,
            permissions: [.memoryRead, .networkFetch], networkHosts: ["api.example.com"]
        )
        let original = MarketplacePluginDTO(
            slug: "paper-trail-digest", name: "Paper Trail Digest", summary: "Builds a cited digest.",
            description: "Reads selected memories and contacts one reviewed API.", category: .skill,
            publisher: publisher, latestVersion: version, ratingAverage: 4.4, ratingCount: 9
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MarketplacePluginDTO.self, from: encoded)

        #expect(decoded == original)
        #expect(decoded.latestVersion.permissions == [.memoryRead, .networkFetch])
    }

    @Test("Install request preserves the exact permission grant")
    func installConsentRoundTrip() throws {
        let original = MarketplaceInstallRequest(
            versionId: UUID(), grantedPermissions: [.vaultRead, .outputEmit], config: ["token": "secret"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MarketplaceInstallRequest.self, from: data)

        #expect(decoded.versionId == original.versionId)
        #expect(decoded.grantedPermissions == [.vaultRead, .outputEmit])
        #expect(decoded.config == ["token": "secret"])
    }

    @Test
    func `upgrade request preserves optimistic version lock and consent`() throws {
        let original = MarketplaceUpgradeRequest(
            fromVersionId: UUID(), toVersionId: UUID(),
            grantedPermissions: [.memoryRead, .vaultWrite], config: ["folder": "Research"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MarketplaceUpgradeRequest.self, from: data)

        #expect(decoded.fromVersionId == original.fromVersionId)
        #expect(decoded.toVersionId == original.toVersionId)
        #expect(decoded.grantedPermissions == original.grantedPermissions)
        #expect(decoded.config == original.config)
    }

    @Test
    func `artifact upload response carries server signature`() throws {
        let original = MarketplaceArtifactUploadResponse(
            artifactKey: "publisher/plugin/hash.wasm", sha256: String(repeating: "a", count: 64),
            sizeBytes: 128, signature: String(repeating: "b", count: 64)
        )

        let decoded = try JSONDecoder().decode(
            MarketplaceArtifactUploadResponse.self, from: JSONEncoder().encode(original)
        )

        #expect(decoded.signature == original.signature)
    }
}
