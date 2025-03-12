import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class FabubloxApi extends Service {
  @service currentUser;
  @service siteSettings;

  get apiBaseUrl() {
    return this.siteSettings.fabublox_api_base_url;
  }

  // Get the Auth0 token for the current user
  async getAuth0Token() {
    this._logWarning("Attempting to get Auth0 token via refresh endpoint");
    try {
      // Instead of reading from the custom field, request a fresh token from the refresh endpoint.
      this._logWarning("Making AJAX request to /oauth2/refresh");

      const result = await ajax("/oauth2/refresh", {
        type: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        }
      });

      this._logWarning("Received response from /oauth2/refresh: " + JSON.stringify(result));

      // Extract the token value
      let token = null;
      
      if (result) {
        // Case 1: Result is already a string (the token itself)
        if (typeof result === "string") {
          token = result;
          this._logWarning("Received token as string directly");
        }
        // Case 2: Result is an object with access_token field (standard OAuth format)
        else if (result.access_token) {
          token = result.access_token;
          this._logWarning("Extracted access_token from response object");
        }
        // Case 3: Result is a string that looks like JSON (possibly double-encoded)
        else if (typeof result === "string" && result.startsWith("{") && result.includes("access_token")) {
          try {
            const parsedResult = JSON.parse(result);
            if (parsedResult.access_token) {
              token = parsedResult.access_token;
              this._logWarning("Extracted access_token from parsed JSON string");
            }
          } catch (e) {
            this._logWarning("Failed to parse response as JSON: " + e.message);
          }
        }
      }
      
      if (token) {
        this._logWarning("Successfully retrieved access token");
        return token;
      } else {
        this._logWarning("No access_token could be extracted from response: " + JSON.stringify(result));
        return null;
      }
    } catch (error) {
      this._logWarning("Error from /oauth2/refresh endpoint: " +
        JSON.stringify({
          status: error.status,
          statusText: error.statusText,
          message: error.message,
          responseText: error.responseText
        })
      );

      this._logError("Error fetching Auth0 token from refresh endpoint:", error);
      return null;
    }
  }

  // Make an authenticated API request
  async authenticatedRequest(endpoint, params = {}) {
    try {
      this._logWarning(`Making authenticated request to: ${endpoint}`);

      // Make sure the endpoint is properly formatted
      const formattedEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

      const data = {
        endpoint: formattedEndpoint,
        ...params
      };

      const result = await ajax("/fabublox/authenticated_request", {
        type: "POST",
        data
      });

      return result;
    } catch (error) {
      this._logError(`Error making authenticated request to ${endpoint}:`, error);
      popupAjaxError(error);
      return null;
    }
  }

  // Fetch processes owned by the current user
  async fetchOwnedProcesses() {
    try {
      if (!this.currentUser) {
        this._logWarning("No current user available for fetching owned processes");
        return [];
      }

      // Get the Auth0 token for authentication
      const token = await this.getAuth0Token();
      if (!token) {
        this._logWarning("No Auth0 token available for fetching owned processes");
        return [];
      }

      this._logWarning("Using server proxy to fetch owned processes");

      // OPTION 1: Use our pre-defined server endpoint
      try {
        const response = await ajax("/api/processes/owned", {
          type: "GET",
          timeout: 30000 // 30 second timeout
        });

        this._logWarning(`Received ${response ? (Array.isArray(response) ? response.length : 'non-array') : 0} processes from proxy endpoint`);
        
        // If it's an empty array, log it but still return it
        if (Array.isArray(response) && response.length === 0) {
          this._logWarning("Server returned an empty array of processes");
        }
        
        return response || [];
      } catch (proxyError) {
        // Enhanced error handling for the proxy endpoint
        this._logError("Error from owned processes endpoint:", proxyError);
        
        // If it's a 500 error, try to extract more information
        if (proxyError.status === 500) {
          this._logWarning("Received 500 Internal Server Error from the API");
          
          // Try to parse the error response if available
          try {
            if (proxyError.responseJSON) {
              this._logWarning(`Error response from API: ${JSON.stringify(proxyError.responseJSON)}`);
            } else if (proxyError.responseText) {
              this._logWarning(`Error response text: ${proxyError.responseText}`);
            }
          } catch (e) {
            this._logWarning("Could not parse error response");
          }
          
          // Return an error object instead of throwing
          return { error: "The server encountered an internal error (500). Please try again later." };
        }
        
        // For other error types
        return { error: proxyError.message || "Error fetching processes" };
      }
    } catch (error) {
      this._logError("Error in fetchOwnedProcesses:", error);
      return { error: error.message || "Unknown error occurred" };
    }
  }

  // Generate SVG preview for a process
  async getProcessSvgPreview(processId) {
    if (!processId) {
      this._logWarning("No process ID provided for SVG preview");
      return null;
    }

    try {
      this._logWarning(`Using server proxy to fetch SVG for process ID: ${processId}`);

      // Use our pre-defined server endpoint with timeout
      try {
        const response = await ajax(`/fabublox/process_svg/${processId}`, {
          type: "GET",
          timeout: 20000 // 20 second timeout
        });

        this._logWarning(`Received SVG data (length: ${response ? response.length : 0})`);
        return response;
      } catch (proxyError) {
        // Enhanced error handling
        this._logError(`Error from SVG proxy for process ${processId}:`, proxyError);
        
        // If it's a 500 error, provide more context
        if (proxyError.status === 500) {
          this._logWarning(`Received 500 Internal Server Error when fetching SVG for process ${processId}`);
          return null;
        }
        
        // For other errors
        return null;
      }
    } catch (error) {
      this._logError(`Error in getProcessSvgPreview for process ${processId}:`, error);
      return null;
    }
  }

  // Helper methods for logging
  _logError(message, error) {
    // eslint-disable-next-line no-console
    console.error(`[FabubloxApi] ${message}`, error);
  }

  _logWarning(message) {
    // eslint-disable-next-line no-console
    console.warn(`[FabubloxApi] ${message}`);
  }
}