import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "sheet"]

  connect() {
    // Prevent body scroll when sheet is open
    this.boundPreventScroll = this.preventScroll.bind(this)
  }

  disconnect() {
    this.close()
  }

  toggle(event) {
    event?.preventDefault()

    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    // Show backdrop
    this.backdropTarget.classList.remove("hidden")

    // Slide up sheet
    setTimeout(() => {
      this.sheetTarget.classList.remove("translate-y-full")
      this.sheetTarget.classList.add("translate-y-0")
    }, 10)

    // Prevent body scroll
    document.body.style.overflow = "hidden"
    document.addEventListener("touchmove", this.boundPreventScroll, { passive: false })
  }

  close() {
    // Slide down sheet
    this.sheetTarget.classList.remove("translate-y-0")
    this.sheetTarget.classList.add("translate-y-full")

    // Hide backdrop after animation
    setTimeout(() => {
      this.backdropTarget.classList.add("hidden")
    }, 300)

    // Restore body scroll
    document.body.style.overflow = ""
    document.removeEventListener("touchmove", this.boundPreventScroll)
  }

  isOpen() {
    return !this.backdropTarget.classList.contains("hidden")
  }

  preventScroll(event) {
    // Allow scrolling within the sheet
    if (!this.sheetTarget.contains(event.target)) {
      event.preventDefault()
    }
  }

  // Close on ESC key
  handleKeydown(event) {
    if (event.key === "Escape" && this.isOpen()) {
      this.close()
    }
  }
}
