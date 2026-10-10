# Download a personal Mac build

Builds run in [your GitHub fork](https://github.com/willsantiagomedina/boring.notch/actions). You do not need Xcode installed locally.

1. Push changes to `main` or a `feature/` branch. Pull requests also trigger a build.
2. Open the **Build for macOS** workflow and select the run for your commit.
3. Wait for **Build downloadable Mac app** to succeed.
4. Download the `Boring-Notch-<commit>` artifact.
5. Extract the downloaded artifact, then extract `Boring-Notch.zip` inside it.
6. Quit any running copy of Boring Notch before opening this copy.

The artifact includes a source commit and a SHA-256 checksum. Builds target both Apple Silicon and Intel Macs with macOS 14 or later. They use ad hoc signing and are not notarized. If macOS blocks launch, review the message in System Settings > Privacy & Security before allowing the app. Do not disable Gatekeeper globally.

Automatic upstream updates are disabled in these builds so that an upstream release cannot replace your changes. Download a new artifact to update your copy. Existing app preferences and permissions may be shared with an installed upstream copy because the bundle identifier has not changed.

Failed builds upload a separate diagnostics artifact with the build log and an Xcode result bundle when available. Artifacts expire after 14 days and diagnostics after 7 days.

The workflow runs `scripts/build-ci.sh` on GitHub's `macos-15` runner with Xcode 16.4. It does not need Apple signing secrets and does not publish releases. The script modifies the checkout's Info.plist for the test build. Use it in a disposable checkout if running it outside CI.
