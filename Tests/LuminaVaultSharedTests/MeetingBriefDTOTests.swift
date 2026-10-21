import Foundation
import Testing
@testable import LuminaVaultShared

struct MeetingBriefDTOTests {
    @Test("a sync event carries its attendees")
    func syncEventAttendeesRoundTrip() throws {
        let input = AppleCalendarEventInput(
            externalID: "EK-1",
            title: "Q4 plan",
            startsAt: Date(timeIntervalSince1970: 1000),
            endsAt: Date(timeIntervalSince1970: 4600),
            attendees: [
                CalendarAttendeeDTO(name: "Ana Silva", email: "ana@example.com"),
                CalendarAttendeeDTO(name: "Rui"),
            ]
        )
        let data = try JSONEncoder().encode(AppleCalendarSyncRequest(events: [input]))
        let decoded = try JSONDecoder().decode(AppleCalendarSyncRequest.self, from: data)
        #expect(decoded.events.first?.attendees == input.attendees)
        #expect(decoded.events.first?.attendees?.last?.email == nil)
    }

    /// An iOS build from before attendees existed must keep syncing.
    @Test("a sync event without attendees still decodes, as nil")
    func syncEventWithoutAttendees() throws {
        let json = #"""
        {"events":[{"externalID":"EK-1","title":"Standup","startsAt":0,"endsAt":900,"allDay":false}]}
        """#
        let decoded = try JSONDecoder().decode(AppleCalendarSyncRequest.self, from: Data(json.utf8))
        #expect(decoded.events.first?.attendees == nil)
    }

    @Test("the meeting brief preference is off when an older server omits it")
    func meetingBriefPreferenceDefaultsOff() throws {
        let json = #"""
        {"chatEnabled":true,"nudgeEnabled":true,"digestEnabled":true,"approvalEnabled":true,"runCompletedEnabled":true}
        """#
        let decoded = try JSONDecoder().decode(APNSCategoryPrefsResponse.self, from: Data(json.utf8))
        #expect(decoded.meetingBriefEnabled == nil)
        #expect(decoded.isMeetingBriefEnabled == false)

        let on = APNSCategoryPrefsResponse(
            chatEnabled: true,
            nudgeEnabled: true,
            digestEnabled: true,
            meetingBriefEnabled: true
        )
        let object = try #require(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(on)) as? [String: Any]
        )
        #expect(object["meetingBriefEnabled"] as? Bool == true)
    }

    @Test("a put request can turn only the meeting brief on")
    func putMeetingBriefOnly() throws {
        let request = APNSCategoryPrefsPutRequest(meetingBriefEnabled: true)
        let decoded = try JSONDecoder().decode(APNSCategoryPrefsPutRequest.self, from: JSONEncoder().encode(request))
        #expect(decoded.meetingBriefEnabled == true)
        #expect(decoded.chatEnabled == nil)
    }

    @Test("a meeting brief round-trips with its event, notes and why")
    func briefRoundTrip() throws {
        let response = MeetingBriefResponse(
            event: MeetingBriefEventDTO(
                id: UUID(),
                title: "Q4 plan",
                startsAt: Date(timeIntervalSince1970: 1000),
                endsAt: Date(timeIntervalSince1970: 4600),
                location: "Room 2",
                attendees: [CalendarAttendeeDTO(name: "Ana", email: "ana@example.com")]
            ),
            memories: [
                MeetingBriefMemoryDTO(
                    id: UUID(),
                    snippet: "Ana wants hiring in the Q4 plan",
                    kind: "decision",
                    createdAt: Date(timeIntervalSince1970: 10),
                    similarity: 0.82
                ),
            ],
            why: "You mentioned Ana in 1 note"
        )
        let data = try JSONEncoder().encode(response)
        #expect(try JSONDecoder().decode(MeetingBriefResponse.self, from: data) == response)

        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let event = try #require(object["event"] as? [String: Any])
        #expect(event["startsAt"] != nil)
        #expect(event["attendees"] is [Any])
    }

    @Test("a memory kind this client does not know still decodes")
    func unknownKindDecodes() throws {
        let json = #"""
        {"id":"7B0D1B2E-4E33-4F06-9C1A-6A8E0F7A1E11","snippet":"s","kind":"someday","createdAt":0,"similarity":0.7}
        """#
        let decoded = try JSONDecoder().decode(MeetingBriefMemoryDTO.self, from: Data(json.utf8))
        #expect(decoded.kind == "someday")
    }
}
