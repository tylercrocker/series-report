import { html, css, LitElement } from 'lit';
import { JSON_ACCEPT_HEADERS, CSRF_PARAM, CSRF_TOKEN, buildRoute } from '../fetch/helpers';
import _ from 'lodash';

const fetchEditableData = async (requestEl, button) => {
  const httpRequest = new Request(buildRoute({ type: button.dataset.editableType, slug: button.dataset.editableSlug }));
  const httpResponse = await fetch(httpRequest, { headers: JSON_ACCEPT_HEADERS });
  const jsonResponse = await httpResponse.json();

  if (httpResponse.ok) {
    requestEl.fields = jsonResponse.fields;
  } else {
    requestEl.error = jsonResponse.message;
  }
  requestEl.loading = false;
  requestEl.requestUpdate();
}

const externalButtonBinds = () => {
  const requestEl = document.querySelector('#new-edit-request-modal new-edit-request');
  const buttons = document.querySelectorAll('button.new-edit-request');

  for (let i = 0; i < buttons.length; i++) {
    const button = buttons[i];
    button.addEventListener('click', e => {
      requestEl.fields = {};
      requestEl.loading = true;
      requestEl.error = null;
      fetchEditableData(requestEl, button);
    });
  }
}

export class NewEditRequest extends LitElement {
  static styles = css`
    .pull-right {
      float: right;
    }
  `;

  static properties = {
    loading: { type: Boolean },
    fields: { attribute: false },
    error: { type: String },
  };

  constructor() {
    super();

    externalButtonBinds();
  }

  render() {
    if (this.error) {
      return html`${this.error}`;
    } else if (this.loading) {
      return html`Loading...`;
    } else if (!this.fields || Object.keys(this.fields).length === 0) {
      return html`Nothing here!`;
    }

    const fieldNames = Object.keys(this.fields);

    return html`
      ${document.head.querySelector('link[rel="stylesheet"]#bootstrap-styles').cloneNode()}
      ${this._renderBaseInfo()}
      <hr />
      <form @submit=${this.__handleSubmit}>
        <input type="hidden" name="${CSRF_PARAM}" value="${CSRF_TOKEN}" autocomplete="off">
        ${fieldNames.map(fieldName => this._renderField(fieldName, this.fields[fieldName]))}
        <hr />
        <button
          type="submit"
          class="btn btn-primary pull-right"
        >
          Create Edit Request
        </button>
      </form>
    `;
  }

  _renderBaseInfo() {
    const path = buildRoute({ type: this.fields.type.value, slug: this.fields.slug.value });

    return html`
      <div class="info">
        <span class="type">${this.fields.type.value}</span>
         - 
        "<span class="label">${(this.fields.title || this.fields.name).value}</span>"
        <a href="${path}" target="_blank">https://www.seriesreport.net${path}</a>
      </div>
    `;
  }

  _renderField(fieldName, field) {
    if (!field.editable) {
      return null;
    }

    switch(field.type) {
    case 'string':
      return this._renderTextInput(fieldName, field);
    case 'text':
      return this._renderTextArea(fieldName, field);
    case 'integer':
      return this._renderIntegerInput(fieldName, field);
    case 'date':
      return this._renderDateInput(fieldName, field);
    default:
      return `UNSUPPORTED FIELD TYPE! "${field.type}"`;
    }
  }

  _renderTextInput(fieldName, field) {
    return html`
      <div class="mb-3">
        <label class="form-label">${_.startCase(fieldName)}</label>
        <input
          type="text"
          class="form-control"
          id="${fieldName}"
          name="editable[${fieldName}]"
          value="${field.value}"
        >
      </div>
    `;
  }

  _renderTextArea(fieldName, field) {
    return html`
      <div class="mb-3">
        <label class="form-label">${_.startCase(fieldName)}</label>
        <textarea
          class="form-control"
          id="${fieldName}"
          name="editable[${fieldName}]"
          rows="3"
        >${field.value}</textarea>
      </div>
    `;
  }

  _renderIntegerInput(fieldName, field) {
    return html`
      <div class="mb-3">
        <label class="form-label">${_.startCase(fieldName)}</label>
        <input
          type="number"
          class="form-control"
          id="${fieldName}"
          name="editable[${fieldName}]"
          value="${field.value}"
          @keydown=${this.__inputIntegersOnly}
        >
      </div>
    `;
  }

  __inputIntegersOnly(event) {
    if (event.metaKey) {
      return;
    }

    if (['Backspace', 'Delete', 'Enter', 'Tab', 'ArrowLeft', 'ArrowRight'].includes(event.key)) {
      return;
    }

    if (!event.key.match(/[0-9]/) || event.currentTarget.value.length >= 4) {
      event.preventDefault();
    }
  }

  _renderDateInput(fieldName, field) {
    return html`
      <div class="mb-3">
        <label class="form-label">${_.startCase(fieldName)}</label>
        <input
          type="date"
          class="form-control"
          id="${fieldName}"
          name="editable[${fieldName}]"
          value="${field.value}"
        >
      </div>
    `;
  }

  async __handleSubmit(e) {
    e.preventDefault();

    const formData = new FormData(e.currentTarget, e.submitter);

    // TODO : allow for other types
    formData.append('request_type', 'FieldsEdit');

    const httpRequest = new Request(buildRoute({
      basePath: 'edit-requests',
      type: this.fields.type.value,
      slug: this.fields.slug.value
    }));

    const httpResponse = await fetch(httpRequest, {
      method: 'POST',
      headers: JSON_ACCEPT_HEADERS,
      body: formData,
    });
    const jsonResponse = await httpResponse.json();

    if (!httpResponse.ok) {
      console.error(jsonResponse.message);
    }
  }
}
customElements.define('new-edit-request', NewEditRequest);
