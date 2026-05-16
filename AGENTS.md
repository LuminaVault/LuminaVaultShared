# LuminaVaultShared — Agent Instructions

These rules apply to every agent (Claude, Codex, etc.) working in this repo. They are non-negotiable unless the user explicitly overrides them in-session.

## Purpose

`LuminaVaultShared` is the **single source of truth** for every wire-format DTO that crosses the boundary between `LuminaVaultServer` (Hummingbird backend) and `LuminaVaultClient` (iOS app). It exists to prevent DTO drift and duplication.

## 1. Swift 6 Concurrency

- Target Swift 6 language mode with strict concurrency checking.
- All public types in `Sources/LuminaVaultShared/APIDTOs.swift` must be `Sendable`. Prefer `struct` + `Codable` + `Sendable` value types.
- Never silence concurrency warnings with `@unchecked Sendable` or `nonisolated(unsafe)` without a code comment explaining why.

## 2. Bruno Collection — Backend Is The Source

- API endpoint shape and contract live in `LuminaVaultServer/Sources/AppAPI/openapi.yaml`, not here.
- This package owns the **Swift representation** of the wire types referenced by that spec — keep field names, casing, and optionality in sync with `openapi.yaml`.
- If `openapi.yaml` changes in a way that affects a DTO here, update this package in the same change set as the server.

## 3. No Duplication — This Repo Owns the Shape

- Any DTO that is sent over HTTP between server and client lives here. Period.
- `LuminaVaultServer` and `LuminaVaultClient` consume this package; they do not redefine the same types locally.
- Server-only models (DB rows, internal services) and client-only models (UI view-state) stay in their respective repos — they are **not** wire types.
- When adding a new wire DTO:
  1. Add it here in `Sources/LuminaVaultShared/APIDTOs.swift` (or a sibling file if it warrants a new module).
  2. Update `LuminaVaultServer/Sources/AppAPI/openapi.yaml` to describe it.
  3. Run `make bruno-regen` on the server.
  4. Consume in server + client.

## How To Apply

- Before opening a PR here: confirm every public type is `Sendable` and matches the corresponding `openapi.yaml` schema in the server.
- If you spot a DTO redefined in server or client that already exists here, that's a bug — consolidate.
