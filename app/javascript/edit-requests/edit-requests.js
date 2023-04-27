import { html, css, LitElement } from 'lit';
import { JSON_ACCEPT_HEADERS, JSON_CONTENT_HEADERS, CSRF_PARAM, CSRF_TOKEN, buildRoute } from '../fetch/helpers';
import _ from 'lodash';

const Diff = require('diff');

const fetchEditRequests = async (requestEl, button) => {
  const httpRequest = new Request(buildRoute({
    basePath: 'edit-requests',
    type: button.dataset.editableType,
    slug: button.dataset.editableSlug,
  }));
  const httpResponse = await fetch(httpRequest, { headers: JSON_ACCEPT_HEADERS });
  const jsonResponse = await httpResponse.json();

  if (httpResponse.ok) {
    requestEl.editRequests = jsonResponse.editRequests;
  } else {
    requestEl.error = jsonResponse.message;
  }
  requestEl.loading = false;
  requestEl.requestUpdate();
}

const externalButtonBinds = () => {
  const modal = document.querySelector('#edit-requests-modal');
  const modalTitle = modal.querySelector('#edit-requests-modal-title');
  const requestEl = modal.querySelector('edit-requests');
  const buttons = document.querySelectorAll('button.edit-requests');

  for (let i = 0; i < buttons.length; i++) {
    const button = buttons[i];
    button.addEventListener('click', e => {
      modalTitle.innerText = `Edit Requests for "${button.dataset.editableTitle}"`
      requestEl.editableType = button.dataset.editableType;
      requestEl.editableSlug = button.dataset.editableSlug;
      requestEl.loading = true;
      requestEl.error = null;
      fetchEditRequests(requestEl, button);
    });
  }
}

export class EditRequests extends LitElement {
  static styles = css`
    table th,
    table td {
      border-bottom: none;
    }

    tr.info-row {
      background-color: rgb(30, 35, 40);
      border-radius: 5px;
    }

    tr.info-row > td {
      padding: 0;
    }

    .right-align {
      text-align: right;
    }

    .pull-right {
      float: right;
    }

    input {
      cursor: pointer;
    }
  `;

  static properties = {
    loading: {type: Boolean},
    editableType: {type: String},
    editableSlug: {type: String},
    editRequests: {attribute: false},
    error: {type: String},
  };

  constructor() {
    super();

    externalButtonBinds();

    // TODO : make `collection` be dynamic in the path based on editable type
    this.UPDATE_PATH = '/edit-requests/:editable_type/:editable_slug/:id';

    // TODO : make this be dynamic based on the editable type
    this.CONTRIBUTION_TYPES = [
      'Contribution::Creator',
      'Contribution::CoCreator',
      'Contribution::ContributingAuthor'
    ];
  }

  render() {
    if (this.error) {
      return html`${this.error}`;
    } else if (this.loading) {
      return html`Loading...`;
    } else if (!this.editRequests || Object.keys(this.editRequests).length === 0) {
      return html`Nothing here!`;
    }

    const requestTypes = Object.keys(this.editRequests);

    return html`
      ${document.head.querySelector('link[rel="stylesheet"]#bootstrap-styles').cloneNode()}
      <table class="table">
        ${requestTypes.map((requestType, i) => this.renderRequests(requestType, this.editRequests[requestType], { notLast: i < requestTypes.length - 1 }))}
      </table>
    `;
  }

  renderRequests(requestType, requests, options = {}) {
    return html`
      <tr>
        <th colspan="5"><h3>${_.startCase(requestType)}</h3></th>
      </tr>
      <tr>
        <th>Created</th>
        <th>Source</th>
        <th>Status</th>
        <th>Reason</th>
        <th></th>
      </tr>
      ${this.__requestTypePicker(requestType, requests)}
      <tr>
        <td colspan="5">
          ${options.notLast ? html`<hr />` : null}
        </td>
      </tr>
    `;
  }

  __requestTypePicker(requestType, requests) {
    switch(requestType) {
    case 'FieldsEdit':
      return requests.map(request => this.renderFieldsEditRequest(requestType, request));
    case 'SeriesMerge':
      return requests.map(request => this.renderSeriesMergeRequest(requestType, request));
    default:
      return `UNIMPLEMENTED REQUEST TYPE ${request.requestType}`;
    }
  }

  __renderRequestHeader(request, actions) {
    return html`
      <tr>
        <td>${new Date(request.created_at).toLocaleDateString()}</td>
        <td>${_.startCase(request.source)}</td>
        <td>${_.startCase(request.status)}</td>
        <td>${_.startCase(request.request.reason)}</td>
        <td>
          <div class="input-group pull-right">
            <select class="form-select form-select-sm">
              <option value="accept" selected>Accept Checked</option>
              <option value="ignore">Ignore</option>
              <option value="deny">Deny</option>
            </select>
            <button
              type="button"
              class="btn btn-sm btn-outline-primary"
              data-request-id="${request.id}"
              data-slug="${this.editableSlug}"
              @click="${this._processRequest}"
            >
              GO
            </button>
          </div>
        </td>
      </tr>
    `;
  }

  __renderRequestInfo(extra) {
    return html`<tr class="info-row"><td colspan="5">${extra}</td></tr>`;
  }

  renderFieldsEditRequest(requestType, request) {
    const fieldNames = Object.keys(request.request);

    return html`
      ${this.__renderRequestHeader(request)}
      ${this.__renderRequestInfo(html`
        <table class="table">
          <tbody>
            ${fieldNames.map(fieldName => {
              const diff = Diff.diffChars(request.request[fieldName].from || '', request.request[fieldName].to || '');

              return html`
                <tr>
                  <td class="right-align">${_.upperFirst(fieldName)}:</td>
                  <td>
                    ${diff.map(part => html`<span style="color: ${part.added ? 'green' : part.removed ? 'red' : 'grey'}">${part.value}</span>`)}
                  </td>
                  <td class="right-align">
                    <input
                      type="checkbox"
                      class="form-check-input request-${request.id}"
                      value="${fieldName}"
                      checked
                    />
                  </td>
                </tr>
              `
            })}
          </tbody>
        </table>
      `)}
    `;
  }

  renderSeriesMergeRequest(requestType, request) {
    const mergeOptions = request.request.merge_options

    let allWorkSlugs = [];
    for (let i = 0; i < mergeOptions.length; i++) {
      const people = mergeOptions[i].people;
      for (let k = 0; k < people.length; k++) {
        allWorkSlugs = allWorkSlugs.concat(people[k].work_slugs);
      }
    }
    const totalWorks = _.uniq(allWorkSlugs).length;

    return html`
      ${this.__renderRequestHeader(request)}
      ${this.__renderRequestInfo(html`
        <table class="table">
          <thead>
            <tr>
              <th class="right-align">Similar To:</th>
              <th>Title</th>
              <th>Person</th>
              <th class="right-align">Works</th>
              <th class="right-align">Contribution</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${mergeOptions.map(similar => this.renderSimilar(request, similar, totalWorks))}
          </tbody>
        </table>
      `)}
    `;
  }

  renderSimilar(request, similar, totalWorks) {
    const isCurrent = this.editableSlug === similar.slug;

    const htmls = [];
    const people = similar.people;
    for (let i = 0; i < people.length; i++) {
      const person = people[i];

      const percentOfTotal = person.work_slugs.length / totalWorks;
      let personContribution;
      if (people.length > 1) {
        // In this case we can assume we already had a merge so we already set them appropriately
        personContribution = person.contribution;
      } else if (percentOfTotal > 0.75) {
        personContribution = 'Contribution::Creator';
      } else if (percentOfTotal > 0.5) {
        personContribution = 'Contribution::CoCreator';
      } else {
        personContribution = 'Contribution::ContributingAuthor';
      }

      htmls.push(html`
        <tr>
          ${i === 0 ? html`
            <td class="right-align">${isCurrent ? html`&rarr;` : null}</td>
            <td>${similar.title}</td>
          ` : html`
            <td></td>
            <td></td>
          `}
          <td>${person.name}</td>
          <td class="right-align">${person.work_slugs.length}</td>
          <td class="right-align">
            <select
              class="form-select form-select-sm contrib-${request.id}"
              data-collection-slug="${similar.slug}"
              data-person-slug="${person.slug}"
            >
              ${this.CONTRIBUTION_TYPES.map(contribution => this.renderContribOption(contribution, personContribution))}
            </select>
          </td>
          <td class="right-align">
            <input
              type="checkbox"
              class="form-check-input request-${request.id}"
              value="${similar.slug}"
              checked
            />
          </td>
        </tr>
      `)
    }

    return htmls;
  }

  renderContribOption(contribution, personContribution) {
    return html`
      <option
        value="${contribution}"
        ?selected=${contribution === personContribution}
      >
        ${_.startCase(contribution.replace('Contribution::', ''))}
      </option>
    `;
  }

  async _processRequest(event) {
    const requestId = event.currentTarget.dataset.requestId;
    const action = event.currentTarget.parentElement.querySelector('select').value;

    const httpRequest = new Request(buildRoute({
      basePath: 'edit-requests',
      type: this.editableType,
      slug: this.editableSlug,
      id: requestId,
    }));

    const httpResponse = await fetch(httpRequest, {
      method: 'PATCH',
      headers: JSON_CONTENT_HEADERS,
      body: JSON.stringify({
        [CSRF_PARAM]: CSRF_TOKEN,
        request_action: action,
        // Note that for any action other than accept we don't need to build out any data.
        edit_request_data: action === 'accept' ? this.__buildRequestData(requestId) : {},
      }),
    });

    const jsonResponse = await httpResponse.json();

    if (httpResponse.ok) {
      this.closest('.modal').querySelector('button.btn-close').click();
    } else {
      console.error(jsonResponse.message);
    }
  }

  __buildRequestData(requestId) {
    const requestData = {};

    // By default this handles field edits, the empty object is "inclusive" enough.
    const checkedData = this.shadowRoot.querySelectorAll(`input.request-${requestId}:checked`);
    for (let i = 0; i < checkedData.length; i++) {
      requestData[checkedData[i].value] = {};
    }

    // For merge requests we need some extra data
    const personSelects = this.shadowRoot.querySelectorAll(`select.contrib-${requestId}`)
    for (let i = 0; i < personSelects.length; i++) {
      if (requestData[personSelects[i].dataset.collectionSlug]) {
        requestData[personSelects[i].dataset.collectionSlug][personSelects[i].dataset.personSlug] = personSelects[i].value;
      }
    }

    return requestData;
  }
}
customElements.define('edit-requests', EditRequests);
