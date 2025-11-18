import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    // Check if app is already installed
    if (window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone) {
      this.hideButton()
      return
    }

    // Check if user has dismissed the install button (for iOS)
    if (localStorage.getItem('pwa_install_dismissed') === 'true') {
      this.hideButton()
      return
    }

    // Detect iOS
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream

    // Always show button on mobile (both Android and iOS)
    if (window.innerWidth < 1024) {
      this.showButton()
    }

    if (!isIOS) {
      // Listen for beforeinstallprompt event (Android/Desktop)
      window.addEventListener('beforeinstallprompt', (e) => {
        // Prevent the mini-infobar from appearing on mobile
        e.preventDefault()
        // Stash the event so it can be triggered later
        this.deferredPrompt = e
      })

      // Listen for app installed
      window.addEventListener('appinstalled', () => {
        this.hideButton()
        localStorage.setItem('pwa_install_dismissed', 'true')
        this.deferredPrompt = null
      })
    }
  }

  install(event) {
    event.preventDefault()

    // Check if it's iOS or Safari
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream
    const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent)

    if (isIOS || isSafari) {
      // Show iOS/Safari instructions using alert or custom modal
      alert('Untuk install di iOS/Safari:\n\n1. Tap tombol Share (ikon kotak dengan panah)\n2. Scroll dan pilih "Add to Home Screen"\n3. Tap "Add"\n\nApp akan muncul di home screen Anda!')
      // Mark as dismissed for iOS/Safari users after they see the instructions
      localStorage.setItem('pwa_install_dismissed', 'true')
      this.hideButton()
      return
    }

    if (!this.deferredPrompt) {
      alert('Install prompt tidak tersedia. Coba refresh halaman atau gunakan browser Chrome/Edge.')
      return
    }

    // Show the install prompt for Android/Desktop
    this.deferredPrompt.prompt()

    // Wait for the user to respond to the prompt
    this.deferredPrompt.userChoice.then((choiceResult) => {
      if (choiceResult.outcome === 'accepted') {
        console.log('User accepted the install prompt')
        this.hideButton()
      } else {
        console.log('User dismissed the install prompt')
      }
      this.deferredPrompt = null
    })
  }

  showButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.remove('hidden')
    }
  }

  hideButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.add('hidden')
    }
  }
}
