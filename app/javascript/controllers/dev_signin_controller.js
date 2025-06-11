import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "form"]

  connect() {
  }

  signIn() {
    const selectedEmail = this.selectTarget.value
    if (!selectedEmail) return

    this.formTarget.elements.email_address.value = selectedEmail
    this.formTarget.elements.password.value = "password"
    this.formTarget.submit()
  }
}