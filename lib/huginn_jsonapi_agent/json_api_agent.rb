module Agents

  class JsonApiAgent < Agent

    include WebRequestConcern

    can_dry_run!
    no_bulk_receive!
    default_schedule "never"

    description do
      <<-MD
        Agent communicates with api.

        `url` – api url

        `method` – must be 'post', 'get', 'put', 'delete', or 'patch'

        `payload` – [Liquid-interpolated](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) data will be send to carprice-api.

        `emit_events` – emit result as event

        `merge_event` – merge result with incoming event

        `extract` – sub-hashes specify [JSONPaths](http://goessner.net/articles/JsonPath/) to the values that you care about.
         Option can be skipped, causing the full JSON response to be returned.

      MD
    end

    event_description <<-MD
      Events look like this:
        {
          "id": 12345,
          "field_1": "field_1 value",
          "field_2": "field_2 value"
        }
    MD

    def default_options
      {
          'url' => 'https://service_name/api/',
          'method' => 'post',
          'payload' => {
              'key' => 'value',
              'something' => 'the event contained {{ somekey }}'
          },
          'extract' => {
              'field_1' => {'path' => 'items.[*].field_1'},
              'field_2' => {'path' => 'items.[*].field_2'}
          },
          'headers' => {},
          'emit_events' => 'true',
          'merge_event' => 'true'
      }
    end

    def working?
      !recent_error_logs?
    end

    def method
      (interpolated['method'].presence || 'post').to_s.downcase
    end

    def validate_options
      unless options['url'].present?
        errors.add(:base, "url are required fields")
      end

      if options['merge_event'].present? && !%[true false].include?(options['merge_event'].to_s)
        errors.add(:base, "if provided, merge_event must be 'true' or 'false'")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      unless %w[post get put delete patch].include?(method)
        errors.add(:base, "method must be 'post', 'get', 'put', 'delete', or 'patch'")
      end

      unless headers.is_a?(Hash)
        errors.add(:base, "if provided, headers must be a hash")
      end

      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          outgoing = interpolated['payload'].presence || {}
          handle outgoing, event, headers(interpolated[:headers])
        end
      end
    end

    def check
      handle interpolated['payload'].presence || {}, headers
    end

    private

    def handle(data, event = Event.new, headers)
      url = interpolated(event.payload)[:url]

      case method
      when 'get', 'delete'
        params, body = data, nil
      when 'post', 'put', 'patch'
        params = nil
        headers['Content-Type'] = 'application/json; charset=utf-8'
        body = data.to_json

      else
        error "Invalid method '#{method}'"
      end

      begin
        response = faraday.run_request(method.to_sym, url, body, headers) { |request|
          request.params.update(params) if params
        }
      rescue => error
        log("faraday.run_request err #{error.inspect}")
      end

      if response and boolify(interpolated['emit_events'])
        output = extract_json(JSON.parse(response.body.presence || '{}'))
        num_unique_lengths = interpolated['extract'].keys.map { |name| output[name].length }.uniq

        if num_unique_lengths.length != 1
          raise "Got an uneven number of matches for #{interpolated['name']}: #{interpolated['extract'].inspect}"
        end

        num_unique_lengths.first.times do |index|
          result = {}
          interpolated['extract'].keys.each do |name|
            result[name] = output[name][index]
          end

          # merge event payload
          result.deep_merge!(event.payload) if boolify(interpolated['merge_event']) and event.payload.is_a?(Hash)

          create_event payload: result

        end

      end
    end

    def extract_each(&block)
      interpolated['extract'].each_with_object({}) { |(name, extraction_details), output|
        output[name] = block.call(extraction_details)
      }
    end

    def extract_json(doc)
      extract_each { |extraction_details|
        result = Utils.values_at(doc, extraction_details['path'])
        log "Extracting at #{extraction_details['path']}: #{result}"
        result
      }
    end

  end
end
