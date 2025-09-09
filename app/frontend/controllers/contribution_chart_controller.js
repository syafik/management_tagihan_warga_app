import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    labels: Array,
    amounts: Array,
    counts: Array
  }

  connect() {
    console.log("Contribution chart controller connected")
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
      console.error("Chart.js not loaded for contribution chart")
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
    let amounts = []
    let counts = []
    
    try {
      // Get raw data attributes
      const labelsRaw = this.element.dataset.contributionChartLabelsValue
      const amountsRaw = this.element.dataset.contributionChartAmountsValue  
      const countsRaw = this.element.dataset.contributionChartCountsValue
      
      console.log('Raw contribution chart data:', { labelsRaw, amountsRaw, countsRaw })
      
      // Parse labels
      if (labelsRaw && labelsRaw.trim() !== '' && labelsRaw !== 'null' && labelsRaw !== 'undefined') {
        try {
          labels = JSON.parse(labelsRaw)
          console.log('Parsed contribution labels:', labels)
        } catch (e) {
          console.error('Failed to parse labels JSON:', labelsRaw, e)
          labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        }
      } else {
        labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      }
      
      // Parse amounts
      if (amountsRaw && amountsRaw.trim() !== '' && amountsRaw !== 'null' && amountsRaw !== 'undefined') {
        try {
          amounts = JSON.parse(amountsRaw)
          console.log('Parsed contribution amounts:', amounts)
        } catch (e) {
          console.error('Failed to parse amounts JSON:', amountsRaw, e)
          amounts = new Array(labels.length).fill(0)
        }
      } else {
        amounts = new Array(labels.length).fill(0)
      }
      
      // Parse counts
      if (countsRaw && countsRaw.trim() !== '' && countsRaw !== 'null' && countsRaw !== 'undefined') {
        try {
          counts = JSON.parse(countsRaw)
          console.log('Parsed contribution counts:', counts)
        } catch (e) {
          console.error('Failed to parse counts JSON:', countsRaw, e)
          counts = new Array(labels.length).fill(0)
        }
      } else {
        counts = new Array(labels.length).fill(0)
      }
      
    } catch (error) {
      console.error('Error parsing contribution chart data:', error)
      // Use fallback data
      labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      amounts = new Array(12).fill(0)
      counts = new Array(12).fill(0)
    }
    
    // Ensure arrays are same length
    if (amounts.length !== labels.length) {
      amounts = new Array(labels.length).fill(0)
    }
    if (counts.length !== labels.length) {
      counts = new Array(labels.length).fill(0)
    }
    
    console.log('Final contribution chart data:', { labels, amounts, counts })
    
    this.chart = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Contribution Amount (Rp)',
          data: amounts,
          backgroundColor: 'rgba(16, 185, 129, 0.8)',
          borderColor: 'rgb(16, 185, 129)',
          borderWidth: 1,
          yAxisID: 'y'
        }, {
          label: 'Payment Count',
          data: counts,
          type: 'line',
          borderColor: 'rgb(245, 158, 11)',
          backgroundColor: 'rgba(245, 158, 11, 0.1)',
          tension: 0.1,
          yAxisID: 'y1'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            beginAtZero: true,
            ticks: {
              callback: function(value) {
                return 'Rp ' + value.toLocaleString('id-ID')
              }
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            beginAtZero: true,
            grid: {
              drawOnChartArea: false,
            },
            ticks: {
              callback: function(value) {
                return value + ' payments'
              }
            }
          }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                if (context.datasetIndex === 0) {
                  return context.dataset.label + ': Rp ' + context.raw.toLocaleString('id-ID')
                } else {
                  return context.dataset.label + ': ' + context.raw + ' payments'
                }
              }
            }
          }
        }
      }
    })
  }
}