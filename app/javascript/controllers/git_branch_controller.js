import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["branch"]

  connect() {
    this.loadBranch()
    setInterval(() => this.loadBranch(), 30000)
  }

  async loadBranch() {
    try {
      const response = await fetch('/git_branch/current')
      const data = await response.json()
      
      if (data.branch) {
        this.branchTarget.textContent = data.branch
      }
    } catch (error) {
      console.error('Failed to load git branch:', error)
    }
  }
}