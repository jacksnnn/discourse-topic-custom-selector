import Component from "@glimmer/component";
import { action } from "@ember/object";
import { alias } from "@ember/object/computed";
import { service } from "@ember/service";

/*
 * type:        step
 * number:      6
 * title:       Show an input in topic title edit
 * description: If your field can be edited by the topic creator or
 *              staff, you may want to let them do this in the topic
 *              title edit view.
 * references:  app/assets/javascripts/discourse/app/templates/topic.hbs
 */

export default class TopicCustomFieldEditTopic extends Component {
  @service siteSettings;
  @alias("siteSettings.topic_custom_field_name") fieldName;
  @alias("args.outletArgs.model") composerModel;
  @alias("composerModel.topic") topic;
  @alias("composerModel.replyingToTopic") reply;
  @alias("composerModel.canEditTitle") canEditTitle;
  @alias("composerModel.editingFirstPost") editingFirstPost;

  constructor() {
    super(...arguments);
    // Only set `fieldValue` if we know we are editing the first post
    if ( this.editingFirstPost && this.canEditTitle ) {
    this.fieldValue = this.args.outletArgs.model.get(this.fieldName);
  } else{
    // Don't set 'fieldValue' if we are not editing the first post
    this.fieldValue = null;
  }
}

  @action
  onChangeField(fieldValue) {
    // console.log("TopicModel:", this.topicModel);
    // console.log("Can Edit Title:", this.canEditTitle);
    // console.log("Editing First Post:", this.editingFirstPost);
    this.args.outletArgs.buffered.set(this.fieldName, fieldValue);
  }
}
