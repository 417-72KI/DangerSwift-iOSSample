import Foundation
import Danger

private let infoPlistFilePath = "DangerSwift-iOSSample/Info.plist"
private let releaseNoteFilePath = "fastlane/metadata/ja/release_notes.txt"

// fileImport: DangerExtensions/Branch.swift
// fileImport: DangerExtensions/InfoPlist.swift
// fileImport: DangerExtensions/Logger.swift
// fileImport: DangerExtensions/PNG.swift
func run(_ danger: DangerDSL) {
    logger.logLevel = .debug

    // Run SwiftLint
    SwiftLint.lint(inline: true)

    if let github = danger.github {
        let pr = github.pullRequest
        logger.debug("base: \(pr.base.ref)")
        logger.debug("head: \(pr.head.ref)")

        // Make it more obvious that a PR is a work in progress and shouldn't be merged yet
        if pr.title.lowercased().contains("[wip]") || pr.draft == true {
            danger.warn("PR is classed as Work in Progress")
        }

        validate(danger: danger, pr: pr)

        switch Branch(rawValue: pr.base.ref) {
        case .main:
            validateForMain(danger: danger, pr: pr)
        case .develop:
            validateForDevelop(danger: danger, pr: pr)
        default:
            break
        }
    }
}

// MARK: -
func validate(danger: DangerDSL, pr: GitHub.PullRequest) {
    // Verify screenshots if modified
    (danger.git.createdFiles + danger.git.modifiedFiles).lazy
        .filter { $0.hasPrefix("fastlane/screenshots/ja/") && $0.hasSuffix(".png") }
        .sorted()
        .map(URL.init(fileURLWithPath:))
        .map(verifyPNG(contentsOf:))
        .forEach {
            if case let .failure(error) = $0 {
                danger.fail("Invalid screenshot: \(error)")
            }
        }
}

// MARK: -
func validateForMain(danger: DangerDSL, pr: GitHub.PullRequest) {
    let base = Branch(pr.base.ref)
    let head = Branch(pr.head.ref)
    precondition(base == .main)

    if let body = pr.body, !body.contains("PROJECT/versions") {
        danger.warn("This PR doesn't contains JIRA release.")
    }

    // Fail when source is unexpected
    let isUnexpectedHead: Bool = {
        switch head {
        case .develop, .release, .hotfix: return false
        default:
            if let _ = head.rawValue.range(of: #"^bump-(build-number-to-\d*|version-to-\d+?\.\d+?\.\d+)$"#, options: .regularExpression) {
                return false
            }
            return true
        }
    }()
    if isUnexpectedHead {
        danger.fail("Only `develop`, `hotfix/*`, `release/*` or branches for bumping build number can be merged into main.")
    }

    // Warn when version number is not modified.
    if !danger.git.modifiedFiles.contains(infoPlistFilePath) {
        danger.warn("Info.plist is not modified. Check if version number is bumped.")
    }

    do {
        let infoPlist = try loadInfoPlist(infoPlistFilePath)
        // Print meta-data.
        outputMetadata(danger: danger, releaseNote: releaseNoteFilePath, infoPlist: infoPlist)
    } catch {
        logger.error(error)
        danger.fail(error.localizedDescription)
    }
}

// MARK: -
func validateForDevelop(danger: DangerDSL, pr: GitHub.PullRequest) {
    let base = Branch(pr.base.ref)
    let head = Branch(pr.head.ref)
    precondition(base == .develop)

    // Skip when backport (main to develop) PR
    if case .main = head, pr.title.lowercased().starts(with: "back") {
        danger.message("This is backport PR")
        return
    }

    // Skip if created by Renovate
    if case let .other(ref) = head, ref.starts(with: "renovate/") {
        danger.message("This PR is created by [Renovate](https://github.com/marketplace/renovate)")
        return
    }

    if let body = pr.body, !body.contains("PROJECT-") {
        danger.warn("This PR doesn't contains JIRA ticket.")
    }
}

// MARK: -
func loadInfoPlist(_ filePath: String) throws -> InfoPlist {
    try PropertyListDecoder()
        .decode(InfoPlist.self, from: try Data(contentsOf: URL(fileURLWithPath: filePath)))
}

func outputMetadata(danger: DangerDSL, releaseNote releaseNoteFilePath: String, infoPlist: InfoPlist) {
    var markdown = """
        # Version info
        \(infoPlist.shortVersionString) (\(infoPlist.bundleVersion))
        """
        markdown += "\n"
    do {
        if let releaseNote = String(data: try Data(contentsOf: URL(fileURLWithPath: releaseNoteFilePath)), encoding: .utf8) {
            markdown += """
            # Release note
            \(releaseNote)
            """
            markdown += "\n"
        } else {
            danger.fail("Failed to read release note(\"\(releaseNoteFilePath)\").")
        }
    } catch {
        logger.error(error)
        danger.fail(error.localizedDescription)
    }
    guard !markdown.isEmpty else { return }
    danger.markdown(markdown)
}

// MARK: -
run(Danger())
