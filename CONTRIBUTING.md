# Contributing

Thanks for helping improve the Transloadit Ruby SDK! This guide covers local development, testing, and publishing new releases.

## Local Development

After cloning the repository, install dependencies and run the test suite:

```bash
bundle install
bundle exec rake test
```

To exercise the signature parity suite against the Node.js CLI, make sure `npx transloadit` is available and run:

```bash
TEST_NODE_PARITY=1 bundle exec rake test
```

You can warm the CLI cache ahead of time:

```bash
TRANSLOADIT_KEY=... TRANSLOADIT_SECRET=... \
  npx --yes transloadit smart_sig --help
TRANSLOADIT_KEY=... TRANSLOADIT_SECRET=... \
  npx --yes transloadit sig --algorithm sha384 --help
```

Set `COVERAGE=0` to skip coverage instrumentation if desired:

```bash
COVERAGE=0 bundle exec rake test
```

## Docker Workflow

The repository ships with a helper that runs tests inside a reproducible Docker image:

```bash
./scripts/test-in-docker.sh
```

Pass a custom command to run alternatives (Bundler still installs first):

```bash
./scripts/test-in-docker.sh bundle exec ruby -Itest test/unit/transloadit/test_request.rb
```

The script forwards environment variables such as `TEST_NODE_PARITY` and credentials from `.env`, so you can combine parity checks and integration tests. End-to-end uploads are enabled by default; unset them by running:

```bash
RUBY_SDK_E2E=0 ./scripts/test-in-docker.sh
```

## Live End-to-End Test

To exercise the optional live upload:

```bash
RUBY_SDK_E2E=1 TRANSLOADIT_KEY=... TRANSLOADIT_SECRET=... \
  ./scripts/test-in-docker.sh bundle exec ruby -Itest test/integration/test_e2e_upload.rb
```

The test uploads `chameleon.jpg`, resizes it, and asserts on a real assembly response.

## Releasing to RubyGems

Publishing is manual: `scripts/notify-registry.sh` builds and pushes the gem through Docker. Pushing a tag or creating a GitHub release does not publish to RubyGems; `.github/workflows/ci.yml` only runs checks.

Before changing the version, have Docker running, Ruby 3.1+ (for the release notes and install check), Git, and an authenticated GitHub CLI (`gh`). Confirm you can push signed commits to `main` and push tags. Load `GEM_HOST_API_KEY` as described under [RubyGems Credentials](#rubygems-credentials) before committing or tagging, and configure `TRANSLOADIT_KEY` and `TRANSLOADIT_SECRET` for the live test (the Docker test helper also reads `.env`).

Run the following steps from the repository root, in the same shell:

1. Start with a clean checkout (`git status --short` must be empty), then update `main`:
   ```bash
   git switch main
   git pull --ff-only origin main
   ```
2. Update the version and changelog:
   - Use semantic versioning: patch for fixes, minor for backward-compatible additions or deprecations, major for breaking changes or removals.
   - Bump `lib/transloadit/version.rb`.
   - Move the `CHANGELOG.md` Unreleased bullets under `### X.Y.Z / YYYY-MM-DD`, leaving an empty `### Unreleased` heading above them. Use those bullets for the release notes.
   - Read the chosen version for the remaining commands, and confirm it has not already been tagged or published:
     ```bash
     version=$(ruby -Ilib -rtransloadit/version -e 'puts Transloadit::VERSION')
     git ls-remote --tags origin "refs/tags/v$version"
     gem list transloadit --remote --exact --all --clear-sources --source https://rubygems.org
     ```
3. Run the full Docker suite with Node signature parity and the live upload, then lint:
   ```bash
   TEST_NODE_PARITY=1 RUBY_SDK_E2E=1 ./scripts/test-in-docker.sh
   RUBY_SDK_E2E=0 ./scripts/test-in-docker.sh bundle exec standardrb
   ```
   Confirm the parity and live tests ran rather than skipped. The live test uploads a fixture to Transloadit and requires working credentials.
4. Commit only the release files with a signed commit, and create the annotated tag:
   ```bash
   git add lib/transloadit/version.rb CHANGELOG.md
   git commit -S -m "Release v$version"
   git tag -a "v$version" -m "Release v$version"
   ```
5. Push the commit and tag:
   ```bash
   git push origin main
   git push origin "v$version"
   ```
   Wait for CI on this exact `main` commit to pass, including all supported Ruby versions and the e2e job.
6. Publish the gem using the helper script with the already-exported key:
   ```bash
   ./scripts/notify-registry.sh
   ```
   If authentication or push permissions fail, stop and obtain the required access. If the version is already published, verify it before retrying; RubyGems versions cannot be overwritten.
7. Publish the GitHub release notes from the version's changelog entry. This fails before creating a release if the entry is missing or empty, and requires the pushed tag:
   ```bash
   (
     set -eu
     notes_file=$(mktemp)
     trap 'rm -f "$notes_file"' EXIT
     ruby -e '
       version = ARGV.fetch(0)
       entry = File.read("CHANGELOG.md").split(/^### /).find { |section| section.start_with?("#{version} / ") }
       abort "No changelog entry for #{version}" unless entry
       notes = entry.lines.drop(1).join.strip
       abort "Empty changelog entry for #{version}" if notes.empty?
       puts notes
     ' "$version" > "$notes_file"
     gh release create "v$version" --verify-tag --title "v$version" --notes-file "$notes_file"
   )
   ```
8. Verify the remote listing, then install the published gem in a scratch directory and check `uploads:` without an API call:
   ```bash
   gem list transloadit --remote --exact --clear-sources --source https://rubygems.org
   (
     set -eu
     scratch_dir=$(mktemp -d)
     trap 'rm -rf "$scratch_dir"' EXIT
     gem install transloadit --remote --clear-sources --source https://rubygems.org --version "$version" --no-document --install-dir "$scratch_dir/gems"
     GEM_HOME="$scratch_dir/gems" GEM_PATH="$scratch_dir/gems" ruby -rtransloadit -rstringio -e '
       abort "Unexpected gem version" unless Transloadit::VERSION == ARGV.fetch(0)
       fields = {count: 2, enabled: false}
       assembly = Transloadit.new(key: "offline-smoke").assembly(uploads: {photo: StringIO.new("photo")}, fields: fields)
       instructions = assembly.to_hash
       abort "Upload leaked into JSON" if instructions.key?(:uploads)
       abort "Custom fields changed" unless instructions[:fields] == fields
       puts "transloadit #{Transloadit::VERSION}: uploads smoke passed"
     ' "$version"
   )
   ```
   `--remote` avoids a leftover local `.gem`, and `--clear-sources --source` selects rubygems.org even when other gem sources are configured. The smoke check builds Instructions without creating an Assembly; step 3 exercises multipart requests. Allow time for RubyGems indexing if the new version is not visible immediately.

### RubyGems Credentials

- Use a RubyGems account authorized to push the `transloadit` gem, with an API key granting [**Push rubygems**](https://guides.rubygems.org/api-key-scopes/) permissions (and access to `transloadit` if the key is gem-scoped).
- Export the key as `GEM_HOST_API_KEY` through your secret manager or a separate credential file outside the checkout. Do not put the token in shell commands or logs. The publish helper requires this environment variable; it does not load `.env` or use the host's `~/.gem/credentials`.
- Keep the publishing key out of the test `.env`: `scripts/test-in-docker.sh` passes that entire file to the container running dependency installation, tests, and Node tooling. An exported host `GEM_HOST_API_KEY` is not forwarded by the test helper.
- Confirm the key is loaded without displaying it:
  ```bash
  test -n "${GEM_HOST_API_KEY:-}"
  ```

That’s it! Thank you for contributing.
