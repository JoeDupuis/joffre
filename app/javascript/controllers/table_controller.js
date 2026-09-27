import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.preserve = this.preserve.bind(this)
    document.addEventListener("turbo:before-morph-element", this.preserve)
  }

  disconnect() {
    document.removeEventListener("turbo:before-morph-element", this.preserve)
  }

  openMenu() {
    if (!this.hasMenuTarget) return

    this.menuTarget.hidden = false
    this.menuTarget.querySelector("[data-action='table#closeMenu']")?.focus()
  }

  closeMenu() {
    if (this.hasMenuTarget) this.menuTarget.hidden = true
  }

  preserve(event) {
    if (!this.hasMenuTarget || event.target !== this.menuTarget) return

    event.detail.newElement.hidden = this.menuTarget.hidden
  }
}
