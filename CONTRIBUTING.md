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

1. Update the version and changelog:
   - Bump `lib/transloadit/version.rb`.
   - Add a corresponding entry to `CHANGELOG.md`.
2. Run the full test suite (including Docker, parity, and e2e checks as needed).
3. Commit the release changes and tag:
   ```bash
   git commit -am "Release X.Y.Z"
   git tag -a vX.Y.Z -m "Release X.Y.Z"
   ```
4. Push the commit and tag:
   ```bash
   git push origin main
   git push origin vX.Y.Z
   ```
5. Publish the gem using the helper script:
   ```bash
   GEM_HOST_API_KEY=... ./scripts/notify-registry.sh
   ```
6. Publish the GitHub release notes:
   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z" --notes "$(ruby -e 'puts File.read("CHANGELOG.md")[/^### #{ARGV[0].dump.gsub(/\"/, "\\\"")}/, /\A### /m] || "")'"
   ```
   Adjust the notes if needed before publishing.

### RubyGems Credentials

- You must belong to the `transloadit` organization on RubyGems with permission to push the `transloadit` gem.
- Generate an API key with **Push Rubygems** permissions at <https://rubygems.org/profile/edit>. Copy the token and keep it secure.
- Export the token as `GEM_HOST_API_KEY` in your environment before running `./scripts/notify-registry.sh`. The script refuses to run if the variable is missing.

That’s it! Thank you for contributing.
