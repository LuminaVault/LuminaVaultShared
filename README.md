# LuminaVaultShared

Shared Swift wire-format types for the LuminaVault ecosystem.

Consumed by `LuminaVaultServer` (Hummingbird backend), and intended for `LuminaVaultApp` /
`LuminaVaultClient` / `LuminaVaultCollection` when they migrate from hand-written request/response
structs to a shared source of truth.

## Purpose

One Swift package, one role: **the over-the-wire contract between server and Swift clients.**

If a struct or enum is encoded into a request body or returned in a response body for the
LuminaVault HTTP API, it lives here. If it does anything else, it lives somewhere else.

## What belongs

- `Codable` request structs (e.g. `RegisterRequest`, `MemoryUpsertRequest`).
- `Codable` response structs (e.g. `AuthResponse`, `MemoryListResponse`).
- Public enums that appear in those structs as wire values (e.g. tool-call shapes,
  status discriminators).
- Free-form escape hatches for JSON fields the type system can't pin down
  (`AnyJSONValue`, `AnyCodableDict`) — kept minimal and audited.
- Pure `init` forwarders and `CodingKeys` declarations needed to keep the JSON shape stable.

## What does NOT belong

This package has zero non-Foundation dependencies. Keep it that way.

Hard "no" list (CI / code review should reject):

- `import FluentKit` / `import Fluent` / any DB driver — DB models stay server-side.
- `import Hummingbird` / `import HummingbirdAuth` / `import HummingbirdFluent` /
  `import HummingbirdWebSocket` — HTTP framework types are server-side.
- `FileManager`, `URLSession`, `URLRequest`, `ProcessInfo`, env-var reads, filesystem
  paths — clients (iOS) and tests don't want runtime side-effects here.
- Business logic in struct methods. `init` forwarders, trivial computed accessors, and
  `Codable` glue are fine; anything that branches on state, hits a service, or transforms
  data is not.
- Server-only fields that leak internal state across the wire: raw `passwordHash`,
  embedding `[Float]` vectors, internal `lastError` diagnostics, opaque internal IDs the
  client never needs.
- `@retroactive` conformance declarations. Consumers extend imported types in their own
  module (e.g. the server adds `extension AuthResponse: ResponseEncodable {}`); this
  package stays pure data.
- Catch-all "utility" types. If it isn't a DTO, it doesn't belong here even if it's
  convenient.

## Versioning policy

This package follows [SemVer](https://semver.org/).

- **Patch** (`0.1.0` → `0.1.1`) — internal refactor that produces an identical encoded
  JSON shape. Bug fixes that don't change the wire format.
- **Minor** (`0.1.0` → `0.2.0`) — additive only. New fields **must** be optional
  (`String?`) or have a default value. New structs, new enum cases (only on
  `@frozen`-style enums or non-exhaustive consumers — be careful). Existing fields
  cannot be renamed, retyped, or removed.
- **Major** (`0.x` → `1.0`, then `1.x` → `2.0`) — breaking changes. Rename a field,
  remove a field, change a type, drop a struct. Requires a coordinated bump on every
  consumer in the same merge window.

Once a tag is pushed to `origin`, it is **immutable**. Don't re-tag the same name.
Mistakes get a new patch.

## Consumer pin guidance

Always pin to a tag, never to a branch:

```swift
// ✅ Correct — stable, reproducible
.package(
    url: "https://github.com/LuminaVault/LuminaVaultShared.git",
    from: "0.1.0"
)

// ❌ Wrong — `Package.resolved` revision drifts unpredictably across
//     machines and CI as commits land on main
.package(
    url: "https://github.com/LuminaVault/LuminaVaultShared.git",
    branch: "main"
)
```

When bumping a consumer's pin, commit `Package.swift` **and** `Package.resolved`
together so the pinned revision is reproducible.

## Codegen from OpenAPI

Two parallel sources of truth currently coexist:

1. **`APIDTOs.swift`** — hand-written `Codable` structs for the majority of the API
   surface (auth, memory, LLM, vault, billing, achievements, etc.).
2. **`openapi.yaml`** (this directory) — OpenAPI 3.1 spec for the **`/spaces`** domain
   only. The `swift-openapi-generator` SPM plugin emits Swift types from this spec at
   build time into `Components.Schemas.*`.

### How `/spaces` is generated

- Spec lives at `Sources/LuminaVaultShared/openapi.yaml`.
- Config lives at `Sources/LuminaVaultShared/openapi-generator-config.yaml`
  (`generate: [types]`, `accessModifier: public`, `namingStrategy: idiomatic`).
- Build-time plugin: `OpenAPIGenerator` from
  `https://github.com/apple/swift-openapi-generator`.
- Generated types are emitted under `Components.Schemas.*` and accessible as
  `Components.Schemas.SpaceDTO`, `Components.Schemas.SpaceListResponse`,
  `Components.Schemas.CreateSpaceRequest`, `Components.Schemas.UpdateSpaceRequest`.
- The hand-written `/spaces` DTOs have been removed from `APIDTOs.swift`.

### Adding a new endpoint to the spec

1. Add a new schema (or schemas) under `components.schemas` in `openapi.yaml`.
2. Add a new path under `paths`.
3. Run `swift build` in this package — generator runs automatically as part of the
   build plugin and emits the new types into
   `.build/plugins/outputs/.../GeneratedSources/Types.swift`.
4. Bump the package version (minor for additive, major for breaking) and tag.
5. Bump the consumer pin (`LuminaVaultServer`, `LuminaVaultClient` when added).

### Server-side conformance and conversion

The generator emits raw wire types. Framework-specific glue and Fluent ↔ DTO
conversion stay in the **server**, never in this package. Pattern from
`LuminaVaultServer/Sources/App/Spaces/SpacesController.swift`:

```swift
typealias SpaceDTO = Components.Schemas.SpaceDTO
extension SpaceDTO: ResponseEncodable {}
```

Note: OpenAPI's `format: uuid` and `format: date-time` map to `Swift.String` and
`Foundation.Date` in generated types — not `UUID`. Server-side fromModel/toModel
helpers convert UUIDs to strings (`uuid.uuidString`) and back.

### Pilot scope

`/spaces` is the proof-of-pattern. Other domains continue to live in
`APIDTOs.swift` until per-domain migrations occur. Server-stub generation
(implementing `APIProtocol`) is **not** part of this pilot — controllers stay
imperative and only swap their request/response types to the generated forms.

When the spec eventually covers every endpoint, server-stub generation will move
into `LuminaVaultServer/Sources/AppAPI/` (with `generate: [server]`,
`accessModifier: package`), reading a synced copy of this spec. That step is
out of scope until enough domains have migrated.

### Boundary rules still apply

The "no Hummingbird / no Fluent / no business logic" rules in the section above
apply to generated output too. The current generator config (`generate: [types]`)
guarantees this — it does not emit `swift-openapi-hummingbird` server-stub code
into this package, so the iOS Client can consume `LuminaVaultShared` without
inheriting a Hummingbird dependency.
