import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Team vault DTOs")
struct TeamVaultDTOTests {
    @Test func permissionShapeRoundTrips() throws {
        let value = VaultPermissionsDTO(canRead: true, canWrite: false, canAdmin: false, canUseAI: true)
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(VaultPermissionsDTO.self, from: data) == value)
    }

    @Test func aiAccessIsIndependentFromRole() {
        let viewer = VaultSummaryDTO(
            id: UUID(),
            name: "Research",
            isPersonal: false,
            role: .viewer,
            permissions: .init(canRead: true, canWrite: false, canAdmin: false, canUseAI: true)
        )
        #expect(viewer.role == .viewer)
        #expect(viewer.permissions.canUseAI)
        #expect(!viewer.permissions.canWrite)
    }
}
