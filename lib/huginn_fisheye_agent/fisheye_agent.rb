require 'addressable/uri'

module Agents
  class FisheyeAgent < Agent
    include WebRequestConcern
    include FormConfigurable


    can_dry_run!
    no_bulk_receive!
    cannot_be_scheduled!
    
    description <<-MD
      Trigger Atlassian Fisheye to index a repository (for example, after new commits are pushed)
        
      `fisheye_url` is the address of the Fisheye Instance you want to trigger
    
      `fisheye_token` is the Rest API Token for the Fisheye Instance (Found under Admin->Security Settings->Authentication in Fisheye)
    
      `fisheye_repository` is the repository you want to trigger the index on
     
      If `merge_event` is true, then the response is merged with the original payload
    
      MD

    def default_options
      {
        'fisheye_url' => 'https://fisheye.example.com',
        'fisheye_token' => 'XXX',
        'fisheye_repository' => 'XXX-XXX',
        'merge_event' => 'false'
      }
    end

    form_configurable :fisheye_url, type: :text
    form_configurable :fisheye_token, type: :text
    form_configurable :fisheye_repository, type: :text
    form_configurable :merge_event, type: :boolean
 
    
    SCHEMES = %w(http https)
    
    def valid_url?(url)
      parsed = Addressable::URI.parse(url) or return false
      SCHEMES.include?(parsed.scheme)
      rescue Addressable::URI::InvalidURIError
        false
    end
    
    def validate_options
      if options['merge_event'].present? && !%[true false].include?(options['merge_event'].to_s)
        errors.add(:base, "Oh no!!! if provided, merge_event must be 'true' or 'false'")
      end
      errors.add(:base, "Fisheye URL Missing") unless options['fisheye_url'].present?
      errors.add(:base, "Fisheye Token Missing") unless options['fisheye_token'].present?
      errors.add(:base, "Fisheye Repository Missing") unless options['fisheye_repository'].present?
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
      response = faraday.run_request(:put, fisheye_url, fisheye_body, fisheye_headers)
      case response.status
        when 202
          log("Succesfully Trigger incremental index of Repository " + interpolated(event)["fisheye_repository"])
        when 204
          log("Succesfully Trigger incremental index of Repository " + interpolated(event)["fisheye_repository"])
        when 401
          log("Invalid Authentication Token Body: #{response.body}")
          return  
        when 404
          log("Repository Doesn't Exist: Repo: " + interpolated(event)["fisheye_repository"] + " Body: #{response.body}")
          return
        when 405 
          log("Repository is disabled: Repo: " + interpolated(event)["fisheye_repository"] + " Body: #{response.body}")
          return
        else
          log("Invalid Response from Fisheye: Status: #{response.status} Body: #{response.body}")
          return
      end
      if boolify(interpolated['merge_event'])
        create_event payload: event.payload.merge(
          fisheeye_response: {
            body: response.body,
            headers: response.headers,
            status: response.status
          }
        )
      else
      create_event payload: {fisheye_response: {body: response.body, headers: response.headers, status: response.status}}
      end
    end
  end
end
