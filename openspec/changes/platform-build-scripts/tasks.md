## 1. Untrack the readability bundle

- [ ] 1.1 Run `git rm --cached assets/readability-bundle.js` so the file stays on disk but is no longer tracked
- [ ] 1.2 Add `assets/readability-bundle.js` to `.gitignore`

## 2. Make the download script idempotent

- [ ] 2.1 Update `scripts/download_readability.sh` to exit early (no network calls) if `assets/readability-bundle.js` already exists
- [ ] 2.2 Add a `--force` flag to `scripts/download_readability.sh` that bypasses the exists-check and re-downloads

## 3. Add platform build scripts

- [ ] 3.1 Create `scripts/build_ios.sh`: call `scripts/download_readability.sh`, then run `flutter clean && rm ios/Podfile.lock pubspec.lock && rm -rf ios/Pods/ ios/Runner.xcworkspace && flutter build ipa --no-sound-null-safety`
- [ ] 3.2 Create `scripts/build_android.sh`: call `scripts/download_readability.sh`, then run `flutter build apk --split-per-abi --no-sound-null-safety`
- [ ] 3.3 Make both new scripts executable (`chmod +x`)

## 4. Verify

- [ ] 4.1 Delete the local `assets/readability-bundle.js` and confirm `scripts/build_android.sh` regenerates it and produces a build
- [ ] 4.2 Re-run `scripts/build_android.sh` a second time and confirm no network download happens on the second run (idempotent skip)
- [ ] 4.3 Run `scripts/download_readability.sh --force` and confirm it re-downloads even though the bundle already exists
