// LLMModelCatalog.swift
//
// BYOK v2 — curated, offline model catalog so the iOS client can present a
// Picker per provider instead of a free-text field (no typos). Intentionally
// hand-maintained and conservative: list the models worth defaulting to, not
// every SKU. Phase 2 adds a dynamic `GET /v1/me/providers/{id}/models` fetch
// that merges live provider listings on top of this baseline.
//
// `ollama` is deliberately omitted — self-hosted model names are user-specific,
// so that provider keeps a free-text entry on the client.

import Foundation

/// One selectable model for a provider.
public struct LLMModelInfo: Codable, Sendable, Hashable, Identifiable {
    /// Wire model id sent to the provider (e.g. `gemini-2.5-flash`).
    public let id: String
    /// Human-facing label for the picker row.
    public let displayName: String
    /// Approximate context window in tokens, when known. UI hint only.
    public let contextWindow: Int?
    /// Auto (Smart) capability band. Defaults to balanced when unknown.
    public let tier: RouterModelTier

    public init(
        id: String,
        displayName: String,
        contextWindow: Int? = nil,
        tier: RouterModelTier = .balanced
    ) {
        self.id = id
        self.displayName = displayName
        self.contextWindow = contextWindow
        self.tier = tier
    }
}

/// Curated per-provider model lists. Source of truth for the client model
/// picker. Edit + bump the package to add models.
public enum LLMModelCatalog {
    /// Models offered for a provider. Empty → the client should fall back to a
    /// free-text custom-model field (e.g. `ollama`, or any future provider not
    /// yet curated here).
    public static func models(for provider: ProviderID) -> [LLMModelInfo] {
        switch provider {
        case .gemini:
            return [
                .init(id: "gemini-2.5-flash-lite", displayName: "Gemini 2.5 Flash Lite", contextWindow: 1_000_000, tier: .fast),
                .init(id: "gemini-2.5-flash", displayName: "Gemini 2.5 Flash", contextWindow: 1_000_000, tier: .fast),
                .init(id: "gemini-2.0-flash", displayName: "Gemini 2.0 Flash", contextWindow: 1_000_000, tier: .fast),
                .init(id: "gemini-2.5-pro", displayName: "Gemini 2.5 Pro", contextWindow: 1_000_000, tier: .balanced),
                .init(id: "gemini-3-flash-preview", displayName: "Gemini 3 Flash (preview)", contextWindow: 1_000_000, tier: .fast),
                .init(id: "gemini-3-pro-preview", displayName: "Gemini 3 Pro (preview)", contextWindow: 1_000_000, tier: .max),
            ]
        case .openai:
            return [
                .init(id: "gpt-4o-mini", displayName: "GPT-4o mini", contextWindow: 128_000, tier: .fast),
                .init(id: "gpt-4.1-mini", displayName: "GPT-4.1 mini", contextWindow: 1_000_000, tier: .fast),
                .init(id: "gpt-4o", displayName: "GPT-4o", contextWindow: 128_000, tier: .balanced),
                .init(id: "gpt-4.1", displayName: "GPT-4.1", contextWindow: 1_000_000, tier: .balanced),
                .init(id: "o4-mini", displayName: "o4-mini (reasoning)", contextWindow: 200_000, tier: .balanced),
                .init(id: "o3", displayName: "o3 (reasoning)", contextWindow: 200_000, tier: .max),
            ]
        case .anthropic:
            return [
                .init(id: "claude-3-5-haiku-20241022", displayName: "Claude 3.5 Haiku", contextWindow: 200_000, tier: .fast),
                .init(id: "claude-sonnet-4-5", displayName: "Claude Sonnet 4.5", contextWindow: 200_000, tier: .balanced),
                .init(id: "claude-3-5-sonnet-20241022", displayName: "Claude 3.5 Sonnet", contextWindow: 200_000, tier: .balanced),
                .init(id: "claude-opus-4-1", displayName: "Claude Opus 4.1", contextWindow: 200_000, tier: .max),
            ]
        case .openRouter:
            return [
                .init(id: "openrouter/auto", displayName: "OpenRouter Auto (provider)", tier: .balanced),
                .init(id: "deepseek/deepseek-chat", displayName: "DeepSeek Chat", contextWindow: 64_000, tier: .fast),
                .init(id: "google/gemini-2.5-flash", displayName: "Gemini 2.5 Flash", contextWindow: 1_000_000, tier: .fast),
                .init(id: "anthropic/claude-3.5-haiku", displayName: "Claude 3.5 Haiku", contextWindow: 200_000, tier: .fast),
                .init(id: "qwen/qwen-2.5-72b-instruct", displayName: "Qwen 2.5 72B", contextWindow: 131_072, tier: .balanced),
                .init(id: "openai/gpt-4o", displayName: "GPT-4o", contextWindow: 128_000, tier: .balanced),
                .init(id: "anthropic/claude-3.5-sonnet", displayName: "Claude 3.5 Sonnet", contextWindow: 200_000, tier: .balanced),
                .init(id: "google/gemini-2.5-pro", displayName: "Gemini 2.5 Pro", contextWindow: 1_000_000, tier: .balanced),
                .init(id: "anthropic/claude-opus-4", displayName: "Claude Opus 4", contextWindow: 200_000, tier: .max),
            ]
        case .xai:
            return [
                .init(id: "grok-3-mini", displayName: "Grok 3 mini", contextWindow: 131_072, tier: .fast),
                .init(id: "grok-3", displayName: "Grok 3", contextWindow: 131_072, tier: .balanced),
                .init(id: "grok-4", displayName: "Grok 4", contextWindow: 256_000, tier: .max),
            ]
        case .nvidia:
            return [
                .init(id: "meta/llama-3.1-8b-instruct", displayName: "Llama 3.1 8B", contextWindow: 128_000, tier: .fast),
                .init(id: "meta/llama-3.1-70b-instruct", displayName: "Llama 3.1 70B", contextWindow: 128_000, tier: .balanced),
                .init(id: "meta/llama-3.3-70b-instruct", displayName: "Llama 3.3 70B", contextWindow: 128_000, tier: .balanced),
                .init(id: "deepseek-ai/deepseek-r1", displayName: "DeepSeek R1 (reasoning)", contextWindow: 128_000, tier: .max),
            ]
        case .nous:
            return [
                .init(id: "stepfun/step-3.7-flash:free", displayName: "StepFun Step 3.7 Flash (free)", tier: .fast),
                .init(id: "stepfun/step-3.7-flash", displayName: "StepFun Step 3.7 Flash", tier: .fast),
                .init(id: "nvidia/nemotron-3-ultra:free", displayName: "Nemotron 3 Ultra (free)", tier: .balanced),
            ]
        case .ollama:
            return []
        case .custom:
            return []
        }
    }

    /// Convenience default model id for a provider (first catalog entry), used
    /// to seed the picker when a tenant has no saved preference yet.
    public static func defaultModelID(for provider: ProviderID) -> String? {
        models(for: provider).first?.id
    }

    /// Best-effort tier lookup for a wire model id on a provider.
    public static func tier(for provider: ProviderID, model: String) -> RouterModelTier {
        if let hit = models(for: provider).first(where: { $0.id == model }) {
            return hit.tier
        }
        return inferredTier(from: model)
    }

    /// Heuristic when the model is not in the curated list.
    public static func inferredTier(from model: String) -> RouterModelTier {
        let lower = model.lowercased()
        if lower.contains("haiku")
            || lower.contains("flash")
            || lower.contains("mini")
            || lower.contains("lite")
            || lower.contains("8b")
            || lower.contains("deepseek-chat")
        {
            return .fast
        }
        if lower.contains("opus")
            || lower.contains("o3")
            || lower.contains("r1")
            || lower.contains("fable")
            || lower.contains("ultra")
            || lower.contains("gpt-5")
        {
            return .max
        }
        return .balanced
    }
}
