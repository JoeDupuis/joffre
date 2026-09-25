import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  preserveOpen(event) {
    if (event.target !== this.element) return

    const { newElement } = event.detail
    if (newElement.dataset.controller === this.identifier) newElement.open = this.element.open
  }
}
