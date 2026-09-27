import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }

  connect() {
    this.preserve = this.preserve.bind(this)
    document.addEventListener("turbo:before-morph-element", this.preserve)
    this.element.hidden = this.dismissed(this.keyValue)
  }

  disconnect() {
    document.removeEventListener("turbo:before-morph-element", this.preserve)
  }

  dismiss() {
    this.element.hidden = true
    try {
      localStorage.setItem(this.keyValue, "dismissed")
    } catch {}
  }

  dismissed(key) {
    try {
      return localStorage.getItem(key) === "dismissed"
    } catch {
      return false
    }
  }

  preserve(event) {
    const { newElement } = event.detail
    if (event.target !== this.element) return
    if (newElement?.dataset.controller !== this.identifier) return

    const key = newElement.dataset.roundResultKeyValue
    newElement.hidden = key === this.keyValue ? this.element.hidden : this.dismissed(key)
  }
}
