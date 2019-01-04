# Atlassian Fisheye Agent

 Trigger Atlassian Fisheye to index a repository (for example, after new commits are pushed)
        
## Installation

This gem is run as part of the [Huginn](https://github.com/huginn/huginn) project. If you haven't already, follow the [Getting Started](https://github.com/huginn/huginn#getting-started) instructions there.

Add this string to your Huginn's .env `ADDITIONAL_GEMS` configuration:

```ruby
huginn_fisheye_agent
# when only using this agent gem it should look like this:
ADDITIONAL_GEMS=huginn_fisheye_agent
```

And then execute:

    $ bundle

## Usage

 `fisheye_url` is the address of the Fisheye Instance you want to trigger
  `fisheye_token` is the Rest API Token for the Fisheye Instance (Found under Admin->Security Settings->Authentication in Fisheye)
  `fisheye_repository` is the repository you want to trigger the index on
  If `merge_event` is true, then the response is merged with the original payload


## Development

Running `rake` will clone and set up Huginn in `spec/huginn` to run the specs of the Gem in Huginn as if they would be build-in Agents. The desired Huginn repository and branch can be modified in the `Rakefile`:

```ruby
HuginnAgent.load_tasks(branch: '<your branch>', remote: 'https://github.com/DevThenDo/huginn.git')
```

Make sure to delete the `spec/huginn` directory and re-run `rake` after changing the `remote` to update the Huginn source code.

After the setup is done `rake spec` will only run the tests, without cloning the Huginn source again.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/DevThenDo/huginn_fisheye_agent/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
