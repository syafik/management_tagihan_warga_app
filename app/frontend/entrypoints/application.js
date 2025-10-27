// Import Tailwind CSS
import './application.css'

// Import Choices.js CSS
import 'choices.js/public/assets/styles/choices.min.css'

// Import Chart.js globally
import Chart from 'chart.js/auto'

// Make Chart available globally
window.Chart = Chart

// Debug Chart.js loading
console.log('Chart.js loaded:', !!Chart)
if (Chart) {
  console.log('Chart.js version:', Chart.version || 'Unknown')
}

// Import Turbo for handling forms and navigation
import * as Turbo from '@hotwired/turbo'

// Import Stimulus
import { Application } from '@hotwired/stimulus'

// Import and register Stimulus controllers
const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Import all controller files from the controllers directory
import { registerControllers } from '../controllers'
registerControllers(application)

// Start Turbo
Turbo.start()

console.log('Vite ⚡️ Rails with Tailwind CSS, Stimulus & Turbo loaded!')