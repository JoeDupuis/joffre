import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  signIn() {
    const selectedEmail = this.selectTarget.value
    if (!selectedEmail) return

    const form = document.querySelector('form[action="/session"]')
    const emailField = form.querySelector('input[name="email_address"]')
    const passwordField = form.querySelector('input[name="password"]')
    
    emailField.value = selectedEmail
    passwordField.value = "password"
    form.submit()
  }
}