import Foundation

public enum TurnGateDecision: Equatable, Sendable {
    case allowed
    case denied(reason: String, retryAt: Date?)
}

/// Hook for an energy / turn budget. rerun is a single-player app with no
/// rate limit today (`UnlimitedTurns`); plug in a real gate here to add one.
public protocol TurnGate: Sendable {
    func check(momentID: String) -> TurnGateDecision
    func recordTurn(momentID: String, at date: Date)
}

public struct UnlimitedTurns: TurnGate {
    public init() {}
    public func check(momentID: String) -> TurnGateDecision { .allowed }
    public func recordTurn(momentID: String, at date: Date) {}
}
