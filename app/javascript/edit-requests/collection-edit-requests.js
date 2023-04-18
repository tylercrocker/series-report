import { html, css, LitElement } from 'lit';
import { JSON_HEADERS, CSRF_PARAM, CSRF_TOKEN } from '../fetch/helpers'
import _ from 'lodash'

const fetchEditRequests = async (requestEl, button) => {
  const httpRequest = new Request(`/api/edit-requests/collection/${button.dataset.editableSlug}`);
  const httpResponse = await fetch(httpRequest, JSON_HEADERS);
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
  const modal = document.querySelector('#collection-edit-requests-modal');
  const modalTitle = modal.querySelector('#collection-edit-requests-modal-title');
  const requestEl = modal.querySelector('collection-edit-requests');
  const buttons = document.querySelectorAll('button.collection-edit-requests');

  for (let i = 0; i < buttons.length; i++) {
    const button = buttons[i];
    button.addEventListener('click', e => {
      modalTitle.innerText = `Edit Requests for "${button.dataset.editableTitle}"`
      requestEl.editableSlug = button.dataset.editableSlug;
      requestEl.loading = true;
      requestEl.error = null;
      fetchEditRequests(requestEl, button);
    });
  }
}

export class CollectionEditRequests extends LitElement {
  static styles = css`
    table {
      colspan: 0;
      border-spacing: 0;
      width: 100%;
    }

    td,
    th {
      padding: 3px 5px;
      text-align: left;
    }

    td.nopad {
      padding: 0;
    }

    .number {
      text-align: right;
    }

    .actions {
      text-align: right;
    }

    input,
    button {
      cursor: pointer;
    }

    button {
      background-color: #0d6efd;
    }
  `;

  static properties = {
    loading: {type: Boolean},
    editableSlug: {type: String},
    editRequests: {attribute: false},
    error: {type: String},
  };

  constructor() {
    super();

    externalButtonBinds();

    this.UPDATE_PATH = '/api/edit-requests/collection/:slug/:id';
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
      ${requestTypes.map(requestType => this.renderRequests(requestType, this.editRequests[requestType]))}
    `;
  }

  renderRequests(requestType, requests) {
    return html`
      <table>
        <thead>
          <tr>
            <th colspan="6">${_.startCase(requestType)}</th>
          </tr>
          <tr>
            <th>Created</th>
            <th>Source</th>
            <th>Status</th>
            <th>Reason</th>
            <th class="number">Ignored</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          ${requests.map(request => this.renderRequest(requestType, request))}
        </tbody>
      </table>
    `;
  }

  renderRequest(requestType, request) {
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
      <tr>
        <td>${new Date(request.created_at).toLocaleDateString()}</td>
        <td>${_.startCase(request.source)}</td>
        <td>${_.startCase(request.status)}</td>
        <td>${_.startCase(request.request.reason)}</td>
        <td class="number">${request.request.ignored_requests.length}</td>
      </tr>
      <tr>
        <td colspan="5" class="nopad">
          <table class="sub-table">
            <thead>
              <tr>
                <th class="actions">Similar To:</th>
                <th>Title</th>
                <th>Person</th>
                <th class="number">Works</th>
                <th class="actions">Contribution</th>
                <th class="actions">
                  <button
                    data-request-id="${request.id}"
                    data-slug="${this.editableSlug}"
                    @click="${this._processRequest}"
                  >
                    ${this.__requestVerb(requestType)}
                  </button>
                </th>
              </tr>
            </thead>
            <tbody>
              ${mergeOptions.map(similar => this.renderSimilar(request, similar, totalWorks))}
            </tbody>
          </table>
        </td>
      </tr>
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
            <td class="actions">${isCurrent ? html`&rarr;` : null}</td>
            <td>${similar.title}</td>
          ` : html`
            <td></td>
            <td></td>
          `}
          <td>${person.name}</td>
          <td class="number">${person.work_slugs.length}</td>
          <td class="actions">
            <select
              class="contrib-${request.id}"
              data-collection-slug="${similar.slug}"
              data-person-slug="${person.slug}"
            >
              ${this.CONTRIBUTION_TYPES.map(contribution => this.renderContribOption(contribution, personContribution))}
            </select>
          </td>
          <td class="actions">
            <input
              type="checkbox"
              class="request-${request.id}"
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
    const slug = event.currentTarget.dataset.slug;
    const httpRequest = new Request(this.UPDATE_PATH.replace(':slug', slug).replace(':id', requestId));

    const mergeData = {};
    const collectionChecks = this.shadowRoot.querySelectorAll(`input.request-${requestId}:checked`);
    for (let i = 0; i < collectionChecks.length; i++) {
      mergeData[collectionChecks[i].value] = {};
    }

    const personSelects = this.shadowRoot.querySelectorAll(`select.contrib-${requestId}`)
    for (let i = 0; i < personSelects.length; i++) {
      if (mergeData[personSelects[i].dataset.collectionSlug]) {
        mergeData[personSelects[i].dataset.collectionSlug][personSelects[i].dataset.personSlug] = personSelects[i].value;
      }
    }

    const httpResponse = await fetch(httpRequest, {
      method: 'PATCH',
      headers: JSON_HEADERS,
      body: JSON.stringify({
        [CSRF_PARAM]: CSRF_TOKEN,
        // There will be different types of data that are collected
        edit_request_data: mergeData,
      }),
    });
    const jsonResponse = await httpResponse.json();

    if (!httpResponse.ok) {
      console.error(jsonResponse.message);
    }
  }

  __requestVerb(requestType) {
    switch(requestType) {
    case 'SeriesMerge':
      return 'Merge'
      break;
    default:
      return 'TODO: WRITE THIS'
    }
  }
}
customElements.define('collection-edit-requests', CollectionEditRequests);
