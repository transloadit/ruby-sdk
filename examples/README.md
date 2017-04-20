# Example Usage of the Transloadit Ruby SDK

### See an example
Navigate to an example directory (e.g. ```basic```) and then run the following, making sure to 
substitute your own values for the environment variables below:

```bash
TRANSLOADIT_KEY=<your-transloadit-key> \
TRANSLOADIT_SECRET=<your-transloadit-secret> \
main.rb
```

If you wish to store results from the encoding in an s3 bucket of your own, you can set your s3 credentials as well like so:

```bash
TRANSLOADIT_KEY=<your-transloadit-key> \
TRANSLOADIT_SECRET=<your-transloadit-secret> \
S3_BUCKET=<your-s3-bucket> \
S3_ACCESS_KEY=<your-s3-access-key> \ 
S3_SECRET_KEY=<your-s3-secret-key> \ 
S3_REGION=<your-s3-region> \ 
main.rb
```

Please be sure you have the `transloadit` gem installed by running `gem install transloadit` before running these examples.

##  Code Review

### Overview

In each example we utilize a simple base class `MediaTranscoder`. This class provides us a simple method:
 
```
transloadit_client
```

The method is responsible for returning us an instance of the Transloadit SDK object,
utilizing our credentials that we set in environment variables.

### First example

In the [first example](https://github.com/transloadit/ruby-sdk/blob/master/examples/basic/image-transcoder.rb)
that gets played, we fetch an image from the cat api, optimize it using the Transloadit `/image/optimize` robot, and then optionally
stores it in s3 if the s3 credentials are set.

There are only two steps:

```ruby
optimize = transloadit_client.step('image', '/image/optimize', {
  progressive: true,
  use: ':original',
  result: true
})

steps = [optimize]

begin
  store = transloadit_client.step('store', '/s3/store', {
    key: ENV.fetch('S3_ACCESS_KEY'),
    secret: ENV.fetch('S3_SECRET_KEY'),
    bucket: ENV.fetch('S3_BUCKET'),
    bucket_region: ENV.fetch('S3_REGION'),
    use: 'image'
  })

  steps.push(store)
rescue KeyError => e
  p 's3 config not set. Skipping s3 storage...'
end

 ```

Again, we utilize environment variables to access our s3 credentials if given and pass them to 
our assembly. If the s3 credentials are not set, this step is skipped and the transloadit temporary s3 storage is used.

The job is invoked by running the following:

```ruby
assembly = transloadit_client.assembly(steps: steps)
assembly.create! open(file)
```

We pass the steps we defined above and call `open` on the file passed in. This method
assumes the file object passed in responds to `open`.

### Second example

In the [second example](https://github.com/transloadit/ruby-sdk/blob/master/examples/basic/audio-transcoder.rb),
we take a non-mp3 audio file, encode it as an mp3, add ID3 tags to it, and then optionally store it in s3.
There are many use cases for audio uploads, and adding ID3 tags provides the necessary metadata to display artist and track information
in audio players such as iTunes.

We have the following steps:

```ruby
encode_mp3 = transloadit_client.step('mp3_encode', '/audio/encode', {
  use: ':original',
  preset: 'mp3',
  ffmpeg_stack: 'v2.2.3',
  result: true
})
write_metadata = transloadit_client.step('mp3', '/meta/write', {
  use: 'mp3_encode',
  ffmpeg_stack: 'v2.2.3',
  result: true,
  data_to_write: mp3_metadata
})

steps = [encode_mp3, write_metadata]

begin
  store = transloadit_client.step('store', '/s3/store', {
    key: ENV.fetch('S3_ACCESS_KEY'),
    secret: ENV.fetch('S3_SECRET_KEY'),
    bucket: ENV.fetch('S3_BUCKET'),
    bucket_region: ENV.fetch('S3_REGION'),
    use: ['mp3']
  })

  steps.push(store)
rescue KeyError => e
  p 's3 config not set. Skipping s3 storage...'
end
```

The first step simply uses the original file to create an mp3 version using the `audio/encode`
robot.

The second step takes the first step as input, and adds the appropriate metadata using the `meta/write`
robot. In our simple example we set the track name to the name of the file using variable
name substitution (see https://transloadit.com/docs/#assembly-variables), and set canned
values for all other ID3 fields

```ruby
def mp3_metadata
  meta = { publisher: 'Transloadit', title: '${file.name}' }
  meta[:album] = 'Transloadit Compilation'
  meta[:artist] = 'Transloadit'
  meta[:track] = '1/1'
  meta
end
```

Again, we utilize environment variables to access our s3 credentials if given and pass them to 
our assembly. If the s3 credentials are not set, this step is skipped and the transloadit temporary s3 storage is used.

Finally, we submit the assembly in the same way as the previous example:

```ruby
assembly = transloadit_client.assembly(steps: steps)
assembly.create! open(file)
```

### Third example

In the [third example](https://github.com/transloadit/ruby-sdk/blob/master/examples/basic/audio-concat-transcoder.rb),
we take a series of mp3 files and concatenate them together. We then optionally upload the result to s3.

This example is provided to showcase advanced usage of the `use` parameter in the `audio/concat` assembly.

In our `transcode` method, note that this time we are passed an array of files.

```ruby
concat = transloadit_client.step('concat', '/audio/concat', {
  ffmpeg_stack: 'v2.2.3',
  preset: 'mp3',
  use: {
    steps: files.map.each_with_index do |f, i|
      { name: ':original', as: "audio_#{i}", fields: "file_#{i}" }
    end
  },
  result: true
})
```

Taking a look at the `concat` step, we see a different usage of the `use` parameter
than we have seen in previous examples. We are effectively able to define the ordering of the
concatenation by specifying the ```name```,  `as` and `fields` parameters.
 
In this example, we have set the name for each to `:original`, specifying that the input
at index `i` should be the input file defined at index  `i`.
 
It is equally important to specify the `as` parameter. This simple parameter tells the assembly
the ordering.
 
Finally, we have the `fields` parameter. Files that get uploaded via the Ruby SDK get sent to Transloadit
through an HTTP Rest client as a multipart/form-data request. This means that each field needs a name. The Ruby SDK
automatically adds the name `file_<index>` to the outgoing request, where `<index>` is the number specified
by its position in the array. 

This is why it is important to define the ordering in the `steps` array, as there is no guarantee that items
will finish uploading in the order they are sent.

With that step complete, we can finalize our store step (which is optionally added if the s3 credentials are set) and submit the assembly.

```ruby
begin
  store = transloadit_client.step('store', '/s3/store', {
    key: ENV.fetch('S3_ACCESS_KEY'),
    secret: ENV.fetch('S3_SECRET_KEY'),
    bucket: ENV.fetch('S3_BUCKET'),
    bucket_region: ENV.fetch('S3_REGION'),
    use: ['concat']
  })

  steps.push(store)
rescue KeyError => e
  p 's3 config not set. Skipping s3 storage...'
end

assembly = transloadit_client.assembly(steps: steps)
assembly.create! *open_files(files)
```

Note the final call to `create` and usage of the splat (`*`) operator. The `create!` method expects
one or more arguments. If you would like to pass an array to this method, you must unpack the contents of the array
or the method will treat the argument passed in as a single object, and you may have unexpected results in your 
final results.

### Conclusion

With the above examples, we have seen how we can utilize the Transloadit Ruby SDK to perform simple image optimization,
mp3 encoding and metadata writing, and audio concatenation features provided by the Transloadit service. Please visit
https://transloadit.com/docs for the full Transloadit API documentation.
