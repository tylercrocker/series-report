import { html, css, LitElement } from 'lit';
import { JSON_ACCEPT_HEADERS, CSRF_PARAM, CSRF_TOKEN, buildRoute } from '../fetch/helpers';
import _ from 'lodash';

const fetchEditableData = async (requestEl, button) => {
  const httpRequest = new Request(buildRoute({ type: button.dataset.editableType, slug: button.dataset.editableSlug }));
  const httpResponse = await fetch(httpRequest, { headers: JSON_ACCEPT_HEADERS });
  const jsonResponse = await httpResponse.json();

  if (httpResponse.ok) {
    requestEl.editableType = button.dataset.editableType;
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
    editableType: { type: String },
    loading: { type: Boolean },
    fields: { attribute: false },
    error: { type: String },
  };

  constructor() {
    super();

    this.newFields = {
      alternate_names: {
        key: { editable: false, value: 'new' },
        name: {
          editable: true,
          type: 'string',
          value: '',
          placeholder: 'Bruce Wayne',
          required: true,
        },
        language: {
          editable: true,
          type: 'string',
          value: '',
          placeholder: 'English (default)',
          required: false,
        },
        empty: true,
      }
    };
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
    const path = buildRoute({ type: this.editableType, slug: this.fields.slug.value });

    return html`
      <div class="info">
        <span class="type">${this.fields.type.displayable || this.fields.type.value}</span>
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
    case 'array[table]':
      return this._renderArrayInputAsTable(fieldName, field);
    default:
      return `UNSUPPORTED FIELD TYPE! "${field.type}"`;
    }
  }

  // TODO : possibly put this into an outer helper...
  _renderTextInputSimple(data = {}) {
    return html`
      <input
        type="text"
        class=${data.small ? 'form-control form-control-sm' : 'form-control'}
        name=${data.name}
        value=${data.value}
        placeholder=${data.placeholder}
        ?required=${data.required}
      >
    `;
  }

  _renderTextInput(fieldName, field) {
    return html`
      <div class="mb-3">
        <label class="form-label">${_.startCase(fieldName)}</label>
        ${this._renderTextInputSimple({
          name: fieldName,
          value: field.value,
          required: field.required,
        })}
      </div>
    `;
  }

  _renderTextArea(fieldName, field) {
    return html`
      <div class="mb-3">
        <label class="form-label">${_.startCase(fieldName)}</label>
        <textarea
          class="form-control"
          name="editable[${fieldName}]"
          rows="3"
          ?required=${field.required}
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
          name="editable[${fieldName}]"
          value="${field.value}"
          @keydown=${this.__inputIntegersOnly}
          ?required=${field.required}
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
          name="editable[${fieldName}]"
          value="${field.value}"
          ?required=${field.required}
        >
      </div>
    `;
  }

  _renderArrayInputAsTable(fieldName, field) {
    return html`
      <table class="table table-borderless">
        <thead>
          <tr>
            <th>&nbsp;</th>
            ${field.headers.map(header => html`<th>${header}</th>`)}
            <th></th>
          </tr>
        </thead>
        <tbody>
          ${field.value.map(innerField => this._renderArrayInputRow(fieldName, innerField))}
          ${this._renderArrayInputRow(fieldName, this.newFields[fieldName])}
        </tbody>
      </table>
    `;
  }

  _renderArrayInputRow(outerFieldName, field = {}) {
    return html`
      <tr>
        <td>&nbsp;</td>
        ${Object.keys(field).map(fieldName => {
          return this.__renderArrayInputRowInput(outerFieldName, field.key.value, fieldName, field[fieldName]);
        })}
        <td>
          ${field.last_updated ? html`
            DELETE
          ` : field.empty ? html`
            <button
              class="btn btn-secondary btn-sm"
              data-fieldname=${outerFieldName}
              @click=${this.__addNewArrayInputRow}
            >
              <i class="bi bi-plus-square-dotted"></i>
            </button>
          ` : html`
            DELETE NEW
          `}
        </td>
      </tr>
    `;
  }

  __renderArrayInputRowInput(outerFieldName, key, fieldName, field) {
    if (!field.editable) {
      return null;
    }

    switch(field.type) {
    case 'string':
      return html`
        <td>
          ${this._renderTextInputSimple({
            small: true,
            name: `editable[${outerFieldName}][${key}][${fieldName}]${key === 'new' ? '[]' : ''}`,
            value: field.value,
            placeholder: field.placeholder,
          })}
        </td>
      `;
    default:
      return `<td>UNSUPPORTED FIELD TYPE! "${field.type}"</td>`;
    }
  }

  __addNewArrayInputRow(event) {
    event.preventDefault();

    const fieldName = event.currentTarget.dataset.fieldname;
    const row = event.currentTarget.closest('tr');
    const fieldInputs = row.querySelectorAll(`input[name$="[]"]`);
    let fields = JSON.parse(JSON.stringify(this.newFields[fieldName]));
    fields.empty = false;
    let valid = true;
    for (let i = 0; i < fieldInputs.length; i++) {
      const fieldInput = fieldInputs[i];

      // 0 is 'editable', 1 is the fieldName value, 2 is always 'new', 4 and 5 are empty
      const innerFieldName = fieldInput.name.split(/\]\[|\[|\]/)[3];

      // If one of the fields was required we don't want the user adding more and more empty rows
      if (this.newFields[fieldName][innerFieldName].required && !fieldInput.value) {
        valid = false;
        break;
      }

      fields[innerFieldName].value = fieldInput.value;
    }

    if (valid) {
      for (let i = 0; i < fieldInputs.length; i++) {
        fieldInputs[i].value = '';
      }
      this.fields[fieldName].value.push(fields)
      this.requestUpdate();
    } else {
      console.error('MISSING VALUES')
      // TODO : handle this
    }
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
