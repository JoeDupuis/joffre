import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.preserve = this.preserve.bind(this)
    this.clear = this.clear.bind(this)
    document.addEventListener("turbo:before-morph-element", this.preserve)
    document.addEventListener("turbo:submit-start", this.clear)
  }

  disconnect() {
    document.removeEventListener("turbo:before-morph-element", this.preserve)
    document.removeEventListener("turbo:submit-start", this.clear)
  }

  preserve(event) {
    if (event.target !== this.element) return

    event.preventDefault()
    const messages = Array.from(event.detail.newElement.children)
    if (messages.length > 0) this.element.replaceChildren(...messages)
  }

  clear() {
    this.element.replaceChildren()
  }
}
