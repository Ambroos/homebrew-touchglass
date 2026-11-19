# Homebrew tap for TouchGlass

[TouchGlass](https://github.com/ambroos/touchglass) shows one Liquid Glass panel for YubiKey operations through gpg-agent: it asks for the PIN, then tells you to touch the key. It needs macOS 26 or later.

## Install

```sh
brew install ambroos/touchglass/touchglass
touchglass install
```

The formula installs `gnupg` and `pinentry-mac` if they're missing, puts `TouchGlass.app` in `$(brew --prefix)/opt/touchglass` and links the `touchglass` command into Homebrew's `bin` directory. The tap's releases provide bottles for Apple silicon; on an Intel Mac, Homebrew builds TouchGlass from source, which needs the Command Line Tools (see [Build from source](#build-from-source)). Installing the formula doesn't change your GnuPG setup.

`touchglass install` prints the change to make in `gpg-agent.conf`; `touchglass install --apply` makes it. Upgrades with `brew upgrade touchglass` need no new `touchglass install`. Before `brew uninstall touchglass`, run `touchglass uninstall --apply` to restore `gpg-agent.conf`.

For what each command changes, upgrades, uninstalling and troubleshooting, see [Install and uninstall TouchGlass](https://github.com/ambroos/touchglass/blob/main/docs/install.md).

## Build from source

```sh
brew install --build-from-source ambroos/touchglass/touchglass
brew install --HEAD ambroos/touchglass/touchglass
```

Building needs the Command Line Tools for macOS 26 or later, which provide Swift and the macOS SDK; install them with `xcode-select --install`. Xcode isn't required. `--HEAD` builds the `main` branch.

## Publish a release

A release takes two steps: push the version tag to the TouchGlass repository, then run the Release workflow here.

1. In the TouchGlass repository, run `scripts/release.sh <version>` on a commit of `main` for the notarized zip. Push the tag with the command it prints, wait until the Tests run for the tag passes, then create the GitHub release with the command it prints. The tag must look like `v1.2.3`.
2. Run the Release workflow, from the Actions tab of this repository (**Release** > **Run workflow**) or with the GitHub CLI:

   ```sh
   gh workflow run release.yml -R ambroos/homebrew-touchglass
   gh workflow run release.yml -R ambroos/homebrew-touchglass -f version=1.2.3
   ```

   Without a version, the workflow releases the latest `v*.*.*` tag of TouchGlass.

The workflow runs on the `macos-26` runner. It sets `url` and `sha256` in `Formula/touchglass.rb` to the tag's source tarball, builds and tests a bottle for Apple silicon with `brew test-bot`, as the pull request checks do, and runs `brew audit --strict --online`. It then uploads the bottle to the release `touchglass-<version>` in this repository, adds the `bottle do` block to the formula and commits the formula to `main` through the GitHub API, so that GitHub signs the commit. The workflow needs no token or secret besides the `GITHUB_TOKEN` that GitHub Actions provides.

Run the workflow from `main`. Running it again for the same version changes nothing if the formula on `main` already has that version and its bottle. If an earlier run failed after it uploaded the bottle, the next run builds and tests the bottle again, then replaces that release; it never deletes a release that the formula on `main` uses. Only one release runs at a time.

To fix the formula without a new TouchGlass version, open a pull request that changes it and adds or raises `revision`; the `brew test-bot` workflow builds and tests it. After you merge the pull request, run the Release workflow with the same version to publish a bottle for the new revision.

If the formula on `main` already has the version that a run releases, as after a merged `revision`, `brew bottle` counts the new bottle as a rebuild: the bottle is named like `touchglass-0.1.0_1.arm64_tahoe.bottle.1.tar.gz` and the `bottle do` block gets `rebuild 1`. Homebrew installs it like any other bottle. For the same reason, leave the placeholder `url` in the formula alone until the workflow publishes the first release.

If the version is published already and its source tarball changed, for example because the tag moved, the workflow stops without changing anything. Release a new version instead, or add a `revision`.

Before you open a pull request, check the formula:

```sh
brew style ambroos/touchglass
brew audit --strict --formula ambroos/touchglass/touchglass
```
