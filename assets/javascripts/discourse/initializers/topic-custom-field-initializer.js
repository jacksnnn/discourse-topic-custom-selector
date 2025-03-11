import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "topic-custom-field-initializer",
  initialize(container) {
    // Takes the site settings from the container and gets the topic custom field name
    const siteSettings = container.lookup("service:site-settings");
    const fieldName = siteSettings.topic_custom_field_name;

    withPluginApi("0.8.31", (api) => {
      // Note: Services are auto-registered in modern Ember/Discourse
      // No need to manually register the FabubloxApi service

      // Make the custom field available in the composer
      api.serializeOnCreate("process_id");
      api.serializeOnCreate("processid");
      api.serializeToTopic("process_id", "process_id");
      api.serializeToTopic("processid", "processid");

      api.serializeOnCreate("Process URL");
      api.serializeOnCreate("process_url");
      api.serializeToTopic("Process URL", "process_url");
      api.serializeToTopic("process_url", "process_url");

      // Add the custom field to the topic model
      api.includePostAttributes("process_id");
      api.includePostAttributes("processid");

      // Add the custom field to the topic model
      api.includePostAttributes("Process URL");
      api.includePostAttributes("process_url");

      // Make sure the price field is also serialized
      api.serializeOnCreate("price");
      api.serializeToTopic("price", "price");
      api.includePostAttributes("price");

      /* For step 5 see connectors/composer-fields/topic-custom-field-composer.js */
      /* For step 6 see connectors/edit-topic/topic-custom-field-edit-topic.js */

      /*
       * type:        step
       * number:      7
       * title:       Serialize your field to the server
       * description: Send your field along with the post and topic data saved
       *              by the user when creating a new topic, saving a draft, or
       *              editing the first post of an existing topic.
       * references:  discourse/app/lib/plugin-api.js,
       *              discourse/app/models/composer.js
       */
      api.serializeOnCreate(fieldName);
      api.serializeToDraft(fieldName);
      api.serializeToTopic(fieldName, `topic.${fieldName}`);

      /* For step 8 see connectors/topic-title/topic-custom-field-topic-title.js */

      /*
       * type:        step
       * number:      9 & 10
       * title:       Display in topic list
       * description: The topic list customization is now handled by the Glimmer component
       *              in connectors/topic-list-after-title/topic-custom-field-topic-list-after-title.gjs
       *              and components/topic-list-custom-field.gjs
       */
    });
  },
};
