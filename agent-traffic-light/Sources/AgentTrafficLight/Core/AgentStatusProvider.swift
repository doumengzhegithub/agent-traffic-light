protocol AgentStatusProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    func snapshot() async -> AgentSnapshot
}
