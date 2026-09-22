import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Pending device commands contract")
struct PendingDeviceCommandsTests {
    @Test("decodes the server's queue, including a command without a domain")
    func decodesQueue() throws {
        let json = """
        {"commands":[
          {"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","kind":"reminder_create","domain":"reminders",
           "payload":{"title":"Call mom","due":""}},
          {"id":"7F9619FF-8B86-D011-B42D-00C04FC964FF","kind":"calendar_create","payload":{"title":"Dentist"}}
        ]}
        """
        let decoded = try JSONDecoder().decode(PendingDeviceCommandsResponse.self, from: Data(json.utf8))
        #expect(decoded.commands.map(\.kind) == [.reminderCreate, .calendarCreate])
        #expect(decoded.commands.first?.domain == .reminders)
        #expect(decoded.commands.last?.domain == nil)
        #expect(decoded.commands.first?.payload["title"] == "Call mom")
    }
}
