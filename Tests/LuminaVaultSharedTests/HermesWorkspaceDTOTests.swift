import Foundation
import Testing
@testable import LuminaVaultShared

/// The read-only workspace contract: the agent's checkout and what changed in
/// it, as the clients will read it.
struct HermesWorkspaceDTOTests {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    @Test("A workspace status round-trips")
    func statusRoundTrips() throws {
        let value = HermesWorkspaceStatusDTO(
            repo: HermesWorkspaceRepoDTO(root: "/work/repo", branch: "main"),
            branches: [
                HermesWorkspaceBranchDTO(name: "main", isCurrent: true),
                HermesWorkspaceBranchDTO(name: "feat/x")
            ],
            worktrees: [HermesWorkspaceWorktreeDTO(path: "/work/repo", branch: "main", isPrimary: true)],
            changes: [
                HermesWorkspaceChangeDTO(path: "a.swift", added: 10, removed: 2, status: "modified")
            ]
        )
        let decoded = try Self.decoder.decode(
            HermesWorkspaceStatusDTO.self,
            from: Self.encoder.encode(value)
        )
        #expect(decoded == value)
    }

    /// A detached HEAD has no branch. Encoding it as an empty string would
    /// make the UI show a blank branch name instead of saying what is going on.
    @Test("A detached HEAD carries no branch")
    func detachedHeadHasNoBranch() throws {
        let repo = HermesWorkspaceRepoDTO(root: "/work/repo", branch: nil, isDetached: true)
        let decoded = try Self.decoder.decode(
            HermesWorkspaceRepoDTO.self,
            from: Self.encoder.encode(repo)
        )
        #expect(decoded.branch == nil)
        #expect(decoded.isDetached)
    }

    /// Status is a free string on purpose: a state this build has never heard
    /// of must survive rather than collapse into "modified".
    @Test("An unfamiliar change status survives the round-trip")
    func unknownStatusSurvives() throws {
        let json = #"{"path":"a.swift","added":1,"removed":0,"status":"typechange"}"#
        let decoded = try Self.decoder.decode(
            HermesWorkspaceChangeDTO.self,
            from: Data(json.utf8)
        )
        #expect(decoded.status == "typechange")
    }

    /// A truncated diff must be flagged, because rendering it as complete
    /// would quietly show the reader the wrong change.
    @Test("A diff carries its truncation flag")
    func diffCarriesTruncation() throws {
        let value = HermesWorkspaceDiffDTO(path: "a.swift", diff: "@@ -1 +1 @@", truncated: true)
        let decoded = try Self.decoder.decode(
            HermesWorkspaceDiffDTO.self,
            from: Self.encoder.encode(value)
        )
        #expect(decoded.truncated)
    }

    @Test("Truncation defaults to false when the server omits it")
    func truncationDefaults() throws {
        let decoded = try Self.decoder.decode(
            HermesWorkspaceDiffDTO.self,
            from: Data(#"{"path":"a.swift","diff":"x","truncated":false}"#.utf8)
        )
        #expect(decoded.truncated == false)
    }

    @Test("A directory listing round-trips")
    func listingRoundTrips() throws {
        let value = HermesWorkspaceListingDTO(
            path: "/work/repo",
            entries: [
                HermesWorkspaceFileEntryDTO(name: "Sources", path: "/work/repo/Sources", isDirectory: true),
                HermesWorkspaceFileEntryDTO(name: "README.md", path: "/work/repo/README.md", isDirectory: false)
            ]
        )
        let decoded = try Self.decoder.decode(
            HermesWorkspaceListingDTO.self,
            from: Self.encoder.encode(value)
        )
        #expect(decoded == value)
    }
}
