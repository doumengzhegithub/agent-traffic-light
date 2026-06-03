import Testing
@testable import AgentTrafficLight

struct CodexAttentionProbeTests {
    @Test
    func testDetectsActionRequiredTitle() {
        #expect(CodexAttentionProbe.isAttentionTitle("[!] Action Required | littleHLD"))
    }

    @Test
    func testDetectsApprovalTitle() {
        #expect(CodexAttentionProbe.isAttentionTitle("Approval required"))
    }

    @Test
    func testIgnoresNormalTitle() {
        #expect(!CodexAttentionProbe.isAttentionTitle("littleHLD"))
    }
}
