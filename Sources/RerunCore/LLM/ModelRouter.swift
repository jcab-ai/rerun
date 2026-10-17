import Foundation

/// Which model writes which kind of scene. Romance goes to Gemini for prose by
/// default; everything else to the fallback route. All of it is editable.
public struct RoutingTable: Codable, Hashable, Sendable {
    public var fallback: ModelRoute
    public var byTag: [MomentTag: ModelRoute]

    public init(fallback: ModelRoute, byTag: [MomentTag: ModelRoute] = [:]) {
        self.fallback = fallback
        self.byTag = byTag
    }

    public static let standard = RoutingTable(
        fallback: ModelRoute(provider: .anthropic),
        byTag: [.romance: ModelRoute(provider: .gemini)]
    )
}

public struct RouteDecision: Hashable, Sendable {
    public enum Reason: Hashable, Sendable {
        /// The scene's tag has its own route.
        case tagRoute(MomentTag)
        /// No tag route, so the fallback route.
        case fallback
        /// The preferred provider has no key; another configured one stepped in.
        case substituted(preferred: LLMProviderID)
    }

    public var route: ModelRoute
    public var reason: Reason
}

/// Picks the provider/model for a story turn from the scene's tag.
public struct ModelRouter: Sendable {
    public var table: RoutingTable
    /// Providers that have an API key saved.
    public var configured: Set<LLMProviderID>

    public init(table: RoutingTable, configured: Set<LLMProviderID>) {
        self.table = table
        self.configured = configured
    }

    /// Nil when no provider has a key.
    public func route(for tag: MomentTag) -> RouteDecision? {
        if let tagged = table.byTag[tag], configured.contains(tagged.provider) {
            return RouteDecision(route: tagged, reason: .tagRoute(tag))
        }
        let preferred = table.byTag[tag]?.provider ?? table.fallback.provider
        if configured.contains(table.fallback.provider) {
            let reason: RouteDecision.Reason = table.byTag[tag] == nil ? .fallback : .substituted(preferred: preferred)
            return RouteDecision(route: table.fallback, reason: reason)
        }
        // Neither the tag route nor the fallback has a key: use any provider that does.
        guard let available = LLMProviderID.allCases.first(where: configured.contains) else { return nil }
        return RouteDecision(route: ModelRoute(provider: available), reason: .substituted(preferred: preferred))
    }
}
