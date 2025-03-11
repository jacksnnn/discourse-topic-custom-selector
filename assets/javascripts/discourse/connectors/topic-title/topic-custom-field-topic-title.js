import Component from "@glimmer/component";
import { inject as controller } from "@ember/controller";
import { alias } from "@ember/object/computed";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { htmlSafe } from "@ember/template";

/*
 * type:        step
 * number:      8
 * title:       Display your field value in the topic
 * description: Display the value of your custom topic field below the
 *              title in the topic
 *              list.
 */

export default class TopicCustomFieldTopicTitle extends Component {
  @service siteSettings;
  @service fabubloxApi;
  @controller topic;
  @alias("siteSettings.topic_custom_field_name") fieldName;
  @tracked processSvg = null;
  @tracked processData = null;
  @tracked isLoading = false;

  constructor() {
    super(...arguments);
    this.loadProcessData();
  }

  get fieldValue() {
    return this.args.outletArgs.model.get(this.fieldName); 
  }

  isValidProcessId(str) {
    // UUID format validation regex
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/?$/i;
    return uuidRegex.test(str);
  }

  get processId() {
    if (!this.fieldValue) return null;

    // If it's already a valid process ID, use it directly
    if (this.isValidProcessId(this.fieldValue)) {
      return this.fieldValue;
    }

    // If it's a full URL, extract and validate the process ID
    const parts = this.fieldValue.split("/");
    const lastPart = parts[parts.length - 1];

    if (this.isValidProcessId(lastPart)) {
      return lastPart;
    }

    return null;
  }

  get fieldUrl() {
    const processId = this.processId;
    if (!processId) return null;
    
    return `https://www.fabublox.com/process-editor/${processId}`;
  }
  
  get processName() {
    return this.processData?.processName || "View Process";
  }
  
  get svgContent() {
    return this.processSvg ? htmlSafe(this.processSvg) : null;
  }
  
  async loadProcessData() {
    const processId = this.processId;
    if (!processId) return;
    
    this.isLoading = true;
    
    try {
      // Fetch process data
      const processData = await this.fabubloxApi.fetchProcessById(processId);
      this.processData = processData;
      
      // Fetch SVG preview
      const svg = await this.fabubloxApi.getProcessSvgPreview(processId);
      this.processSvg = svg;
    } catch (error) {
      console.error("Error loading process data:", error);
    } finally {
      this.isLoading = false;
    }
  }
}