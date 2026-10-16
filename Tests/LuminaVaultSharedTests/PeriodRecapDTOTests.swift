import Foundation
import Testing
@testable import LuminaVaultShared

struct PeriodRecapDTOTests {
    static let sample = PeriodRecapResponse(
        period: .year,
        year: 2026,
        month: nil,
        start: "2026-01-01",
        end: "2026-10-16",
        timezone: "Europe/Lisbon",
        isComplete: false,
        available: true,
        order: [.intro, .captures, .peak, .rhythm, .topics, .themes, .summary],
        captures: RecapCapturesCardDTO(
            captures: 120,
            learned: 40,
            previousCaptures: 0,
            previousLearned: 0,
            series: [RecapBucketDTO(key: "2026-01", count: 12)],
            byKind: [RecapCountDTO(label: "note", count: 90)],
            firstCapture: RecapFirstCaptureDTO(memoryId: UUID(), date: "2026-01-02", title: "Hello")
        ),
        peak: RecapPeakCardDTO(
            busiest: RecapBucketDTO(key: "2026-03", count: 30),
            weekdayCounts: [1, 2, 3, 4, 5, 6, 7],
            busiestWeekday: 7
        ),
        rhythm: RecapRhythmCardDTO(hourCounts: Array(repeating: 1, count: 24), peakHour: 23, persona: .nightOwl),
        topics: RecapTopicsCardDTO(
            topTags: [RecapCountDTO(label: "side_project", count: 9)],
            topSpace: RecapCountDTO(label: "Work", count: 50)
        ),
        chats: RecapChatsCardDTO(conversations: 10, messagesSent: 80, previousMessagesSent: 0),
        skills: RecapSkillsCardDTO(runs: 4, topSkill: RecapCountDTO(label: "daily-brief", count: 3)),
        streak: RecapStreakCardDTO(
            longestDays: 12,
            longestStart: "2026-03-01",
            longestEnd: "2026-03-12",
            activeDays: 90,
            totalDays: 289
        ),
        achievements: RecapAchievementsCardDTO(
            unlocked: 1,
            items: [RecapAchievementDTO(
                key: "first_capture",
                title: "First capture",
                unlockedAt: Date(timeIntervalSince1970: 0)
            )]
        ),
        themes: RecapThemesCardDTO(status: .pending, fallbackSentence: "A year of side_project."),
        shareText: "My 2026 so far on LuminaVault: 120 captures.",
        generatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    @Test("period recap round-trips")
    func roundTrip() throws {
        let data = try JSONEncoder().encode(Self.sample)
        #expect(try JSONDecoder().decode(PeriodRecapResponse.self, from: data) == Self.sample)
    }

    /// The iOS client decodes with `convertFromSnakeCase` + ISO-8601. A tag
    /// with an underscore must survive, which it does only because tags are
    /// values in an array, never keys.
    @Test("survives the client's snake_case-converting decoder")
    func clientDecoder() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PeriodRecapResponse.self, from: encoder.encode(Self.sample))
        #expect(decoded == Self.sample)
        #expect(decoded.topics?.topTags.first?.label == "side_project")
    }

    @Test("unknown card kinds, personas, statuses and reasons decode instead of failing")
    func unknownEnums() throws {
        let json = #"""
        {"period":"month","year":2026,"month":10,"start":"2026-10-01","end":"2026-10-16",
         "timezone":"UTC","isComplete":false,"available":false,"unavailableReason":"tooSoon",
         "order":["intro","confetti"],
         "rhythm":{"hourCounts":[],"peakHour":0,"persona":"lunchBreaker"},
         "themes":{"status":"thinking","themes":[],"fallbackSentence":"x"},
         "shareText":"","generatedAt":0}
        """#
        let decoded = try JSONDecoder().decode(PeriodRecapResponse.self, from: Data(json.utf8))
        #expect(decoded.order == [.intro, .unknown])
        #expect(decoded.unavailableReason == .unknown)
        #expect(decoded.rhythm?.persona == .unknown)
        #expect(decoded.themes?.status == .unknown)
        #expect(decoded.captures == nil)
    }
}
