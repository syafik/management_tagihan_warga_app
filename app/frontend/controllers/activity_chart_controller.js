import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    labels: Array,
    residents: Array
  }

  connect() {
    console.log("Activity chart controller connected")
    console.log("Window.Chart available at connect:", !!window.Chart)
    
    setTimeout(() => {
      this.createChart()
    }, 500)
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  createChart() {
    // Check if Chart is available
    const Chart = window.Chart
    if (!Chart) {
      console.error("Chart.js not loaded for activity chart")
      this.element.innerHTML = '<div class="flex items-center justify-center h-full text-red-500">Chart library not loaded</div>'
      return
    }

    // Check if element is a canvas
    if (!this.element.getContext) {
      console.error("Element is not a canvas")
      this.element.innerHTML = '<div class="flex items-center justify-center h-full text-red-500">Invalid canvas element</div>'
      return
    }

    const ctx = this.element.getContext('2d')
    
    // Safely parse the values with fallbacks
    let labels = []
    let residents = []
    
    try {
      // Get raw data attributes
      const labelsRaw = this.element.dataset.activityChartLabelsValue
      const residentsRaw = this.element.dataset.activityChartResidentsValue
      
      console.log('Raw activity chart data:', { labelsRaw, residentsRaw })
      
      // Parse labels
      if (labelsRaw && labelsRaw.trim() !== '' && labelsRaw !== 'null' && labelsRaw !== 'undefined') {
        try {
          labels = JSON.parse(labelsRaw)
          console.log('Parsed activity labels:', labels)
        } catch (e) {
          console.error('Failed to parse labels JSON:', labelsRaw, e)
          labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        }
      } else {
        labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      }
      
      // Parse residents
      if (residentsRaw && residentsRaw.trim() !== '' && residentsRaw !== 'null' && residentsRaw !== 'undefined') {
        try {
          residents = JSON.parse(residentsRaw)
          console.log('Parsed activity residents:', residents)
        } catch (e) {
          console.error('Failed to parse residents JSON:', residentsRaw, e)
          residents = new Array(labels.length).fill(0)
        }
      } else {
        residents = new Array(labels.length).fill(0)
      }
      
    } catch (error) {
      console.error('Error parsing activity chart data:', error)
      // Use fallback data
      labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      residents = new Array(12).fill(0)
    }
    
    // Ensure arrays are same length
    if (residents.length !== labels.length) {
      residents = new Array(labels.length).fill(0)
    }
    
    console.log('Final activity chart data:', { labels, residents })
    
    this.chart = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Active Residents',
          data: residents,
          backgroundColor: 'rgba(139, 92, 246, 0.8)',
          borderColor: 'rgb(139, 92, 246)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function(value) {
                return value + ' residents'
              }
            }
          }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                return context.dataset.label + ': ' + context.raw + ' residents'
              }
            }
          }
        }
      }
    })
  }
}