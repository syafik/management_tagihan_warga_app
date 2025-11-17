import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    // Initialize collapsed state using max-height instead of hidden
    // This ensures form inputs inside are still submitted even when collapsed
    const content = this.contentTarget
    if (!content.dataset.expanded) {
      content.style.maxHeight = "0px"
      content.style.overflow = "hidden"
      content.style.transition = "max-height 0.3s ease-out"
    }
  }

  toggle() {
    const content = this.contentTarget
    const icon = this.iconTarget

    if (content.style.maxHeight === "0px" || !content.dataset.expanded) {
      // Expand content
      content.style.maxHeight = content.scrollHeight + "px"
      content.dataset.expanded = "true"
      icon.style.transform = "rotate(180deg)"
    } else {
      // Collapse content
      content.style.maxHeight = "0px"
      content.dataset.expanded = "false"
      icon.style.transform = "rotate(0deg)"
    }
  }
}
