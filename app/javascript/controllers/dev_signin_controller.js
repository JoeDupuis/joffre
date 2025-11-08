import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  signIn(event) {
    const email = event.currentTarget.dataset.email
    if (!email) return

    const form = document.querySelector('form[action="/session"]')
    const emailField = form.querySelector('input[name="email_address"]')
    const passwordField = form.querySelector('input[name="password"]')

    emailField.value = email
    passwordField.value = "Xk9#mP7$qR2@"
    form.submit()
  }
}