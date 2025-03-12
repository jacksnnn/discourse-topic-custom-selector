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

      if (result && result.access_token) {
        this._logWarning("Successfully retrieved access token");
        return result.access_token;
      } else {
        this._logWarning("No access_token in response: " + JSON.stringify(result));
        this._logWarning("No Auth0 token returned from the refresh endpoint");
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

      // Make a direct request to the API using the base URL
      const url = `${this.apiBaseUrl}/api/processes/owned`;
      const response = await ajax(url, {
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json"
        }
      });
      return response || [];
    } catch (error) {
      this._logError("Error fetching owned processes:", error);
      popupAjaxError(error);
      return [];
    }
  }

  // Generate SVG preview for a process
  async getProcessSvgPreview(processId) {
    if (!processId) {
      this._logWarning("No process ID provided for SVG preview");
      return null;
    }

    try {
      // Get the Auth0 token for authentication
      const token = await this.getAuth0Token();

      // Make a direct request to the API using the base URL
      const url = `${this.apiBaseUrl}/api/processes/${processId}/svg`;
      const response = await ajax(url, {
        headers: token ? {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json"
        } : {
          "Content-Type": "application/json"
        }
      });

      return response;
    } catch (error) {
      this._logError(`Error fetching SVG for process ${processId}:`, error);
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