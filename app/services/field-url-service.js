import Service from "@ember/service";

export default class FieldUrlService extends Service {
  fieldUrl = null;

  setFieldUrl(url) {
    this.fieldUrl = url;
  }

  getFieldUrl() {
    return this.fieldUrl;
  }
}