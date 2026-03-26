# Contributing Guidelines

## Workflow and Branching

- Work must be performed on dedicated branches named according to the pattern: `feature/issue-number-description` or `fix/issue-number-description`.
- Direct commits to the `main` branch are prohibited.
- All branches must be merged via Pull Requests.

## Pull Request Process

1. Ensure the code compiles and all existing tests pass.
2. Pull Requests must reference at least one open Issue in the description (e.g., "Closes #12").
3. Provide a concise summary of changes and any architectural decisions made.
4. While self-approval for contributors is permitted for rapid iteration, complex logic changes should involve a peer review from another maintainer.

## Development Standards

- Architecture: Favor Dependency Injection over Singletons to facilitate unit testing.
- Concurrency: Use Swift Structured Concurrency (async/await) rather than legacy Grand Central Dispatch (GCD) where possible.
- Constants: Do not use magic strings. All storage keys and hardcoded values must be centralized in the AppConstants file.
- Logging: Use the AppLogger for telemetry-related events and ErrorLogger for debugging.

## Environment Setup

Configuration files are excluded from version control and must be created locally.

1. Copy `Example.xcconfig` to `Development.xcconfig`.
2. Populate it with API keys.
3. In Xcode, set your Bundle Identifier and Development Team under Signing & Capabilities for all targets.