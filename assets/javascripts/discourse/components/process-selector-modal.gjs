import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { extractTokenFromAuth0 } from "../lib/auth";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";

export default class ProcessSelectorModal extends Component {
  @service siteSettings;
  @service currentUser;
  @service site;

  @tracked loading = true;
  @tracked error = null;
  @tracked iframeUrl = null;
  @tracked debugInfo = null;

  constructor() {
    super(...arguments);
    this.initializeSelector();
  }

  async initializeSelector() {
    try {
      // Get the Auth0 token
      let debugMessages = [];
      debugMessages.push("Attempting to get Auth0 token...");

      // If running in development mode, you can use a demo token for testing
      if (this.site.isDevMode) {
        debugMessages.push("Running in development mode, will try to use demo token.");
        if (!this.currentUser) {
          this.error = "User is not logged in. Please log in to select a process.";
          this.debugInfo = debugMessages.join("\n");
          this.loading = false;
          return;
        }

        // In dev mode, use a fake token if real one can't be retrieved
        try {
          const token = await extractTokenFromAuth0();
          if (token) {
            debugMessages.push("Successfully got token from Auth0");
            this.setupIframe(token, debugMessages);
          } else {
            debugMessages.push("Failed to get real token, using demo token for development");
            // Use a fake demo token in development
            const demoToken = `demo_${this.currentUser.username}_${Date.now()}`;
            this.setupIframe(demoToken, debugMessages);
          }
        } catch (e) {
          debugMessages.push(`Error extracting token: ${e.message}`);
          // Use a fake demo token in development
          const demoToken = `demo_${this.currentUser.username}_${Date.now()}`;
          this.setupIframe(demoToken, debugMessages);
        }
      } else {
        // Production mode: require a real token
        const token = await extractTokenFromAuth0();
        if (!token) {
          this.error = "Authentication failed. Please try again.";
          debugMessages.push("Failed to get Auth0 token");
          this.debugInfo = debugMessages.join("\n");
          this.loading = false;
          return;
        }

        debugMessages.push("Successfully got token from Auth0");
        this.setupIframe(token, debugMessages);
      }
    } catch (e) {
      this.error = "Failed to initialize the process selector. Please try again.";
      this.debugInfo = `Error: ${e.message}`;
      this.loading = false;
    }
  }

  setupIframe(token, debugMessages = []) {
    // Construct URL with token as a query parameter
    const baseUrl = "https://www.fabublox.com/process-selector";
    const url = new URL(baseUrl);
    url.searchParams.append("token", token);
    url.searchParams.append("origin", window.location.origin);

    debugMessages.push(`Setting up iframe with URL parameters`);
    this.debugInfo = debugMessages.join("\n");
    this.iframeUrl = url.toString();
    this.loading = false;
  }

  @action
  handleMessage(event) {
    // Validate the origin
    if (new URL(event.origin).hostname !== "www.fabublox.com") {
      return;
    }

    // Process the message
    if (event.data && event.data.type === "processSelected" && event.data.process) {
      if (this.args.model && this.args.model.onSelect) {
        // Pass the process data to the parent component
        this.args.model.onSelect({
          processUrl: event.data.process.url,
          svgContent: event.data.process.svgContent
        });
      }

      // Close the modal
      this.args.closeModal();
    }
  }

  <template>
    <DModal
      @title="Select a Process"
      @closeModal={{@closeModal}}
    >
      <:body>
        {{#if this.loading}}
          <div class="loading-spinner">
            <div class="spinner"></div>
            <p>Loading process selector...</p>
          </div>
        {{else if this.error}}
          <div class="error-message">
            <p>{{this.error}}</p>
            {{#if this.site.isDevMode}}
              <div class="debug-info">
                <details>
                  <summary>Debug Information</summary>
                  <pre>{{this.debugInfo}}</pre>
                </details>
              </div>
            {{/if}}
            <div class="retry-button">
              <DButton
                @action={{@closeModal}}
                @label="Close"
              />
            </div>
          </div>
        {{else}}
          <div class="iframe-container">
            <iframe
              src={{this.iframeUrl}}
              width="100%"
              height="100%"
              frameborder="0"
              {{on "load" (action (mut this.loading) false)}}
              {{on "message" this.handleMessage}}
            ></iframe>
          </div>
          {{#if this.site.isDevMode}}
            <div class="debug-info">
              <details>
                <summary>Debug Information</summary>
                <pre>{{this.debugInfo}}</pre>
              </details>
            </div>
          {{/if}}
        {{/if}}
      </:body>

      <:footer>
        <DButton
          @action={{@closeModal}}
          @label="Cancel"
        />
      </:footer>
    </DModal>
  </template>
}