# Migrating from v3 to v4

Version 4 replaces the `rest-client` HTTP transport with Faraday 2. Most applications only use the
Transloadit API exposed by this gem and do not need code changes. The migration is a major release
because v3 also delegated undocumented methods to RestClient response objects and exposed
RestClient exception inheritance.

Version 4 requires Ruby 3.1 or newer. The final v3 release allowed Ruby 3.0, so applications still
running Ruby 3.0 must upgrade Ruby before updating this gem.

## Update the dependency

Once v4 is released, update the application Gemfile and bundle:

```ruby
gem "transloadit", "~> 4.0"
```

```shell
bundle update transloadit
```

The SDK installs Faraday and its multipart middleware. Applications do not need to add Faraday
directly. Remove an explicit `rest-client` dependency only if the application does not use it for
anything else. Version 4 no longer installs or loads the `RestClient` constant on the application's
behalf.

## Responses

Use the SDK-owned response API:

```ruby
response = transloadit.assembly.get(assembly_id)

response["ok"]
response[:assembly_id]
response.body
response.headers
response.code
response.status
```

`code` continues to return the integer HTTP status, and `status` is its new explicit alias. Header
names remain normalized to lowercase symbols with underscores, for example
`response.headers[:retry_after]`.

HTTP error statuses still return `Transloadit::Response` objects. They are not converted into
transport exceptions:

```ruby
response = transloadit.assembly.get(assembly_id)

if response.code >= 400
  warn response["error"]
end
```

### Remove raw RestClient response usage

In v3, `Transloadit::Response` delegated unknown methods to a `RestClient::Response`. Version 4 no
longer exposes the underlying HTTP client. Replace calls to RestClient-specific response methods
with the SDK-owned response API above.

For example:

```ruby
# v3: relied on the delegated RestClient object
response.raw_headers

# v4
response.headers
```

If an application relies on another delegated method that has no equivalent, open an issue with the
use case before upgrading.

## Request failures

Network, TLS, and timeout failures now raise `Transloadit::Exception::RequestFailed` instead of a
RestClient exception:

```ruby
# v3
begin
  transloadit.assembly.get(assembly_id)
rescue RestClient::Exception => error
  warn error.message
end

# v4
begin
  transloadit.assembly.get(assembly_id)
rescue Transloadit::Exception::RequestFailed => error
  warn error.message
end
```

The original adapter exception is retained as `error.cause` for diagnostics. Avoid branching on its
class so application behavior does not become coupled to Faraday.

## Rate-limit failures

Continue rescuing the SDK exception directly:

```ruby
begin
  assembly.create!(file)
rescue Transloadit::Exception::RateLimitReached => error
  retry_after = error.response.wait_time
end
```

`RateLimitReached` remains a `StandardError` and retains its Transloadit response through
`error.response`, but it no longer inherits from `RestClient::RequestEntityTooLarge`. Replace code
that rescues the RestClient superclass with the SDK exception.

## Uploaded file handles

Version 4 does not close path-backed file objects supplied by the caller. Prefer a block so ownership
is explicit:

```ruby
File.open("video.mp4", "rb") do |file|
  assembly.create!(file)
end
```

Multipart field order is unchanged: `params` and `signature` are sent before file bodies.

## Upgrade checklist

- Update the gem and run the application's request and upload tests.
- Replace rescues of `RestClient::Exception` and `RestClient::RequestEntityTooLarge`.
- Replace calls to delegated RestClient response methods.
- Confirm the application closes files that it opens.
- Remove the direct `rest-client` dependency if nothing else uses it.
