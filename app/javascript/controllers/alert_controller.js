import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { closeBtnClass: String }

  connect() {
    const closeBtn = document.createElement("button")
    closeBtn.textContent = "×"
    closeBtn.classList.add(this.closeBtnClassValue || "closeBtn")
    closeBtn.addEventListener("click", () => this.dismiss())
    this.element.appendChild(closeBtn)
  }

  dismiss() {
    this.element.remove()
  }
}