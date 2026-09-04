import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("APNS category prefs contracts")
struct APNSCategoryPrefsDTOTests {
    @Test("the response carries the two Phase 1 categories")
    func responseRoundTrips() throws {
        let response = APNSCategoryPrefsResponse(
            chatEnabled: true,
            nudgeEnabled: false,
            digestEnabled: true,
            approvalEnabled: false,
            runCompletedEnabled: true
        )
        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(APNSCategoryPrefsResponse.self, from: data)
        #expect(decoded.approvalEnabled == false)
        #expect(decoded.runCompletedEnabled == true)
        #expect(decoded.nudgeEnabled == false)
    }

    /// A client built before these fields existed keeps compiling, and an older
    /// server that does not send them still decodes — both must stay true or
    /// the tag is a breaking change rather than a minor one.
    @Test("the Phase 1 flags default to on when a caller omits them")
    func defaultsAreOn() {
        let response = APNSCategoryPrefsResponse(chatEnabled: true, nudgeEnabled: true, digestEnabled: true)
        #expect(response.approvalEnabled)
        #expect(response.runCompletedEnabled)
    }

    @Test("a put request omits what it does not change")
    func putIsSparse() throws {
        let request = APNSCategoryPrefsPutRequest(approvalEnabled: false)
        #expect(request.chatEnabled == nil)
        #expect(request.runCompletedEnabled == nil)

        let json = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(APNSCategoryPrefsPutRequest.self, from: json)
        #expect(decoded.approvalEnabled == false)
        #expect(decoded.digestEnabled == nil)
    }

    /// Wire names are what the iOS and web clients bind to; a rename here is a
    /// silent breakage, so pin them.
    @Test("wire keys are the camelCase the clients expect")
    func wireKeys() throws {
        let data = try JSONEncoder().encode(
            APNSCategoryPrefsResponse(chatEnabled: true, nudgeEnabled: true, digestEnabled: true)
        )
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["approvalEnabled"] as? Bool == true)
        #expect(object["runCompletedEnabled"] as? Bool == true)
    }
}
