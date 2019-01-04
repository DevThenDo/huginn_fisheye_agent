require 'addressable/uri'

module Agents
  class FisheyeAgent < Agent
    include WebRequestConcern

    can_dry_run!
    no_bulk_receive!
    default_schedule "never"
    
    description <<-MD
      Trigger Atlassian Fisheye to index a repository (for example, after new commits are pushed)
    MD

    def default_options
      {
        'fisheye_url' => 'https://fisheye.example.com',
        'fisheye_token' => 'XXX',
        'fisheye_repository' => 'XXX-XXX',
        'merge_event' => 'false'
      }
    end

    
    SCHEMES = %w(http https)
    
    def valid_url?(url)
      parsed = Addressable::URI.parse(url) or return false
      SCHEMES.include?(parsed.scheme)
    rescue Addressable::URI::InvalidURIError
      false
    end
    
    def validate_options
    end

    def working?
      return false if recent_error_logs?
      
      if interpolated['expected_receive_period_in_days'].present?
        return false unless last_receive_at && last_receive_at > interpolated['expected_receive_period_in_days'].to_i.days.ago
      end
    end

    def check
      receive(interpolated)
    end

    def receive(incoming_events)
      incoming_events.each do |event|  
        handle(event)
      end
    end
    def handle(event)
      fisheye_url = interpolated(event)["fisheye_url"] + '/rest-service-fecru/admin/repositories/'+ interpolated(event)["fisheye_repository"] + '/incremental-index'
      if not valid_url?(fisheye_url)
        log("Invalid URL #{fisheye_url}")
        return
      end
        
      fisheye_headers = {'Content-Type'  => 'application/json; charset=utf-8', 'X-Api-Key' => interpolated(event)["fisheye_token"] }
      fisheye_body = ''
      begin
        response = faraday.run_request(:put, fisheye_url, fisheye_body, fisheye_headers)
      rescue  => e
        warn pp e
      end
      log("Response" +  pp(response))
      if boolify(interpolated['merge_event'])
        create_event payload: event.payload.merge(
          body: response.body,
          headers: response.headers,
          status: response.status
        )
      end
    end
  end
end
