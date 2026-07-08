import Foundation
import Testing
@testable import LuminaVaultShared

@Suite("Chat inbox + preferences contracts")
struct ChatInboxAndPreferencesContractTests {
    @Test func `chat inbox item round trips rich summary metadata`() throws {
        let workspaceID = UUID()
        let timestamp = Date(timeIntervalSince1970: 1_788_888_888)
        let item = ChatInboxItemDTO(
            id: UUID(),
            title: "Launch planning",
            preview: "Let's turn the settings surface into a daily-use layer.",
            messageCount: 12,
            lastMessageAt: timestamp,
            workspaceID: workspaceID,
            sourceLabel: "Lumina",
            providerID: .openRouter,
            model: "openai/gpt-4.1-mini",
            pinned: true,
            archived: false
        )

        let response = ChatInboxResponse(items: [item], nextCursor: "next-page")
        let decoded = try roundTrip(response, as: ChatInboxResponse.self)

        let decodedItem = try #require(decoded.items.first)
        #expect(decodedItem == item)
        #expect(decodedItem.workspaceID == workspaceID)
        #expect(decodedItem.providerID == .openRouter)
        #expect(decoded.nextCursor == "next-page")
    }

    @Test func `chat preferences default to expandable thinking and no send-on-return`() {
        let preferences = ChatPreferencesDTO()
        #expect(preferences.autoExpandThinking == true)
        #expect(preferences.sendOnReturn == false)
    }

    @Test func `chat preferences get and put bodies round trip`() throws {
        let preferences = ChatPreferencesDTO(autoExpandThinking: false, sendOnReturn: true)
        let getResponse = ChatPreferencesGetResponse(preferences: preferences)
        let putRequest = ChatPreferencesPutRequest(preferences: preferences)

        #expect(try roundTrip(getResponse, as: ChatPreferencesGetResponse.self).preferences == preferences)
        #expect(try roundTrip(putRequest, as: ChatPreferencesPutRequest.self).preferences == preferences)
    }
}

@Suite("Connections summary + diagnostics contracts")
struct ConnectionsContractTests {
    @Test func `connection enum wire values are stable snake-case values`() {
        #expect(ConnectionKind.llmProvider.rawValue == "llm_provider")
        #expect(ConnectionKind.hermesServer.rawValue == "hermes_server")
        #expect(ConnectionKind.hermesGateway.rawValue == "hermes_gateway")
        #expect(ConnectionKind.linkedAccount.rawValue == "linked_account")

        #expect(ConnectionHealth.needsSetup.rawValue == "needs_setup")
        #expect(ConnectionActionHint.configureProvider.rawValue == "configure_provider")
        #expect(ConnectionActionHint.openServerSettings.rawValue == "open_server_settings")
    }

    @Test func `connections summary round trips provider and gateway routing hints`() throws {
        let checkedAt = Date(timeIntervalSince1970: 1_788_888_999)
        let provider = ConnectionSummaryDTO(
            id: "provider:openRouter",
            kind: .llmProvider,
            title: "OpenRouter",
            subtitle: "Bring your own key",
            health: .connected,
            providerID: .openRouter,
            lastCheckedAt: checkedAt,
            statusDetail: "Verified",
            actionHint: .configureProvider
        )
        let gateway = ConnectionSummaryDTO(
            id: "gateway:whatsapp",
            kind: .hermesGateway,
            title: "WhatsApp",
            subtitle: "Messaging gateway",
            health: .needsSetup,
            gatewayID: .whatsapp,
            actionHint: .configureGateway
        )

        let response = ConnectionsSummaryResponse(
            connections: [provider, gateway],
            checkedAt: checkedAt
        )
        let decoded = try roundTrip(response, as: ConnectionsSummaryResponse.self)

        #expect(decoded == response)
        #expect(decoded.connections[0].providerID == .openRouter)
        #expect(decoded.connections[1].gatewayID == .whatsapp)
    }

    @Test func `test-all response can carry successful and actionable failed checks`() throws {
        let checkedAt = Date(timeIntervalSince1970: 1_788_889_111)
        let response = ConnectionsTestAllResponse(
            results: [
                ConnectionTestResultDTO(
                    id: "provider:anthropic",
                    kind: .llmProvider,
                    title: "Anthropic",
                    health: .connected,
                    ok: true,
                    checkedAt: checkedAt,
                    statusDetail: "Model probe succeeded"
                ),
                ConnectionTestResultDTO(
                    id: "calendar:google",
                    kind: .calendar,
                    title: "Google Calendar",
                    health: .error,
                    ok: false,
                    checkedAt: checkedAt,
                    errorCode: "reauth_required",
                    errorMessage: "Reconnect Google Calendar."
                )
            ],
            checkedAt: checkedAt
        )

        let decoded = try roundTrip(response, as: ConnectionsTestAllResponse.self)

        #expect(decoded == response)
        #expect(decoded.results[0].ok == true)
        #expect(decoded.results[1].ok == false)
        #expect(decoded.results[1].errorCode == "reauth_required")
    }

    @Test func `diagnostic events round trip connection identity and severity`() throws {
        let event = ConnectionDiagnosticEventDTO(
            id: UUID(),
            occurredAt: Date(timeIntervalSince1970: 1_788_889_222),
            kind: .hermesServer,
            connectionID: "hermes:managed",
            connectionTitle: "Hermes Server",
            severity: .warning,
            message: "Remote capabilities cache is stale.",
            code: "stale_capabilities"
        )

        let response = ConnectionDiagnosticEventsResponse(events: [event], nextCursor: nil)
        let decoded = try roundTrip(response, as: ConnectionDiagnosticEventsResponse.self)

        #expect(decoded == response)
        #expect(decoded.events.first?.severity == .warning)
        #expect(decoded.events.first?.connectionID == "hermes:managed")
    }
}

private func roundTrip<T: Codable>(_ value: T, as type: T.Type) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(type, from: data)
}
