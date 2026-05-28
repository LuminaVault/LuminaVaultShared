import Foundation
import Testing
@testable import LuminaVaultShared

// MARK: - HER-37 DTO round-trip tests

@Suite("QueryStreamEvent codable round-trip")
struct QueryStreamEventCodableTests {
    private func roundTrip(_ event: QueryStreamEvent) throws -> QueryStreamEvent {
        let data = try JSONEncoder().encode(event)
        return try JSONDecoder().decode(QueryStreamEvent.self, from: data)
    }

    @Test func token() throws {
        #expect(try roundTrip(.token("hello")) == .token("hello"))
    }

    @Test func summary() throws {
        #expect(try roundTrip(.summary("done thinking")) == .summary("done thinking"))
    }

    @Test func followUps() throws {
        let event: QueryStreamEvent = .followUps(["Go deeper", "Save as memo"])
        #expect(try roundTrip(event) == event)
    }

    @Test func source() throws {
        let hit = QueryHitDTO(id: UUID(), content: "snippet", distance: 0.42, createdAt: nil)
        #expect(try roundTrip(.source(hit)) == .source(hit))
    }

    @Test func done() throws {
        #expect(try roundTrip(.done) == .done)
    }

    @Test func error() throws {
        #expect(try roundTrip(.error("boom")) == .error("boom"))
    }

    @Test func wireShapeIsTypePayloadDiscriminator() throws {
        let event: QueryStreamEvent = .token("hi")
        let json = try JSONEncoder().encode(event)
        let dict = try JSONSerialization.jsonObject(with: json) as? [String: Any]
        #expect(dict?["type"] as? String == "token")
        #expect(dict?["payload"] as? String == "hi")
    }

    @Test func followUpsUsesSnakeCaseWireKey() throws {
        let event: QueryStreamEvent = .followUps(["a"])
        let json = try JSONEncoder().encode(event)
        let dict = try JSONSerialization.jsonObject(with: json) as? [String: Any]
        #expect(dict?["type"] as? String == "follow_ups")
    }

    @Test func doneOmitsPayloadKey() throws {
        let json = try JSONEncoder().encode(QueryStreamEvent.done)
        let dict = try JSONSerialization.jsonObject(with: json) as? [String: Any]
        #expect(dict?["type"] as? String == "done")
        #expect(dict?.keys.contains("payload") == false)
    }
}

@Suite("Conversation DTOs codable round-trip")
struct ConversationDTOCodableTests {
    @Test func conversation() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let c = ConversationDTO(
            id: UUID(),
            title: "Sleep patterns",
            spaceId: UUID(),
            createdAt: now,
            updatedAt: now
        )
        let data = try JSONEncoder().encode(c)
        let decoded = try JSONDecoder().decode(ConversationDTO.self, from: data)
        #expect(decoded.id == c.id)
        #expect(decoded.title == c.title)
        #expect(decoded.spaceId == c.spaceId)
    }

    @Test func message() throws {
        let m = ConversationMessageDTO(
            id: UUID(),
            conversationId: UUID(),
            role: .assistant,
            content: "Based on 7 notes from your vault…",
            sourceMemoryIDs: [UUID(), UUID()],
            createdAt: Date()
        )
        let data = try JSONEncoder().encode(m)
        let decoded = try JSONDecoder().decode(ConversationMessageDTO.self, from: data)
        #expect(decoded.role == .assistant)
        #expect(decoded.sourceMemoryIDs.count == 2)
    }

    @Test func roleWireValues() {
        #expect(ConversationMessageRole.user.rawValue == "user")
        #expect(ConversationMessageRole.assistant.rawValue == "assistant")
        #expect(ConversationMessageRole.system.rawValue == "system")
    }
}

@Suite("Backward-compatible additive DTO fields")
struct AdditiveFieldsTests {
    @Test func queryResponseFollowUpsIsOptionalAndDefaultsNil() throws {
        let r = QueryResponse(summary: "s", hits: [])
        #expect(r.followUps == nil)
    }

    @Test func queryResponseDecodesWithoutFollowUpsKey() throws {
        let legacyJSON = #"{"summary":"s","hits":[]}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(QueryResponse.self, from: legacyJSON)
        #expect(decoded.summary == "s")
        #expect(decoded.followUps == nil)
    }

    @Test func insightDTODecodesWithoutPeriodKeys() throws {
        let legacyJSON = """
        {"id":"00000000-0000-0000-0000-000000000000","headline":"h","summary":"s","section":"patterns","createdAt":\(Date().timeIntervalSinceReferenceDate),"sourceMemoryIDs":[],"dismissed":false}
        """.data(using: .utf8)!
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .deferredToDate
        let insight = try dec.decode(InsightDTO.self, from: legacyJSON)
        #expect(insight.periodStart == nil)
        #expect(insight.periodEnd == nil)
    }

    @Test func insightSectionAddsThisMonth() {
        #expect(InsightSection.thisMonth.rawValue == "this_month")
        #expect(InsightSection.allCases.contains(.thisMonth))
    }

    // HER-300 — LLM brain mode + onboarding flag back-compat
    @Test func llmPreferencesGetResponseDefaultsModeToManagedWhenMissing() throws {
        let legacyJSON = """
        {"primaryProvider":"openai","primaryModel":"gpt-4o","fallbackChain":[]}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(LLMPreferencesGetResponse.self, from: legacyJSON)
        #expect(decoded.mode == .managed)
        #expect(decoded.primaryProvider == .openai)
        #expect(decoded.primaryModel == "gpt-4o")
    }

    @Test func llmPreferencesPutRequestDefaultsModeToManagedWhenMissing() throws {
        let legacyJSON = """
        {"primaryProvider":"anthropic","primaryModel":"claude-opus-4-7","fallbackChain":[]}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(LLMPreferencesPutRequest.self, from: legacyJSON)
        #expect(decoded.mode == .managed)
    }

    @Test func onboardingStateDTODefaultsBrainConfiguredFalseWhenMissing() throws {
        let legacyJSON = """
        {"signupCompleted":true,"signupCompletedAt":null,"emailVerifiedCompleted":false,"emailVerifiedCompletedAt":null,"soulConfiguredCompleted":false,"soulConfiguredCompletedAt":null,"firstCaptureCompleted":false,"firstCaptureCompletedAt":null,"firstKBCompileCompleted":false,"firstKBCompileCompletedAt":null,"firstQueryCompleted":false,"firstQueryCompletedAt":null}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(OnboardingStateDTO.self, from: legacyJSON)
        #expect(decoded.brainConfiguredCompleted == false)
        #expect(decoded.brainConfiguredCompletedAt == nil)
    }
}

// MARK: - HER-300 LLM brain mode + preferences round-trip

@Suite("LLMBrainMode + LLMPreferences round-trip")
struct LLMBrainModeRoundTripTests {
    @Test func brainModeWireValues() {
        #expect(LLMBrainMode.managed.rawValue == "managed")
        #expect(LLMBrainMode.byok.rawValue == "byok")
        #expect(LLMBrainMode.allCases.count == 2)
    }

    @Test func getResponseRoundTrip() throws {
        let original = LLMPreferencesGetResponse(
            mode: .byok,
            primaryProvider: .anthropic,
            primaryModel: "claude-opus-4-7",
            fallbackChain: [ModelRouteDTO(provider: .openai, model: "gpt-4o")]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LLMPreferencesGetResponse.self, from: data)
        #expect(decoded.mode == .byok)
        #expect(decoded.primaryProvider == .anthropic)
        #expect(decoded.primaryModel == "claude-opus-4-7")
        #expect(decoded.fallbackChain.count == 1)
        #expect(decoded.fallbackChain[0].provider == .openai)
    }

    @Test func putRequestRoundTripManaged() throws {
        let original = LLMPreferencesPutRequest(
            mode: .managed,
            primaryProvider: .openRouter,
            primaryModel: "qwen/qwen-2.5-72b-instruct",
            fallbackChain: []
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LLMPreferencesPutRequest.self, from: data)
        #expect(decoded.mode == .managed)
        #expect(decoded.primaryModel == "qwen/qwen-2.5-72b-instruct")
    }

    @Test func getResponseEncodesModeKey() throws {
        let dto = LLMPreferencesGetResponse(
            mode: .managed,
            primaryProvider: .openRouter,
            primaryModel: "qwen/qwen-2.5-72b-instruct",
            fallbackChain: []
        )
        let data = try JSONEncoder().encode(dto)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(dict?["mode"] as? String == "managed")
    }

    @Test func onboardingStateBrainConfiguredRoundTrip() throws {
        let stamped = Date(timeIntervalSince1970: 1_700_000_000)
        let original = OnboardingStateDTO(
            signupCompleted: true, signupCompletedAt: stamped,
            emailVerifiedCompleted: true, emailVerifiedCompletedAt: stamped,
            soulConfiguredCompleted: true, soulConfiguredCompletedAt: stamped,
            firstCaptureCompleted: false, firstCaptureCompletedAt: nil,
            firstKBCompileCompleted: false, firstKBCompileCompletedAt: nil,
            firstQueryCompleted: false, firstQueryCompletedAt: nil,
            brainConfiguredCompleted: true, brainConfiguredCompletedAt: stamped
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OnboardingStateDTO.self, from: data)
        #expect(decoded.brainConfiguredCompleted == true)
        #expect(decoded.brainConfiguredCompletedAt == stamped)
    }

    @Test func onboardingPatchRequestCarriesBrainFlag() throws {
        let patch = OnboardingPatchRequest(brainConfiguredCompleted: true)
        let data = try JSONEncoder().encode(patch)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(dict?["brainConfiguredCompleted"] as? Bool == true)
    }
}
