import Component from "@glimmer/component";
import { Input, Textarea } from "@ember/component";
import { on } from "@ember/modifier";
import { readOnly } from "@ember/object/computed";
import { service } from "@ember/service";
import { eq } from "truth-helpers";
import ProcessSelector from "./process-selector";

export default class TopicCustomFieldInput extends Component {
  @service siteSettings;
  @readOnly("siteSettings.topic_custom_field_name") fieldName;
  @readOnly("siteSettings.topic_custom_field_type") fieldType;

  get isProcessField() {
    return this.fieldName === "price" ||
           this.fieldName === "process_id" ||
           this.fieldName === "processid" ||
           this.fieldName === "Process URL";
  }

  <template>
    {{#if (eq this.fieldType "boolean")}}
      <Input
        @type="checkbox"
        @checked={{@fieldValue}}
        {{on "change" (action @onChangeField value="target.checked")}}
      />
      <span>{{this.fieldName}}</span>
    {{/if}}

    {{#if (eq this.fieldType "integer")}}
      <Input
        @type="number"
        @value={{@fieldValue}}
        placeholder="Enter {{this.fieldName}}"
        class="topic-custom-field-input small"
        {{on "change" (action @onChangeField value="target.value")}}
      />
    {{/if}}

    {{#if (eq this.fieldType "string")}}
      {{#if this.isProcessField}}
        <ProcessSelector
          @fieldValue={{@fieldValue}}
          @onChangeField={{@onChangeField}}
        />
      {{else}}
        <Input
          @type="text"
          @value={{@fieldValue}}
          placeholder="Enter {{this.fieldName}}"
          class="topic-custom-field-input large"
          {{on "change" (action @onChangeField value="target.value")}}
        />
      {{/if}}
    {{/if}}

    {{#if (eq this.fieldType "json")}}
      <Textarea
        @value={{@fieldValue}}
        {{on "change" (action @onChangeField value="target.value")}}
        placeholder="Enter {{this.fieldName}}"
        class="topic-custom-field-textarea"
      />
    {{/if}}
  </template>
}
