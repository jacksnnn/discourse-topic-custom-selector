import Component from "@glimmer/component";
import { service } from "@ember/service";

export default class TopicListCustomField extends Component {
  @service siteSettings;

  get fieldName() {
    return this.siteSettings.topic_custom_field_name;
  }

  get fieldValue() {
    return this.args.topic?.[this.fieldName];
  }

  get showCustomField() {
    return !!this.fieldValue;
  }

  isValidProcessId(str) {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/?$/i;
    return uuidRegex.test(str);
  }

  get fieldUrl() {
    if (!this.fieldValue) return null;

    // If it's already a valid process ID, use it directly
    if (this.isValidProcessId(this.fieldValue)) {
      return `https://www.fabublox.com/process-editor/${this.fieldValue}`;
    }

    // If it's a full URL, extract and validate the process ID
    const parts = this.fieldValue.split("/");
    const lastPart = parts[parts.length - 1];

    if (this.isValidProcessId(lastPart)) {
      return `https://www.fabublox.com/process-editor/${lastPart}`;
    }

    return this.fieldValue; // Return the original value if it doesn't match expected patterns
  }

  <template>
    {{#if this.showCustomField}}
      <a href={{this.fieldUrl}} target="_blank" class="referenced-button">
        <svg xmlns="http://www.w3.org/2000/svg" id="svg5" 
        viewBox="0 0 346.76 286.46" class="referenced-icon">
          <defs>
            <style>
              .cls-1 {
                stroke: #606f7e;
              }
              .cls-1, .cls-2 {
                stroke-width: 22.68px;
              }
              .cls-1, .cls-2, .cls-3 {
                fill: none;
                stroke-linecap: round;
                stroke-linejoin: round;
              }
              .cls-2 {
                stroke: #000;
              }
              .cls-3 {
                stroke: #764d82;
                stroke-width: 22.68px;
              }
            </style>
          </defs>
          <g id="layer1">
            <path id="path6303" class="cls-2" d="M335.42,86.9L173.38,11.34,11.34,86.9l162.04,75.56,162.04-75.56Z"/>
            <path id="path6311" class="cls-1" d="M11.34,124.45l162.04,75.56,162.04-75.56"/>
            <path id="path6313" class="cls-3" d="M11.34,162.01l162.04,75.56,162.04-75.56"/>
            <path id="path6315" class="cls-2" d="M11.34,199.56l162.04,75.56,162.04-75.56"/>
          </g>
        </svg>
      </a>
    {{/if}}
  </template>
} 