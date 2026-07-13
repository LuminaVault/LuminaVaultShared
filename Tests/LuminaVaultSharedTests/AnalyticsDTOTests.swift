import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Analytics intelligence contracts")
struct AnalyticsDTOTests {
    @Test("overview round trips transparent health and recommendations")
    func overviewRoundTrip() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let value = AnalyticsOverviewResponse(
            scope: .personal,
            vaultId: UUID(),
            range: .month,
            periodStart: now.addingTimeInterval(-29 * 86_400),
            periodEnd: now,
            summary: .init(aiRequests: 3, tokensIn: 100, tokensOut: 50),
            daily: [.init(date: now, aiRequests: 3, tokens: 150)],
            memoryHealth: .init(
                score: 74,
                totalMemories: 10,
                staleCount: 2,
                neverRetrievedCount: 1,
                unorganizedCount: 1,
                pendingReviewCount: 0,
                components: [.init(key: "freshness", title: "Freshness", score: 80, weight: 35)]
            ),
            recommendations: [.init(
                id: "memory-review-overdue",
                title: "Review memories",
                detail: "Two are due.",
                severity: .attention,
                actionTitle: "Review",
                deepLink: "/memories"
            )]
        )

        let decoded = try JSONDecoder().decode(
            AnalyticsOverviewResponse.self,
            from: JSONEncoder().encode(value)
        )

        #expect(decoded.range == .month)
        #expect(decoded.memoryHealth.score == 74)
        #expect(decoded.recommendations.first?.id == "memory-review-overdue")
    }

    @Test("model feedback and satisfaction round trip without content")
    func modelFeedbackRoundTrip() throws {
        let feedback = ModelFeedbackRequest(
            provider: "openai",
            model: "gpt-test",
            rating: .positive,
            idempotencyKey: "turn-1-positive"
        )
        let model = ModelEffectivenessDTO(
            provider: "openai",
            model: "gpt-test",
            requests: 4,
            successRate: 1,
            fallbackRate: 0,
            averageLatencyMs: 120,
            p95LatencyMs: 160,
            tokens: 500,
            estimatedCostUsdMicros: 100,
            positiveFeedback: 3,
            negativeFeedback: 1,
            satisfactionRate: 0.75
        )

        let decodedFeedback = try JSONDecoder().decode(
            ModelFeedbackRequest.self,
            from: JSONEncoder().encode(feedback)
        )
        let decodedModel = try JSONDecoder().decode(
            ModelEffectivenessDTO.self,
            from: JSONEncoder().encode(model)
        )

        #expect(decodedFeedback.rating == .positive)
        #expect(decodedModel.positiveFeedback == 3)
        #expect(decodedModel.satisfactionRate == 0.75)
    }
}
