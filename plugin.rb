# frozen_string_literal: true

# name: discourse-topic-custom-fields
# about: Discourse plugin showing how to add custom fields to Discourse topics
# version: 1.0
# authors: Angus McLeod
# contact email: angus@pavilion.tech
# url: https://github.com/pavilionedu/discourse-topic-custom-fields

# This sets the plugin name in the admin interface 
# & registers the plugin's stylesheet from /assets/stylesheets/common.scss
enabled_site_setting :topic_custom_field_enabled
register_asset "stylesheets/common.scss"

##
# type:        introduction
# title:       Add a custom field to a topic
# description: To get started, load the [discourse-topic-custom-fields](https://github.com/pavilionedu/discourse-topic-custom-fields)
#              plugin in your local development environment. Once you've got it
#              working, follow the steps below and in the client "initializer"
#              to understand how it works. For more about the context behind
#              each step, follow the links in the 'references' section.
##

# Executes after the discourse application is initialized
after_initialize do 
  # Defines a module for the custom field
  module ::TopicCustomFields 
    # Defines the custom field name & type for admins to set in the admin interface
    FIELD_NAME = SiteSetting.topic_custom_field_name
    FIELD_TYPE = SiteSetting.topic_custom_field_type
  end

  ##
  # type:        step
  # number:      1
  # title:       Register the field
  # description: Where we tell discourse what kind of field we're adding. You
  #              can register a string, integer, boolean or json field.
  # references:  lib/plugins/instance.rb,
  #              app/models/concerns/has_custom_fields.rb
  ##
  register_topic_custom_field_type(
    # Registers the custom field name & type fom 
    TopicCustomFields::FIELD_NAME,
    TopicCustomFields::FIELD_TYPE.to_sym,
  )

  ##
  # type:        step
  # number:      2
  # title:       Add getter and setter methods
  # description: Adding getter and setter methods is optional, but advisable.
  #              It means you can handle data validation or normalisation, and
  #              it lets you easily change where you're storing the data.
  ##

  ##
  # type:        step
  # number:      2.1
  # title:       Getter method
  # references:  lib/plugins/instance.rb,
  #              app/models/topic.rb,
  #              app/models/concerns/has_custom_fields.rb
  ##
  add_to_class(:topic, TopicCustomFields::FIELD_NAME.to_sym) do
    # Dynamically defines a getter method for the custom field
    # Returns the custom field value if it exists (not nil3), otherwise returns nil
    if !custom_fields[TopicCustomFields::FIELD_NAME].nil?
      custom_fields[TopicCustomFields::FIELD_NAME]
    else
      nil
    end
  end

  ##
  # type:        step
  # number:      2.2
  # title:       Setter method
  # references:  lib/plugins/instance.rb,
  #              app/models/topic.rb,
  #              app/models/concerns/has_custom_fields.rb
  ##
  add_to_class(:topic, "#{TopicCustomFields::FIELD_NAME}=") do |value|
  # Stores the custom field value in the custom_fields hash
    custom_fields[TopicCustomFields::FIELD_NAME] = value
  end

  ##
  # type:        step
  # number:      3
  # title:       Update the field when the topic is created or updated
  # description: Topic creation is contingent on post creation. This means that
  #              many of the topic update classes are associated with the post
  #              update classes.
  ##

  ##
  # type:        step
  # number:      3.1
  # title:       Update on topic creation
  # description: Here we're using an event callback to update the field after
  #              the first post in the topic, and the topic itself, is created.
  # references:  lib/plugins/instance.rb,
  #              lib/post_creator.rb
  ##
  on(:topic_created) do |topic, opts, user| # event listner for topic creation
    topic.send(
      # Calls the setter method, passing the initial custom field value from opts
      "#{TopicCustomFields::FIELD_NAME}=".to_sym, #
      opts[TopicCustomFields::FIELD_NAME.to_sym],
    )
    topic.save!
  end

  ##
  # type:        step
  # number:      3.2
  # title:       Update on topic edit
  # description: Update the field when it's updated in the composer when
  #              editing the first post in the topic, or in the topic title
  #              edit view.
  # references:  lib/plugins/instance.rb,
  #              lib/post_revisor.rb
  ##
  PostRevisor.track_topic_field(TopicCustomFields::FIELD_NAME.to_sym) do |tc, value|
    # Monitors changes to the custom field when the topic is edited
    tc.record_change( # Logs the field's original and new values
      TopicCustomFields::FIELD_NAME,
      tc.topic.send(TopicCustomFields::FIELD_NAME),
      value,
    )
    # Calls the setter method, passing the new custom field value
    tc.topic.send("#{TopicCustomFields::FIELD_NAME}=".to_sym, value.present? ? value : nil)
  end

  ##
  # type:        step
  # number:      4
  # title:       Serialize the field
  # description: Send our field to the client, along with the other topic
  #              fields.
  ##

  ##
  # type:        step
  # number:      4.1
  # title:       Serialize to the topic
  # description: Send your field to the topic.
  # references:  lib/plugins/instance.rb,
  #              app/serializers/topic_view_serializer.rb
  ##
  add_to_serializer(:topic_view, TopicCustomFields::FIELD_NAME.to_sym) do
    object.topic.send(TopicCustomFields::FIELD_NAME)
  end

  ##
  # type:        step
  # number:      4.2
  # title:       Preload the field
  # description: Discourse preloads custom fields on listable models (i.e.
  #              categories or topics) before serializing them. This is to
  #              avoid running a potentially large number of SQL queries
  #              ("N+1 Queries") at the point of serialization, which would
  #              cause performance to be affected.
  # references:  lib/plugins/instance.rb,
  #              app/models/topic_list.rb,
  #              app/models/concerns/has_custom_fields.rb
  ##
  add_preloaded_topic_list_custom_field(TopicCustomFields::FIELD_NAME)

  ##
  # type:        step
  # number:      4.3
  # title:       Serialize to the topic list
  # description: Send your preloaded field to the topic list.
  # references:  lib/plugins/instance.rb,
  #              app/serializers/topic_list_item_serializer.rb
  ##
  add_to_serializer(:topic_list_item, TopicCustomFields::FIELD_NAME.to_sym) do
    object.send(TopicCustomFields::FIELD_NAME)
  end
  
  # Add the auth0_id to the current user serializer
  add_to_serializer(:current_user, :auth0_id) do
    object.custom_fields["auth0_id"]
  end
  
  # Add API endpoints for Fabublox integration
  require 'net/http'
  require 'uri'
  require 'json'
  
  # Define a module for the Fabublox API
  module ::FabubloxApi
    def self.api_base_url
      SiteSetting.fabublox_api_base_url.chomp('/')
    end
    
    # def self.owned_process(jwt_token)
    #   uri = URI.parse("#{api_base_url}/api/processes/owned")
    #   http = Net::HTTP.new(uri.host, uri.port)
    #   http.use_ssl = uri.scheme == 'https'
      
    #   request = Net::HTTP::Get.new(uri.request_uri)
    #   request["Content-Type"] = "application/json"
    #   request["Authorization"] = "Bearer #{jwt_token}"
    #   response = http.request(request)
      
    #   if response.code.to_i == 200
    #     JSON.parse(response.body)
    #   else
    #     nil
    #   end
    # end

    # def self.fetch_user_processes(jwt_token)
    #   uri = URI.parse("#{api_base_url}/api/processes/user/#{jwt_token}")
    #   http = Net::HTTP.new(uri.host, uri.port)
    #   http.use_ssl = uri.scheme == 'https'
      
    #   request = Net::HTTP::Get.new(uri.request_uri)
    #   request["Authorization"] = "Bearer #{jwt_token}"
    #   request["Content-Type"] = "application/json"
    #   response = http.request(request)
      
    #   if response.code.to_i == 200
    #     JSON.parse(response.body)
    #   else
    #     []
    #   end
    # end
    
    # def self.fetch_process(process_id)
    #   uri = URI.parse("#{api_base_url}/api/processes/read/#{process_id}")
    #   http = Net::HTTP.new(uri.host, uri.port)
    #   http.use_ssl = uri.scheme == 'https'
      
    #   request = Net::HTTP::Get.new(uri.request_uri)
    #   request["Content-Type"] = "application/json"
    #   request["Authorization"] = "Bearer #{jwt_token}"
    #   response = http.request(request)
      
    #   if response.code.to_i == 200
    #     JSON.parse(response.body)
    #   else
    #     nil
    #   end
    # end
    
    # Updated method to fetch process SVG
    def self.fetch_process_svg(process_id, token = nil)
      Rails.logger.info("Fetching SVG for process ID: #{process_id}")
      
      if !process_id
        Rails.logger.warn("No process ID provided to fetch_process_svg")
        return nil
      end
      
      # Parse the token if provided and in JSON format
      if token
        begin
          if token.start_with?('{') && token.include?('"access_token"')
            parsed_token = JSON.parse(token)
            if parsed_token && parsed_token["access_token"]
              Rails.logger.info("Found token in JSON format in fetch_process_svg, extracting access_token value")
              token = parsed_token["access_token"]
            end
          end
        rescue JSON::ParserError => e
          Rails.logger.warn("Failed to parse token as JSON in fetch_process_svg, will use as-is: #{e.message}")
        end
      end
      
      uri = URI.parse("#{api_base_url}/api/processes/#{process_id}/svg")
      Rails.logger.info("Full URI for SVG request: #{uri}")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 10
      http.read_timeout = 20
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "*/*"
      request["User-Agent"] = "Discourse/FabubloxPlugin"
      
      # Add authorization if token provided
      if token
        request["Authorization"] = "Bearer #{token}"
        Rails.logger.info("Added authorization header to SVG request")
      end
      
      Rails.logger.info("Sending request to: #{uri}")
      
      begin
        response = http.request(request)
        
        if response.code.to_i == 200
          content_type = response["Content-Type"]
          Rails.logger.info("Successfully fetched SVG, content length: #{response.body.length}, Content-Type: #{content_type}")
          response.body
        else
          Rails.logger.warn("Failed to fetch SVG, response code: #{response.code}")
          Rails.logger.warn("Response body: #{response.body[0..200]}")
          nil
        end
      rescue => e
        Rails.logger.error("Error in fetch_process_svg: #{e.class.name} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        nil
      end
    end
    
    # Method to fetch data with Auth0 token
    def self.fetch_with_auth_token(endpoint, token = nil, params = {})
      Rails.logger.info("Fetching with auth token: #{endpoint}")
      
      # Make sure the endpoint doesn't start with a slash
      endpoint = endpoint.sub(/^[\/]/, '')
      
      uri = URI.parse("#{api_base_url}/#{endpoint}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      
      # Add Auth0 token if available
      if token
        request["Authorization"] = "Bearer #{token}"
        Rails.logger.info("Added Authorization header with token: Bearer [REDACTED]")
      else
        Rails.logger.warn("No token provided for authenticated request")
      end
      
      # Add any additional parameters
      params.each do |key, value|
        request[key] = value
      end
      
      if params.any?
        Rails.logger.info("Additional request params: #{params.inspect}")
      end
      
      Rails.logger.info("Sending GET request to: #{uri}")
      Rails.logger.info("Request headers: #{request.to_hash.inspect}")
      
      begin
        response = http.request(request)
        
        Rails.logger.info("Received response: code #{response.code}")
        
        if response.code.to_i == 200
          result = JSON.parse(response.body)
          Rails.logger.info("Successfully parsed response, body length: #{response.body.length}")
          result
        else
          Rails.logger.warn("API request failed: #{response.code} - #{response.body[0..200]}")
          nil
        end
      rescue => e
        Rails.logger.error("Error in fetch_with_auth_token: #{e.message}\n#{e.backtrace.join("\n")}")
        nil
      end
    end
    
    # Enhanced method to fetch owned processes with retry logic
    def self.fetch_owned_processes(jwt_token)
      Rails.logger.info("Fetching owned processes with token: #{jwt_token ? '[REDACTED]' : 'nil'}")
      
      if !jwt_token || jwt_token.strip.empty?
        Rails.logger.error("No JWT token provided for fetch_owned_processes")
        return []
      end
      
      # Parse the token if it's in JSON format
      # This handles the case where the token is stored as {"access_token":"actual_token_value"}
      begin
        if jwt_token.start_with?('{') && jwt_token.include?('"access_token"')
          parsed_token = JSON.parse(jwt_token)
          if parsed_token && parsed_token["access_token"]
            Rails.logger.info("Found token in JSON format, extracting access_token value")
            jwt_token = parsed_token["access_token"]
          else
            Rails.logger.error("Token appears to be JSON but does not contain access_token field")
          end
        end
      rescue JSON::ParserError => e
        Rails.logger.warn("Failed to parse token as JSON, will use as-is: #{e.message}")
        # Continue with the token as-is
      end
      
      Rails.logger.info("Using token format: #{jwt_token.start_with?('eyJ') ? 'starts with eyJ (looks like JWT)' : 'does not look like standard JWT'}")
      
      max_retries = 2
      retries = 0
      
      while retries <= max_retries
        begin
          uri = URI.parse("#{api_base_url}/api/processes/owned")
          Rails.logger.info("Full URI for API request: #{uri}")
          
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.open_timeout = 15  # Increased timeout
          http.read_timeout = 30
          
          request = Net::HTTP::Get.new(uri.request_uri)
          request["Authorization"] = "Bearer #{jwt_token}"
          request["Content-Type"] = "application/json"
          request["Accept"] = "application/json"
          request["User-Agent"] = "Discourse/FabubloxPlugin"
          
          # Log a sanitized version of the token for debugging
          token_preview = jwt_token ? "#{jwt_token[0..10]}...#{jwt_token[-10..-1]}" : "nil"
          Rails.logger.info("Using token (preview): #{token_preview}")
          Rails.logger.info("Sending GET request to: #{uri}, attempt #{retries + 1} of #{max_retries + 1}")
          
          response = http.request(request)
          Rails.logger.info("Received response: code #{response.code}")
          
          # Log the full response for debugging (limit to first 1000 chars to avoid overflowing logs)
          Rails.logger.info("Response headers: #{response.to_hash.inspect}")
          Rails.logger.info("Response body (truncated): #{response.body ? response.body[0..1000] : 'nil'}")
          
          case response.code.to_i
          when 200
            begin
              result = JSON.parse(response.body)
              Rails.logger.info("Successfully parsed JSON response")
              
              # Return the processes based on the response structure
              if result.is_a?(Array)
                Rails.logger.info("Response is an array with #{result.length} processes")
                return result
              elsif result.is_a?(Hash)
                if result["processes"].is_a?(Array)
                  Rails.logger.info("Found processes array inside result hash with #{result["processes"].length} processes")
                  return result["processes"]
                elsif result["data"].is_a?(Array)
                  Rails.logger.info("Found data array inside result hash with #{result["data"].length} processes")
                  return result["data"]
                elsif result["items"].is_a?(Array)
                  Rails.logger.info("Found items array inside result hash with #{result["items"].length} processes")
                  return result["items"]
                else
                  Rails.logger.warn("Response is a hash but doesn't contain expected process arrays. Keys: #{result.keys.join(', ')}")
                  return []
                end
              else
                Rails.logger.warn("Unexpected response type: #{result.class.name}")
                return []
              end
            rescue JSON::ParserError => e
              Rails.logger.error("JSON parsing error: #{e.message}")
              Rails.logger.error("Response that failed to parse: #{response.body ? response.body[0..500] : 'nil'}")
              return []
            end
          when 401, 403
            Rails.logger.error("Authentication error: #{response.code} - Token may be invalid or expired")
            return []
          when 500..599
            Rails.logger.error("Server error #{response.code}: #{response.body ? response.body[0..500] : 'nil'}")
            
            # Increment retry counter for server errors
            if retries < max_retries
              retries += 1
              Rails.logger.info("Will retry request (#{retries}/#{max_retries})...")
              sleep(1 * retries) # Exponential backoff
              break # Exit the current begin-rescue but stay in the while loop
            else
              Rails.logger.error("Max retries reached. Giving up.")
              return []
            end
          else
            Rails.logger.error("Unexpected response code: #{response.code}")
            return []
          end
          
          # If we reach here without breaking or returning, we succeeded
          break
          
        rescue => e
          Rails.logger.error("Exception in fetch_owned_processes: #{e.class.name} - #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          
          # Increment retry counter for exceptions
          if retries < max_retries
            retries += 1
            Rails.logger.info("Will retry after error (#{retries}/#{max_retries})...")
            sleep(1 * retries)
          else
            Rails.logger.error("Max retries reached after error. Giving up.")
            return []
          end
        end
      end
      
      # If we've reached here without returning, return an empty array
      []
    end
  end
  
  # Register API endpoints
  Discourse::Application.routes.append do
    get "/fabublox/user_processes/:auth0_id" => "fabublox_api#user_processes", constraints: { auth0_id: /.*/ }
    get "/fabublox/process/:process_id" => "fabublox_api#get_process"
    get "/fabublox/process_svg/:process_id" => "fabublox_api#process_svg"
    get "/fabublox/current_user_token" => "fabublox_api#current_user_token"
    post "/fabublox/authenticated_request" => "fabublox_api#authenticated_request"
    get "/api/processes/owned" => "fabublox_api#owned_processes"
    get "/fabublox/debug_token" => "fabublox_api#debug_token"
  end
  
  # Create a controller for the Fabublox API
  class ::FabubloxApiController < ::ApplicationController
    requires_plugin 'discourse-topic-custom-fields'
    
    skip_before_action :check_xhr, only: [:user_processes, :get_process, :process_svg, :current_user_token, :authenticated_request, :owned_processes]
    
    def user_processes
      auth0_id = params[:auth0_id]
      render json: FabubloxApi.fetch_user_processes(auth0_id)
    end
    
    def get_process
      process_id = params[:process_id]
      render json: FabubloxApi.fetch_process(process_id)
    end
    
    def process_svg
      process_id = params[:process_id]
      Rails.logger.info("FabubloxApiController#process_svg called for process ID: #{process_id}")
      
      if !process_id
        Rails.logger.warn("No process ID provided")
        render json: { error: "Process ID is required" }, status: 400
        return
      end
      
      svg_content = FabubloxApi.fetch_process_svg(process_id)
      
      if svg_content
        Rails.logger.info("SVG content retrieved, length: #{svg_content.length}")
        
        # Check if it's JSON or raw SVG
        begin
          # Try to parse as JSON first
          json_content = JSON.parse(svg_content)
          # If we get here, it's valid JSON, so return it
          render json: json_content
        rescue JSON::ParserError
          # Not JSON, likely raw SVG content
          Rails.logger.info("Content is not JSON, returning as raw SVG")
          render plain: svg_content, content_type: "image/svg+xml"
        end
      else
        Rails.logger.warn("No SVG content found for process ID: #{process_id}")
        render json: { error: "Could not retrieve SVG content" }, status: 404
      end
    end
    
    # New endpoint to get the current user's Auth0 token
    def current_user_token
      raise Discourse::NotLoggedIn.new unless current_user
      
      token = current_user.custom_fields['current_access_token']
      
      # Try to parse the token if it's in JSON format
      if token
        begin
          if token.start_with?('{') && token.include?('"access_token"')
            parsed_token = JSON.parse(token)
            if parsed_token && parsed_token["access_token"]
              Rails.logger.info("Found token in JSON format, extracting access_token value")
              token = parsed_token["access_token"]
            end
          end
        rescue JSON::ParserError
          # Continue with the token as-is
        end
      end
      
      if token
        render json: { success: true, token: token }
      else
        render json: { success: false, error: "No Auth0 token found for user" }, status: 404
      end
    end
    
    # New endpoint to make authenticated API requests
    def authenticated_request
      raise Discourse::NotLoggedIn.new unless current_user
      
      token = current_user.custom_fields['current_access_token']
      endpoint = params[:endpoint]
      
      Rails.logger.info("Authenticated request for endpoint: #{endpoint}")
      
      if token && endpoint
        begin
          result = FabubloxApi.fetch_with_auth_token(endpoint, token)
          render json: result || { success: false, error: "API request failed" }
        rescue => e
          Rails.logger.error("Error in authenticated_request: #{e.message}\n#{e.backtrace.join("\n")}")
          render json: { success: false, error: e.message }, status: 500
        end
      else
        Rails.logger.warn("Missing token or endpoint. Token present: #{token.present?}, Endpoint: #{endpoint}")
        render json: { success: false, error: "Missing token or endpoint" }, status: 400
      end
    end

    # New endpoint to fetch processes owned by the user
    def owned_processes
      Rails.logger.info("FabubloxApiController#owned_processes called")
      
      # Ensure user is logged in
      raise Discourse::NotLoggedIn.new unless current_user
      Rails.logger.info("User is logged in: #{current_user.username}")
      
      # Get the token from user custom fields
      token = current_user.custom_fields['current_access_token']
      Rails.logger.info("Token exists: #{token.present?}")
      
      if token
        # Call the API method to fetch processes
        begin
          processes = FabubloxApi.fetch_owned_processes(token)
          Rails.logger.info("Processes retrieved: #{processes ? processes.length : 0}")
          
          # Return the processes array directly without wrapping it
          # The JavaScript expects this to be an array, not an object
          render json: processes
        rescue => e
          Rails.logger.error("Exception in owned_processes controller: #{e.class.name} - #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          render json: { error: e.message }, status: 500
        end
      else
        Rails.logger.warn("No token found for user #{current_user.username}")
        render json: { success: false, error: "No Auth0 token found for user" }, status: 404
      end
    end

    # Diagnostic endpoint to help debug token issues
    def debug_token
      raise Discourse::NotLoggedIn.new unless current_user
      
      raw_token = current_user.custom_fields['current_access_token']
      
      debug_info = {
        raw_token_present: raw_token.present?,
        raw_token_type: raw_token.class.name,
        raw_token_length: raw_token ? raw_token.length : 0,
        raw_token_preview: raw_token ? "#{raw_token[0..20]}...#{raw_token[-20..-1]}" : nil,
        appears_to_be_json: raw_token ? (raw_token.start_with?('{') && raw_token.end_with?('}')) : false,
        appears_to_have_access_token: raw_token ? raw_token.include?('access_token') : false
      }
      
      # Try to parse the token
      parsed_token = nil
      
      if raw_token && raw_token.start_with?('{')
        begin
          parsed_token = JSON.parse(raw_token)
          debug_info[:parsed_successfully] = true
          debug_info[:parsed_token_keys] = parsed_token.keys
          
          if parsed_token["access_token"]
            debug_info[:extracted_token_preview] = "#{parsed_token["access_token"][0..20]}...#{parsed_token["access_token"][-20..-1]}"
            debug_info[:extracted_token_length] = parsed_token["access_token"].length
          end
        rescue JSON::ParserError => e
          debug_info[:parsed_successfully] = false
          debug_info[:parse_error] = e.message
        end
      else
        debug_info[:parsed_successfully] = false
        debug_info[:parse_error] = "Token doesn't appear to be JSON"
      end
      
      # Provide guidance
      if debug_info[:parsed_successfully] && debug_info[:parsed_token_keys].include?("access_token")
        debug_info[:diagnosis] = "The token is stored as a JSON object. The actual token is inside the 'access_token' field."
        debug_info[:solution] = "Use the extract_token modifications you've added to fix this."
      elsif raw_token && raw_token.start_with?('eyJ')
        debug_info[:diagnosis] = "The token appears to be stored in the correct format (JWT token)."
        debug_info[:solution] = "This is good - the token is stored correctly."
      else
        debug_info[:diagnosis] = "The token format is unclear. It's neither a plain JWT token nor a parseable JSON object."
        debug_info[:solution] = "Check how the token is being generated and stored."
      end
      
      render json: debug_info
    end
  end
end
