import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Home Command Center contracts")
struct HomeSummaryDTOTests {
    @Test("older home payloads decode with cockpit defaults")
    func olderPayloadFillsCockpitDefaults() throws {
        let json = """
        {
          "skillsCount": 2,
          "jobsCount": 4,
          "remindersCount": 1,
          "todosCount": 0,
          "projectsCount": 1,
          "insightsCount": 0
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(HomeSummaryResponse.self, from: json)
        #expect(decoded.skillsCount == 2)
        #expect(decoded.cronJobs.isEmpty)
        #expect(decoded.tools.isEmpty)
        #expect(decoded.period == .today)
        #expect(decoded.periodStats.captures == 0)
        #expect(decoded.periodSeries.isEmpty)
        #expect(decoded.periodMix.chats == 0)
    }

    @Test("cockpit fields round-trip")
    func cockpitFieldsRoundTrip() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let value = HomeSummaryResponse(
            skillsCount: 3,
            jobsCount: 8,
            remindersCount: 1,
            todosCount: 2,
            projectsCount: 1,
            insightsCount: 0,
            cronJobsCount: 1,
            cronJobs: [.init(id: "cron-1", name: "Morning brief", schedule: "0 8 * * *", status: "ok")],
            toolsCount: 2,
            tools: ["web_search", "memory"],
            period: .week,
            periodStats: .init(done: 4, captures: 6, skillRuns: 4, tokens: 1200, previousDone: 2, previousCaptures: 3, previousSkillRuns: 1, previousTokens: 800),
            periodSeries: [.init(at: now, value: 3)],
            periodMix: .init(captures: 6, jobs: 1, skills: 4, chats: 2)
        )

        let decoded = try JSONDecoder().decode(
            HomeSummaryResponse.self,
            from: JSONEncoder().encode(value)
        )
        #expect(decoded.period == .week)
        #expect(decoded.cronJobs.first?.id == "cron-1")
        #expect(decoded.tools == ["web_search", "memory"])
        #expect(decoded.periodStats.done == 4)
        #expect(decoded.periodMix.captures == 6)
        #expect(decoded.periodSeries.count == 1)
    }
}
