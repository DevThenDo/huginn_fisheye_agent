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
      }
    end

    def validate_options
    end

    def working?
      return false if recent_error_logs?
      
      if interpolated['expected_receive_period_in_days'].present?
        return false unless last_receive_at && last_receive_at > interpolated['expected_receive_period_in_days'].to_i.days.ago
    end

#    def check
#    end

    def receive(incoming_events)
      fisheye_url = interpolated(event.payload)[:fisheye_url] + 'rest-service-fecru/admin/repositories/#{event.payload[:fisheye_repository]}/incremental-index'
      headers['Content-Type'] = 'application/json; charset=utf-8'
      end
      headers['X-Api-Key'] = event.payload[:api_key]
      body = ''
      response = faraday.run_request(method.to_sym, url, body, headers)
      

      if boolify(interpolated['emit_events'])
        new_event = interpolated['output_mode'].to_s == 'merge' ? event.payload.dup : {}
        create_event payload: new_event.merge(
          body: response.body,
          headers: normalize_response_headers(response.headers),
          status: response.status
        )
      end
    end
  end
end
