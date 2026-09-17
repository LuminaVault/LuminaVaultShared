import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Guided-start dismissal contracts")
struct OnboardingGuidedStartDTOTests {
    private static let stamped = Date(timeIntervalSince1970: 1_700_000_000)

    private func state(guidedStartDismissedAt: Date?) -> OnboardingStateDTO {
        OnboardingStateDTO(
            signupCompleted: true, signupCompletedAt: Self.stamped,
            emailVerifiedCompleted: true, emailVerifiedCompletedAt: Self.stamped,
            soulConfiguredCompleted: false, soulConfiguredCompletedAt: nil,
            firstCaptureCompleted: false, firstCaptureCompletedAt: nil,
            firstKBCompileCompleted: false, firstKBCompileCompletedAt: nil,
            firstQueryCompleted: false, firstQueryCompletedAt: nil,
            brainConfiguredCompleted: true, brainConfiguredCompletedAt: Self.stamped,
            guidedStartDismissedAt: guidedStartDismissedAt
        )
    }

    @Test("dismissal timestamp round-trips")
    func dismissalRoundTrips() throws {
        let data = try JSONEncoder().encode(state(guidedStartDismissedAt: Self.stamped))
        let decoded = try JSONDecoder().decode(OnboardingStateDTO.self, from: data)
        #expect(decoded.guidedStartDismissedAt == Self.stamped)
        #expect(decoded.brainConfiguredCompleted == true)
    }

    @Test("an undismissed card round-trips as nil")
    func undismissedRoundTrips() throws {
        let data = try JSONEncoder().encode(state(guidedStartDismissedAt: nil))
        let decoded = try JSONDecoder().decode(OnboardingStateDTO.self, from: data)
        #expect(decoded.guidedStartDismissedAt == nil)
    }

    // New client, old server: the key is simply absent from the payload.
    @Test("state decodes with the dismissal key absent")
    func stateDecodesWithKeyAbsent() throws {
        let json = """
        {"signupCompleted":true,"signupCompletedAt":null,
         "emailVerifiedCompleted":false,"emailVerifiedCompletedAt":null,
         "soulConfiguredCompleted":false,"soulConfiguredCompletedAt":null,
         "firstCaptureCompleted":false,"firstCaptureCompletedAt":null,
         "firstKBCompileCompleted":false,"firstKBCompileCompletedAt":null,
         "firstQueryCompleted":false,"firstQueryCompletedAt":null,
         "brainConfiguredCompleted":true,"brainConfiguredCompletedAt":null}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(OnboardingStateDTO.self, from: json)
        #expect(decoded.guidedStartDismissedAt == nil)
        #expect(decoded.brainConfiguredCompleted == true)
    }

    // An explicit null is the same thing as the key being missing.
    @Test("an explicit null dismissal decodes as nil")
    func explicitNullDecodesAsNil() throws {
        let json = """
        {"signupCompleted":true,"signupCompletedAt":null,
         "emailVerifiedCompleted":false,"emailVerifiedCompletedAt":null,
         "soulConfiguredCompleted":false,"soulConfiguredCompletedAt":null,
         "firstCaptureCompleted":false,"firstCaptureCompletedAt":null,
         "firstKBCompileCompleted":false,"firstKBCompileCompletedAt":null,
         "firstQueryCompleted":false,"firstQueryCompletedAt":null,
         "brainConfiguredCompleted":true,"brainConfiguredCompletedAt":null,
         "guidedStartDismissedAt":null}
        """.data(using: .utf8)!

        #expect(try JSONDecoder().decode(OnboardingStateDTO.self, from: json).guidedStartDismissedAt == nil)
    }

    // Old client, new server: keys this build has never heard of must be ignored.
    @Test("state decodes with unknown extra keys present")
    func stateDecodesWithUnknownKeys() throws {
        let json = """
        {"signupCompleted":true,"signupCompletedAt":null,
         "emailVerifiedCompleted":false,"emailVerifiedCompletedAt":null,
         "soulConfiguredCompleted":false,"soulConfiguredCompletedAt":null,
         "firstCaptureCompleted":false,"firstCaptureCompletedAt":null,
         "firstKBCompileCompleted":false,"firstKBCompileCompletedAt":null,
         "firstQueryCompleted":false,"firstQueryCompletedAt":null,
         "brainConfiguredCompleted":true,"brainConfiguredCompletedAt":null,
         "guidedStartDismissedAt":721692800,
         "somethingTheServerAddedLater":{"nested":[1,2,3]},
         "andAScalar":"hello"}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(OnboardingStateDTO.self, from: json)
        #expect(decoded.guidedStartDismissedAt == Self.stamped)
    }

    @Test("patch encodes guidedStartDismissed when set")
    func patchEncodesDismissal() throws {
        for value in [true, false] {
            let data = try JSONEncoder().encode(OnboardingPatchRequest(guidedStartDismissed: value))
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            #expect(dict?["guidedStartDismissed"] as? Bool == value)
        }
    }

    @Test("patch omits guidedStartDismissed when nil")
    func patchOmitsDismissalWhenNil() throws {
        let data = try JSONEncoder().encode(OnboardingPatchRequest(brainConfiguredCompleted: true))
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(dict?["brainConfiguredCompleted"] as? Bool == true)
        #expect(dict?.keys.contains("guidedStartDismissed") == false)
    }

    // Existing positional call sites must keep compiling without the new field.
    @Test("existing positional initialisers still compile and default to nil")
    func positionalInitialiserDefaultsToNil() {
        let legacy = OnboardingStateDTO(
            signupCompleted: true, signupCompletedAt: nil,
            emailVerifiedCompleted: false, emailVerifiedCompletedAt: nil,
            soulConfiguredCompleted: false, soulConfiguredCompletedAt: nil,
            firstCaptureCompleted: false, firstCaptureCompletedAt: nil,
            firstKBCompileCompleted: false, firstKBCompileCompletedAt: nil,
            firstQueryCompleted: false, firstQueryCompletedAt: nil
        )
        #expect(legacy.guidedStartDismissedAt == nil)
        #expect(OnboardingPatchRequest(firstQueryCompleted: true).guidedStartDismissed == nil)
    }
}
