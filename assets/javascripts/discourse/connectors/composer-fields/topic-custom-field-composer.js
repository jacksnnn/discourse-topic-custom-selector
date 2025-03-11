import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { alias } from "@ember/object/computed";

export default class TopicCustomFieldComposer extends Component {
  @service siteSettings;
  @service fabubloxApi;
  @alias("siteSettings.topic_custom_field_name") fieldName;
  @alias("args.outletArgs.model") composerModel;
  @alias("composerModel.topic") topic;
  @alias("composerModel.replyingToTopic") reply;
  @alias("composerModel.canEditTitle") canEditTitle;
  @alias("composerModel.isNew") isNew;
  @alias("composerModel.action") currentAction;
  @alias("composerModel.editingFirstPost") editingFirstPost;
  @alias("composerModel.editingPost") editingPost;


  constructor() {
    super(...arguments);
    const isEditingFirstPost = this.currentAction === "edit" && this.editingFirstPost;
    const isNewTopicPost = this.isNew && !this.reply;
    if ((isNewTopicPost || isEditingFirstPost) && this.topic && this.topic[this.fieldName]) {
      // If the composer doesn't already have the field set, set it:
      if (!this.composerModel[this.fieldName]) {
        this.composerModel.set(this.fieldName, this.topic[this.fieldName]);
        this.fieldValue = this.topic[this.fieldName];
      }
    }
  }

  isValidProcessId(str) {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/?$/i;
    return uuidRegex.test(str);
  }

  @action
  onChangeField(processId) {
    if (!processId) {
      this.composerModel.set(this.fieldName, null);
      this.fieldValue = null;
      return;
    }
    
    // Store just the process ID, not the full URL
    if (this.isValidProcessId(processId)) {
      this.fieldValue = processId;
      this.composerModel.set(this.fieldName, processId);
    } else {
      // If it's a URL, extract the process ID
      const parts = processId.split("/");
      const lastPart = parts[parts.length - 1];
      
      if (this.isValidProcessId(lastPart)) {
        this.fieldValue = lastPart;
        this.composerModel.set(this.fieldName, lastPart);
      } else {
        // Invalid input
        this.composerModel.set(this.fieldName, null);
        this.fieldValue = null;
      }
    }
  }
}