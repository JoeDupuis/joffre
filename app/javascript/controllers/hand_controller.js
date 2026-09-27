import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["flag"]
  static values = { refusal: String }

  refuse(event) {
    const slot = event.currentTarget
    slot.classList.remove("-shake")
    void slot.offsetWidth
    slot.classList.add("-shake")
    slot.addEventListener("animationend", () => slot.classList.remove("-shake"), { once: true })

    if (this.hasFlagTarget && this.refusalValue) this.flagTarget.textContent = this.refusalValue
  }
}
