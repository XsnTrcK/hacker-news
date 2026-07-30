## Context

`assets/readability-bundle.js` is currently a tracked file, produced by manually running `scripts/download_readability.sh`. The actual release build commands for iOS and Android exist only as shell one-liners passed around outside the repo (per the user's request), not as scripts. There's no single command that guarantees the bundle is present and fresh before a release build runs.

## Goals / Non-Goals

**Goals:**
- Stop tracking `assets/readability-bundle.js` in git without breaking local builds (the file must still exist on disk at build time, since `pubspec.yaml` references it as an asset).
- Provide one command per platform (`scripts/build_ios.sh`, `scripts/build_android.sh`) that reproduces the exact release build steps currently done by hand.
- Avoid unnecessary network calls: once downloaded, the bundle shouldn't be re-fetched from unpkg on every build unless explicitly forced.

**Non-Goals:**
- Not changing how the bundle is consumed at runtime (`web_view_carrier.dart` still loads it via `rootBundle.loadString`).
- Not adding CI/CD pipeline integration — these are local developer-invoked scripts only.
- Not changing the Readability.js version or vendoring strategy.

## Decisions

- **Untrack via `git rm --cached` + `.gitignore` entry**, rather than deleting and re-adding: preserves the working-tree file so nothing breaks mid-change, while removing it from future commits. Existing git history still contains old copies, but that's an accepted trade-off (rewriting history is out of scope and riskier than the tracking bloat it solves).
- **Two new scripts, not one parameterized script**: `build_ios.sh` and `build_android.sh` mirror how the user already thinks about these builds (two separate commands they run by hand), and keeps each script a simple, readable line-by-line translation of the existing one-liner. A shared `--force` flag is passed through to `download_readability.sh` rather than duplicating download logic in each build script.
- **Idempotent `download_readability.sh`**: add a check-if-exists guard (`[ -f "$BUNDLE_OUTPUT" ] && [ "$1" != "--force" ] && exit 0`) at the top. Alternative considered: always re-download on every build for maximum freshness — rejected because it adds a network dependency (and a failure point) to every single local build for a file that changes only when Mozilla ships a new Readability version, which happens rarely and is an explicit, deliberate action (bumping `READABILITY_VERSION` in the script) rather than something that should silently re-fetch.
- **Build scripts call `download_readability.sh` directly** (not a Makefile or Flutter build hook): keeps the change additive and avoids introducing a new build-orchestration layer for a two-script use case.

## Risks / Trade-offs

- [Existing git history still contains old bundle blobs, so this doesn't reclaim past repo size] → Accepted; a history rewrite (`git filter-repo`) is a separate, higher-risk decision the user hasn't asked for.
- [A contributor who runs `flutter build ipa`/`flutter build apk` directly instead of the new scripts will get a build failure — the asset won't exist] → Mitigate by keeping `scripts/download_readability.sh` as a clearly named, discoverable single entry point, and noting the requirement in the scripts' own output/README if one exists; this is a one-time discoverability cost, not a functional regression, since the file was never committed in a truly clean clone before either (it's just moving from "commit" to "script" as the source of truth).
- [`--force` flag on `download_readability.sh` changes its CLI contract] → Low risk: the script currently takes no arguments and isn't invoked elsewhere in the repo besides directly by a developer.

## Migration Plan

1. Run `git rm --cached assets/readability-bundle.js` and add the path to `.gitignore`.
2. Update `scripts/download_readability.sh` to skip work when the bundle already exists, honoring a `--force` override.
3. Add `scripts/build_ios.sh` and `scripts/build_android.sh`, each calling `download_readability.sh` then the corresponding `flutter build` sequence.
4. Verify a clean checkout (bundle absent) followed by each build script produces a working build.

No rollback complexity: if this needs to be reverted, re-add the file with `git add -f assets/readability-bundle.js` and remove the `.gitignore` entry.

## Open Questions

- None — the user provided the exact build commands to wrap, so there are no unresolved behavioral questions.
