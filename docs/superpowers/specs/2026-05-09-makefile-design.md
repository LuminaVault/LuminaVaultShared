# Makefile Design Spec

Created: 2026-05-09
Topic: Makefile for LuminaVaultShared

## Purpose
Provide a standardized interface for common development tasks and release management for the LuminaVaultShared Swift package.

## Approaches
- **Chosen Approach**: Swift-Enhanced.
- **Rationale**: Simplifies the development workflow by providing one-word commands for building, testing, and cleaning, in addition to the requested release management.

## Components

### Variables
- `REMOTE`: Git remote name (default: `origin`).
- `VERSION`: Target version string for tagging (e.g., `v1.0.0`).

### Targets
- `help`: (Default) Displays available commands and usage.
- `build`: Compiles the Swift package using `swift build`.
- `test`: Executes the test suite using `swift test`.
- `clean`: Removes build artifacts using `swift package clean`.
- `tag`: 
    - Validates that `VERSION` is provided.
    - Creates a git tag locally.
- `push-tag`:
    - Validates that `VERSION` is provided.
    - Pushes the specified tag to `$(REMOTE)`.
- `release`: Triggers `tag` followed by `push-tag`.

## Testing Strategy
- Verify `make help` displays correct usage.
- Verify `make build` and `make test` correctly invoke Swift tools.
- Verify `make tag` fails without `VERSION`.
- Verify `make tag VERSION=test-tag` creates a tag.
- Verify `make clean` removes `.build` folder content.
