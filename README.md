[![Build Status](https://github.com/transloadit/ruby-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/transloadit/ruby-sdk/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/transloadit/ruby-sdk.png)](https://codeclimate.com/github/transloadit/ruby-sdk)

## ruby-sdk

A **Ruby** Integration for [Transloadit](https://transloadit.com)'s file uploading and encoding service

## Intro

[Transloadit](https://transloadit.com) is a service that helps you handle file uploads, resize, crop and watermark your images, make GIFs, transcode your videos, extract thumbnails, generate audio waveforms, and so much more. In short, [Transloadit](https://transloadit.com) is the Swiss Army Knife for your files.

This is a **Ruby** SDK to make it easy to talk to the [Transloadit](https://transloadit.com) REST API.

_If you run Ruby on Rails and are looking to integrate with the browser for file uploads, checkout the [rails-sdk](https://github.com/transloadit/rails-sdk)._

## Install

```bash
gem install transloadit
```

## Usage

To get started, you need to require the 'transloadit' gem:

```bash
$ irb -rubygems
>> require 'transloadit'
=> true
```

Then create a Transloadit instance, which will maintain your
[authentication credentials](https://transloadit.com/accounts/credentials)
and allow us to make requests to [the API](https://transloadit.com/docs/api/).

```ruby
transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)
```

### 1. Resize and store an image

This example demonstrates how you can create an <dfn>Assembly</dfn> to resize an image
and store the result on [Amazon S3](https://aws.amazon.com/s3/).

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

# First, we create two steps: one to resize the image to 320x240, and another to
# store the image in our S3 bucket.
resize = transloadit.step 'resize', '/image/resize',
  :width  => 320,
  :height => 240

store  = transloadit.step 'store', '/s3/store',
  :key    => 'MY_AWS_KEY',
  :secret => 'MY_AWS_SECRET',
  :bucket => 'MY_S3_BUCKET'

# Now that we have the steps, we create an assembly (which is just a request to
# process a file or set of files) and let Transloadit do the rest.
assembly = transloadit.assembly(
  :steps => [ resize, store ]
)

response = assembly.create! open('/PATH/TO/FILE.jpg')

# reloads the response once per second until all processing is finished
response.reload_until_finished!

if response.error?
  # handle error
else
  # handle other cases
  puts response
end
```

<div class="alert alert-note">
  <strong>Note:</strong> The <dfn>Assembly</dfn> method <code>submit!</code> has been deprecated and replaced with <code>create!</code>.
  The <code>submit!</code> method remains as an alias of <code>create!</code> for backward Compatibility.
</div>

When the `create!` method returns, the file has been uploaded but may not yet
be done processing. We can use the returned object to check if processing has
completed, or examine other attributes of the request.

```ruby
# returns the unique API ID of the assembly
response[:assembly_id] # => '9bd733a...'

# returns the API URL endpoint for the assembly
response[:assembly_ssl_url] # => 'https://api2.vivian.transloadit.com/assemblies/9bd733a...'

# checks how many bytes were expected / received by transloadit
response[:bytes_expected] # => 92933
response[:bytes_received] # => 92933

# checks if all processing has been finished
response.finished? # => false

# cancels further processing on the assembly
response.cancel! # => true

# checks if processing was successfully completed
response.completed? # => true

# checks if the processing returned with an error
response.error? # => false
```

It's important to note that none of these queries are "live" (with the
exception of the `cancel!` method). They all check the response given by the
API at the time the <dfn>Assembly</dfn> was created. You have to explicitly ask the
<dfn>Assembly</dfn> to reload its results from the API.

```ruby
# reloads the response's contents from the REST API
response.reload!

# reloads once per second until all processing is finished, up to number of
# times specified in :tries option, otherwise will raise ReloadLimitReached
response.reload_until_finished! tries: 300 # default is 600
```

In general, you use hash accessor syntax to query any direct attribute from
the [response](https://transloadit.com/docs/api/#assembly-status-response).
Methods suffixed by a question mark provide a more readable way of querying
state (e.g., `assembly.completed?` vs. checking the result of
`assembly[:ok]`). Methods suffixed by a bang make a live query against the
Transloadit HTTP API.

### 2. Uploading multiple files

Multiple files can be given to the `create!` method in order to upload more
than one file in the same request. You can also pass a single <dfn>Step</dfn> for the
`steps` parameter, without having to wrap it in an Array.

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

assembly = transloadit.assembly(steps: store)

response = assembly.create!(
  open('puppies.jpg'),
  open('kittens.jpg'),
  open('ferrets.jpg')
)
```

You can also pass an array of files to the `create!` method.
Just unpack the array using the splat `*` operator.

```ruby
files = [open('puppies.jpg'), open('kittens.jpg'), open('ferrets.jpg')]
response = assembly.create! *files
```

### 3. Parallel Assembly

Transloadit allows you to perform several processing steps in parallel. You
simply need to `use` other <dfn>Steps</dfn>. Following
[their example](https://transloadit.com/docs/#special-parameters):

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

encode = transloadit.step 'encode', '/video/encode', { ... }
thumbs = transloadit.step 'thumbs', '/video/thumbs', { ... }
export = transloadit.step 'store',  '/s3/store',     { ... }

export.use [ encode, thumbs ]

transloadit.assembly(
  :steps => [ encode, thumbs, export ]
).create! open('/PATH/TO/FILE.mpg')
```

You can also tell a step to use the original uploaded file by passing the
Symbol `:original` instead of another step.

Check the YARD documentation for more information on using
[use](https://rubydoc.info/gems/transloadit/frames/Transloadit/Step#use-instance_method).

### 4. Creating an Assembly with Templates

Transloadit allows you to use custom [templates](https://github.com/transloadit/ruby-sdk/blob/main/README.md#8-templates)
for recurring encoding tasks. In order to use these do the following:

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

transloadit.assembly(
  :template_id => 'MY_TEMPLATE_ID'
).create! open('/PATH/TO/FILE.mpg')
```

You can use your steps together with this template and even use variables.
The [Transloadit documentation](https://transloadit.com/docs/#passing-variables-into-a-template)
has some nice examples for that.

### 5. Using fields

Transloadit allows you to submit form field values that you'll get back in the
notification. This is quite handy if you want to add additional custom metadata
to the upload itself. You can use fields like the following:

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

transloadit.assembly(
  :fields => {
    :tag => 'some_tag_name',
    :field_name => 'field_value'
  }
).create! open('/PATH/TO/FILE.mpg')
```

### 6. Notify URL

If you want to be notified when the processing is finished you can provide
a Notify URL for the <dfn>Assembly</dfn>.

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

transloadit.assembly(
  :notify_url => 'https://example.com/processing_finished'
).create! open('/PATH/TO/FILE.mpg')
```

Read up more on the <dfn>Notifications</dfn> [on Transloadit's documentation page](https://transloadit.com/docs/#notifications)

### 7. Other Assembly methods

Transloadit also provides methods to retrieve/replay <dfn>Assemblies</dfn> and their <dfn>Notifications</dfn>.

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

assembly = transloadit.assembly

# returns a list of all assemblies
assembly.list

# returns a specific assembly
assembly.get 'MY_ASSEMBLY_ID'

# replays a specific assembly
response = assembly.replay 'MY_ASSEMBLY_ID'
# should return true if assembly is replaying and false otherwise.
response.replaying?

# returns all assembly notifications
assembly.get_notifications

# replays an assembly notification
assembly.replay_notification 'MY_ASSEMBLY_ID'
```

### 8. Templates

Transloadit provides a [templates api](https://transloadit.com/docs/#templates)
for recurring encoding tasks. Here's how you would create a <dfn>Template</dfn>:

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

template = transloadit.template

# creates a new template
template.create(
  :name => 'TEMPLATE_NAME',
  :template => {
    "steps": {
      "encode": {
        "use": ":original",
        "robot": "/video/encode",
        "result": true
      }
    }
  }
)
```

There are also some other methods to retrieve, update and delete a <dfn>Template</dfn>.

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

template = transloadit.template

# returns a list of all templates.
template.list

# returns a specific template.
template.get 'MY_TEMPLATE_ID'

# updates the template whose id is specified.
template.update(
  'MY_TEMPLATE_ID',
  :name => 'CHANGED_TEMPLATE_NAME',
  :template => {
    :steps => {
      :encode => {
        :use => ':original',
        :robot => '/video/merge'
      }
    }
  }
)

# deletes a specific template
template.delete 'MY_TEMPLATE_ID'
```

### 9. Getting Bill reports

If you want to retrieve your Transloadit account billing report for a particular month and year
you can use the `bill` method passing the required month and year like the following:

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

# returns bill report for February, 2016.
transloadit.bill(2, 2016)
```

Not specifying the `month` or `year` would default to the current month or year.

### 10. Signing Smart CDN URLs

You can generate signed [Smart CDN](https://transloadit.com/services/content-delivery/) URLs using your Transloadit instance:

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

# Generate a signed URL using instance credentials
url = transloadit.signed_smart_cdn_url(
  workspace: "MY_WORKSPACE",
  template: "MY_TEMPLATE",
  input: "avatars/jane.jpg"
)

# Add URL parameters
url = transloadit.signed_smart_cdn_url(
  workspace: "MY_WORKSPACE",
  template: "MY_TEMPLATE",
  input: "avatars/jane.jpg",
  url_params: {
    width: 100,
    height: 200
  }
)

# Set expiration time
url = transloadit.signed_smart_cdn_url(
  workspace: "MY_WORKSPACE",
  template: "MY_TEMPLATE",
  input: "avatars/jane.jpg",
  expire_at_ms: 1732550672867  # Specific timestamp
)
```

The generated URL will be signed using your Transloadit credentials and can be used to access files through the Smart CDN in a secure manner.

### 11. Rate limits

Transloadit enforces rate limits to guarantee that no customers are adversely affected by the usage
of any given customer. See [Rate Limiting](https://transloadit.com/docs/api/#rate-limiting).

While creating an <dfn>Assembly</dfn>, if a rate limit error is received, by default, 2 more attempts would be made for a successful response. If after these attempts the rate limit error persists, a `RateLimitReached` exception will be raised.

To change the number of attempts that will be made when creating an <dfn>Assembly</dfn>, you may pass the `tries` option to your <dfn>Assembly</dfn> like so.

```ruby
require 'transloadit'

transloadit = Transloadit.new(
  :key    => 'MY_TRANSLOADIT_KEY',
  :secret => 'MY_TRANSLOADIT_SECRET'
)

# would make one extra attempt after a failed attempt.
transloadit.assembly(:tries => 2).create! open('/PATH/TO/FILE.mpg')

# Would make no attempt at all. Your request would not be sent.
transloadit.assembly(:tries => 0).create! open('/PATH/TO/FILE.mpg')
```

## Example

A small sample tutorial of using the Transloadit ruby-sdk to optimize an image, encode MP3 audio, add ID3 tags,
and more can be found [here](https://github.com/transloadit/ruby-sdk/tree/main/examples).

## Documentation

Up-to-date YARD documentation is automatically generated. You can view the
docs for the <a href="https://rubydoc.info/gems/transloadit/frames" rel="canonical">released gem</a> or
for the latest [git main](https://rubydoc.info/github/transloadit/ruby-sdk/main/frames).

## Compatibility

Please see [ci.yml](https://github.com/transloadit/ruby-sdk/tree/main/.github/workflows/ci.yml) for a list of supported ruby versions. It may also work on older Rubies, but support for those is not guaranteed. If it doesn't work on one of the officially supported Rubies, please file a
[bug report](https://github.com/transloadit/ruby-sdk/issues). Compatibility patches for other Rubies are welcome.

### Ruby 2.x

If you still need support for Ruby 2.x, 2.0.1 is the last version that supports it.

## Contributing

### Running tests

```bash
bundle install
bundle exec rake test
```

To also test parity against the Node.js reference implementation, run:

```bash
TEST_NODE_PARITY=1 bundle exec rake test
```

To disable coverage reporting, run:

```bash
COVERAGE=0 bundle exec rake test
```
