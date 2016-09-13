[![Build Status](https://travis-ci.org/transloadit/ruby-sdk.png?branch=master)](https://travis-ci.org/transloadit/ruby-sdk)
[![Code Climate](https://codeclimate.com/github/transloadit/ruby-sdk.png)](https://codeclimate.com/github/transloadit/ruby-sdk)
[![Dependency Status](https://gemnasium.com/transloadit/ruby-sdk.png)](https://gemnasium.com/transloadit/ruby-sdk)

# transloadit

Fantastic file uploading for your web application.

## Description

This is the official Ruby gem for [Transloadit](http://transloadit.com). It allows
you to automate uploading files through the Transloadit REST API.

If you run Ruby on Rails and are looking to integrate with the browser for file uploads,
checkout the [rails-sdk](https://github.com/transloadit/rails-sdk).

## Install

```bash
gem install transloadit
```

## Getting started

To get started, you need to require the 'transloadit' gem:

```bash
$ irb -rubygems
>> require 'transloadit'
=> true
```

Then create a Transloadit instance, which will maintain your authentication
credentials and allow us to make requests to the API.

```ruby
transloadit = Transloadit.new(
  :key    => 'transloadit-auth-key',
  :secret => 'transloadit-auth-secret'
)
```

### 1. Resize and store an image

This example demonstrates how you can create an assembly to resize an image
and store the result on [Amazon S3](http://aws.amazon.com/s3/).

First, we create two steps: one to resize the image to 320x240, and another to
store the image in our S3 bucket.

```ruby
resize = transloadit.step 'resize', '/image/resize',
  :width  => 320,
  :height => 240

store  = transloadit.step 'store', '/s3/store',
  :key    => 'aws-access-key-id',
  :secret => 'aws-secret-access-key',
  :bucket => 's3-bucket-name'
```

Now that we have the steps, we create an assembly (which is just a request to
process a file or set of files) and let Transloadit do the rest.

```ruby
assembly = transloadit.assembly(
  :steps => [ resize, store ]
)

response = assembly.create! open('lolcat.jpg')

# loop until processing is finished
until response.finished?
  sleep 1; response.reload! # you'll want to implement a timeout in your production app
end

if response.error?
 # handle error
else
 # handle other cases
end
```
*(note: the assembly method `submit!` has been deprecated and replaced with `create!`.
The submit! method remains as an alias of `create!` for backward Compatibility)*

When the `create!` method returns, the file has been uploaded but may not yet
be done processing. We can use the returned object to check if processing has
completed, or examine other attributes of the request.

```ruby
# returns the unique API ID of the assembly
response[:assembly_id] # => '9bd733a...'

# returns the API URL endpoint for the assembly
response[:assembly_url] # => 'http://api2.vivian.transloadit.com/assemblies/9bd733a...'

# checks how many bytes were expected / received by transloadit
response[:bytes_expected] # => 92933
response[:bytes_received] # => 92933

# checks if all processing has been finished
response.finished? # => false

# cancels further processing on the assembly
response.cancel! # => true

# checks if processing was succesfully completed
response.completed? # => true

# checks if the processing returned with an error
response.error? # => false
```

It's important to note that none of these queries are "live" (with the
exception of the `cancel!` method). They all check the response given by the
API at the time the assembly was created. You have to explicitly ask the
assembly to reload its results from the API.

```ruby
# reloads the response's contents from the REST API
response.reload!
```

In general, you use hash accessor syntax to query any direct attribute from
the [response](http://transloadit.com/docs/assemblies#response-format).
Methods suffixed by a question mark provide a more readable way of quering
state (e.g., `assembly.completed?` vs. checking the result of
`assembly[:ok]`). Methods suffixed by a bang make a live query against the
Transloadit HTTP API.

### 2. Uploading multiple files

Multiple files can be given to the `create!` method in order to upload more
than one file in the same request. You can also pass a single step for the
`steps` parameter, without having to wrap it in an Array.

```ruby
assembly = transloadit.assembly(steps: store)

response = assembly.create!(
  open('puppies.jpg'),
  open('kittens.jpg'),
  open('ferrets.jpg')
)
```

You can also pass an array of files to the `create!` method. Just unpack the array using the splat `*` operator.
```ruby
files = [open('puppies.jpg'), open('kittens.jpg'), open('ferrets.jpg')]
response = assembly.create! *files
```

### 3. Parallel Assembly

Transloadit allows you to perform several processing steps in parallel. You
simply need to `use` other steps. Following
[their example](http://transloadit.com/docs/assemblies#special-parameters):

```ruby
encode = transloadit.step 'encode', '/video/encode', { ... }
thumbs = transloadit.step 'thumbs', '/video/thumbs', { ... }
export = transloadit.step 'store',  '/s3/store',     { ... }

export.use [ encode, thumbs ]

transloadit.assembly(
  :steps => [ encode, thumbs, export ]
).create! open('ninja-cat.mpg')
```

You can also tell a step to use the original uploaded file by passing the
Symbol `:original` instead of another step.

Check the YARD documentation for more information on using
[use](http://rubydoc.info/gems/transloadit/frames/Transloadit/Step#use-instance_method).

### 4. Creating an Assembly with Templates

Transloadit allows you to use custom [templates](https://github.com/transloadit/ruby-sdk/blob/master/README.md#8-templates)
for recurring encoding tasks. In order to use these do the following:

```ruby
transloadit.assembly(
  :template_id => 'YOUR_TEMPLATE_ID'
).create! open('ninja-cat.mpg')
```

You can use your steps together with this template and even use variables.
The [Transloadit documentation](http://transloadit.com/docs/templates#passing-variables-into-a-template) has some nice
examples for that.

### 5. Using fields

Transloadit allows you to submit form field values that you'll get back in the
notification. This is quite handy if you want to add additional custom meta data
to the upload itself. You can use fields like the following:

```ruby
transloadit.assembly(
  :fields => {:tag => 'ninjacats'}
).create! open('ninja-cat.mpg')
```

### 6. Notify URL

If you want to be notified when the processing is finished you can provide
a notify url for the assembly.

```ruby
transloadit.assembly(
  :notify_url => 'http://example.com/processing_finished'
).create! open('ninja-cat.mpg')
```

### 7. Other Assembly methods

Transloadit also provides methods to retrieve/replay assemblies and their notifications.

```ruby
assembly = transloadit.assembly

# returns a list of all assemblies
assembly.list

# returns a specific assembly
assembly.get 'YOUR_ASSEMBLY_ID'

# replays a specific assembly
response = assembly.replay 'YOUR_ASSEMBLY_ID'
# should return true if assembly is replaying and false otherwise.
response.replaying?

# returns all assembly notifications
assembly.get_notifications

# replays an assembly notification
assembly.replay_notification 'YOUR_ASSEMBLY_ID'
```

### 8. Templates

Transloadit provides a [templates api](https://transloadit.com/docs/templates)
for recurring encoding tasks. Here's how you would create a template:

```ruby
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

There are also some other methods to retrieve, update and delete a template.

```ruby
# returns a list of all templates.
template.list

# returns a specific template.
template.get 'YOUR_TEMPLATE_ID'

# updates the template whose id is specified.
template.update(
  'YOUR_TEMPLATE_ID',
  :name => 'CHANGED_TEMPLATE_NAME',
  :template => {
    "steps": {
      "encode": {
        "use": ":original",
        "robot": "/video/merge"
      }
    }
  }
)

# deletes a specific template
template.delete 'YOUR_TEMPLATE_ID'
>>>>>>> docs: update README and CHANGELOG
```

Read up more on the notifications [on Transloadit's documentation page](http://transloadit.com/docs/notifications-vs-redirect-url)

### 9. Getting Bill reports

If you want to retrieve your transloadit account billing report for a particular month and year
you can use the `bill` method passing the required month and year like the following:

```ruby
# returns bill report for February, 2016.
transloadit.bill(month=2, year=2016)
```
Not specifying the `month` or `year` would default to the current month or year.

## Documentation

Up-to-date YARD documentation is automatically generated. You can view the
docs for the [released gem](http://rubydoc.info/gems/transloadit/frames) or
for the latest [git master](http://rubydoc.info/github/transloadit/ruby-sdk/master/frames).

## Compatibility

At a minimum, this gem should work on MRI 2.3.0, 2.2.0, 2.1.0, Rubinius,
and JRuby. It may also work on older ruby versions, but support for those
Rubies is not guaranteed. If it doesn't work on one of the officially supported Rubies, please file a
[bug report](https://github.com/transloadit/ruby-sdk/issues). Compatibility patches for other Rubies
are welcome.

Testing against these versions is performed automatically by
[Travis CI](https://travis-ci.org/transloadit/ruby-sdk).

### Ruby 1.9.x & 2.0

If you still need support for older versions of Ruby, 1.2.0 is the last version that
supports those.
