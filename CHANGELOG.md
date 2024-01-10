### 3.0.1 / 2024-01-10

- Fix `undefined method` errors when handling network exceptions [#67](https://github.com/transloadit/ruby-sdk/pull/67) (@Acconut)

### 3.0.0 / 2024-01-10

- BREAKING: Drop support for EOL'd Ruby 2.x
- Ensure that signature is sent before files [#65](https://github.com/transloadit/ruby-sdk/pull/65) (@Acconut)
- Send requests via HTTPS by default [#64](https://github.com/transloadit/ruby-sdk/pull/64) (@Acconut)
- Prevent duplicate assembly steps [#49](https://github.com/transloadit/ruby-sdk/issues/27) (@ifedapoolarewaju)
- Send "Transloadit-Client" header for every request (@ifedapoolarewaju)
- Send all requests via HTTPS by default
- Position signature before any files in requests [#51](https://github.com/transloadit/ruby-sdk/issues/51)

### 2.0.1 / 2017-01-23

- Use the ssl enabled url as the API base url (@ifedapoolarewaju)

### 2.0.0 / 2016-12-03

- Drop support for EOL'd Ruby 1.9.x and Ruby 2.0, please use version 1.2.0 if you need support for older
  Ruby versions.
- Fix compatibility to Ruby >=2.1 and Rails 5.
- Remove bored instance logic (thanks @ifedapoolarewaju for the PR). This shouldn't affect users at all and removes
  the need for another HTTP request before the actual HTTP request.
- We now have the `transloadit.bill` method to retrieve billing reports. (@ifedapoolarewaju)
- Deprecate `assembly.submit!` method for `assembly.create!`. This shouldn't affect users as the `submit!` method remains
  as an alias for `create!`. (@ifedapoolarewaju)
- Add support for new `assembly` methods (Thanks @ifedapoolarewaju):
  - list to get a list of all assemblies.
  - get to retrieve a particular assembly. Requires assembly id to be passed as argument.
  - replay to replay a particular assembly. Requires assembly id to be passed as argument.
  - get_notifications to get a list of all assembly notifications.
  - replay_notification to replay the notification of a particular assembly. Requires assembly id to be passed as argument.
- We now have a Template api with the following methods:
  - create to create a new template.
  - list to get a list of all templates.
  - get to retrieve a particular template.
  - update to update a particular template.
  - delete to delete a particular template.
- Add rate limit feature to implicitly retry assembly creation when the rate limit is reached.
- Add `assembly.reload_until_finished!` which calls `reload!` once per second until assembly is finished (@gbuesing)
- Added example files with a [small tutorial](examples/README.md) in `examples` (@jasonaibrahim)

### 1.2.0 / 2015-12-28

- allow custom fields to be passed to Transloadit and received back in the response (thanks @Acconut for the pull request)

### 1.1.4 / 2015-12-14

- fix Ruby 1.9.x compatibility by explicitly requiring mime-types 2.99

### 1.1.3 / 2014-08-21

- Use rest-client < 1.7.0 for Ruby version below 1.9 to stay 1.8 compatible.

### 1.1.2 / 2014-06-17

- Fix deprecation warning on Ruby 2.1.0 for OpenSSL::Digest (thanks @pekeler for the patch)

### 1.1.1 / 2013-06-25

- request.get with secret (thanks @miry for the patch)

### 1.1.0 / 2013-04-22

- We now have more statuses available in the response:
  - finished? to check if processing is finished
  - error? to check if processing failed with errors
  - canceled? to check if processing was canceled
  - aborted? to check if processing was aborted
  - executing? to check if processing is still executing
  - uploading? to check if the upload is still going
- Please use `finished?` to check if procssing is finished and `completed?` to
  check if completed successfully

### 1.0.5 / 2013-03-13

- Use MultiJSON so everyone can use the JSON parser they like. (thanks @kselden for the patch)
- Switch to Kramdown for RDoc formatting
- Support jRuby 1.8/1.9 and MRI 2.0.0 too

### 1.0.4 / 2013-03-06

- allow symbols as keys for response attributes (thanks @gbuesing for reporting)

### 1.0.3 / 2012-11-10

- Support max_size option

### 1.0.1 / 2011-02-08

[Full list of changes](https://github.com/transloadit/ruby-sdk/compare/v1.0.0...v1.0.1)

- Enhancements

  - support custom form fields for Transloadit::Assembly

- New Maintainers
  - Robin Mehner <robin@coding-robin.de>

### 1.0.0 / 2011-09-06

- Initial release
