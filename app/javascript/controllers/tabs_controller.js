import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]
  static values = { activeTab: String }

  connect() {
    this.showTab(this.activeTabValue || "email")
  }

  switch(event) {
    const tabName = event.currentTarget.dataset.tab
    this.showTab(tabName)
  }

  showTab(tabName) {
    // Remove active class from all buttons and contents
    this.buttonTargets.forEach(btn => btn.classList.remove('active'))
    this.contentTargets.forEach(content => content.classList.remove('active'))
    
    // Add active class to clicked button and corresponding content
    const activeButton = this.buttonTargets.find(btn => btn.dataset.tab === tabName)
    const activeContent = this.contentTargets.find(content => content.id === `${tabName}-tab`)
    
    if (activeButton) activeButton.classList.add('active')
    if (activeContent) activeContent.classList.add('active')
  }
}