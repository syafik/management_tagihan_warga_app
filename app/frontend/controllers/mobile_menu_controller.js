import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  connect() {
    console.log('Mobile menu controller connected')
    this.sidebar = document.getElementById('sidebar')
    this.overlay = document.getElementById('sidebar-overlay')
    
    console.log('Sidebar found:', this.sidebar)
    
    // Exit if sidebar doesn't exist yet
    if (!this.sidebar) {
      console.log('No sidebar found, exiting')
      return
    }
    
    // Create overlay if it doesn't exist
    if (!this.overlay) {
      this.createOverlay()
    }
    
    // Ensure sidebar starts in closed position on mobile
    if (window.innerWidth < 1024) {
      this.sidebar.classList.add('-translate-x-full')
    }
  }

  toggle() {
    console.log('Toggle called')
    
    // Find elements fresh each time
    const sidebar = document.getElementById('sidebar')
    const overlay = document.getElementById('sidebar-overlay') || this.createAndGetOverlay()
    
    console.log('Fresh sidebar found:', sidebar)
    
    if (!sidebar) {
      console.log('No sidebar available for toggle')
      return
    }
    
    sidebar.classList.toggle('-translate-x-full')
    overlay.classList.toggle('hidden')
    
    console.log('Sidebar classes after toggle:', sidebar.classList.toString())
    
    // Prevent body scrolling when sidebar is open
    if (sidebar.classList.contains('-translate-x-full')) {
      document.body.classList.remove('overflow-hidden')
    } else {
      document.body.classList.add('overflow-hidden')
    }
  }

  close() {
    const sidebar = document.getElementById('sidebar')
    const overlay = document.getElementById('sidebar-overlay')
    
    if (!sidebar) return
    
    sidebar.classList.add('-translate-x-full')
    if (overlay) overlay.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
  }

  createOverlay() {
    this.overlay = document.createElement('div')
    this.overlay.id = 'sidebar-overlay'
    this.overlay.className = 'fixed inset-0 bg-gray-600 bg-opacity-75 z-30 lg:hidden hidden'
    this.overlay.addEventListener('click', () => this.close())
    document.body.appendChild(this.overlay)
  }

  createAndGetOverlay() {
    const overlay = document.createElement('div')
    overlay.id = 'sidebar-overlay'
    overlay.className = 'fixed inset-0 bg-gray-600 bg-opacity-75 z-30 lg:hidden hidden'
    overlay.addEventListener('click', () => this.close())
    document.body.appendChild(overlay)
    return overlay
  }
}