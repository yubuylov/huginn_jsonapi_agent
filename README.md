# JsonApiAgent

Huginn's agent for run json api.

## Installation

Add `huginn_jsonapi_agent` to your Huginn's `ADDITIONAL_GEMS` configuration:

[Docker installation](https://github.com/huginn/huginn/tree/master/docker):
```yaml
# docker env
environment:
  ADDITIONAL_GEMS: 'huginn_jsonapi_agent(git: https://github.com/yubuylov/huginn_jsonapi_agent.git)'
```

[Local installation](https://github.com/huginn/huginn#local-installation):
```ruby 
# .env (Local huginn installation)
ADDITIONAL_GEMS=huginn_jsonapi_agent(github: yubuylov/huginn_jsonapi_agent)
```

## Usage
Configure agent
```json
{
  "post_url": "https://service_name/api/get_messages",
  "method": "post",
  "payload": {
    "user_id": "{{user_id}}"
  },
  "extract": {
    "message_id": {
      "path": "items.[*].message_id"
    },
    "text": {
      "path": "items.[*].text"
    }
  },
  "emit_events": "true",
  "no_merge": "false"
}
```

Will be emitted some events:
```json
    {
      "message_id": 12345,
      "text": "message text"
    }
```

## Development

Running `rake` will clone and set up Huginn in `spec/huginn` to run the specs of the Gem in Huginn as if they would be build-in Agents. The desired Huginn repository and branch can be modified in the `Rakefile`:

```ruby
HuginnAgent.load_tasks(branch: '<your branch>', remote: 'https://github.com/<github user>/huginn.git')
```

Make sure to delete the `spec/huginn` directory and re-run `rake` after changing the `remote` to update the Huginn source code.

After the setup is done `rake spec` will only run the tests, without cloning the Huginn source again.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/huginn_jsonapi_agent/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
