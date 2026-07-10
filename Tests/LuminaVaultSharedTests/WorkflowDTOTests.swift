import Foundation
@testable import LuminaVaultShared
import Testing

@Test func workflowDefinitionRoundTrips() throws {
    let trigger = WorkflowNodeDTO(kind: .trigger, name: "Manual", x: 12, y: 24)
    let output = WorkflowNodeDTO(kind: .output, name: "Result", x: 300, y: 24, configuration: ["value": "{{trigger.topic}}"])
    let value = WorkflowDefinitionDTO(trigger: .manual, nodes: [trigger, output], edges: [WorkflowEdgeDTO(sourceNodeID: trigger.id, targetNodeID: output.id)])
    let decoded = try JSONDecoder().decode(WorkflowDefinitionDTO.self, from: JSONEncoder().encode(value))
    #expect(decoded == value)
}
