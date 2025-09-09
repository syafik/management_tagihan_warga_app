import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    labels: Array,
    incomeData: Array, 
    outcomeData: Array 
  }

  connect() {
    console.log("Financial chart controller connected")
    console.log("Window.Chart available at connect:", !!window.Chart)
    
    // Wait a bit to ensure Chart.js is loaded and DOM is ready
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
      console.error("Chart.js not loaded")
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
    
    // Debug the data values
    console.log('Labels value:', this.element.dataset.financialChartLabelsValue)
    console.log('Income data:', this.element.dataset.financialChartIncomeDataValue)
    console.log('Outcome data:', this.element.dataset.financialChartOutcomeDataValue)
    
    // Safely parse the values with fallbacks
    let labels = []
    let incomeData = []
    let outcomeData = []
    
    try {
      // Check if the raw data attributes exist and are not empty
      const labelsRaw = this.element.dataset.financialChartLabelsValue
      const incomeRaw = this.element.dataset.financialChartIncomeDataValue  
      const outcomeRaw = this.element.dataset.financialChartOutcomeDataValue
      
      console.log('Raw data attributes:', { labelsRaw, incomeRaw, outcomeRaw })
      
      if (labelsRaw && labelsRaw.trim() !== '' && labelsRaw !== 'null' && labelsRaw !== 'undefined') {
        try {
          labels = JSON.parse(labelsRaw)
          console.log('Parsed labels:', labels)
        } catch (e) {
          console.error('Failed to parse labels JSON:', labelsRaw, e)
          labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        }
      } else {
        // Fallback labels
        labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      }
      
      if (incomeRaw && incomeRaw.trim() !== '' && incomeRaw !== 'null' && incomeRaw !== 'undefined') {
        try {
          incomeData = JSON.parse(incomeRaw)
          console.log('Parsed income data:', incomeData)
        } catch (e) {
          console.error('Failed to parse income JSON:', incomeRaw, e)
          incomeData = new Array(labels.length).fill(0)
        }
      } else {
        incomeData = new Array(labels.length).fill(0)
      }
      
      if (outcomeRaw && outcomeRaw.trim() !== '' && outcomeRaw !== 'null' && outcomeRaw !== 'undefined') {
        try {
          outcomeData = JSON.parse(outcomeRaw)
          console.log('Parsed outcome data:', outcomeData)
        } catch (e) {
          console.error('Failed to parse outcome JSON:', outcomeRaw, e)
          outcomeData = new Array(labels.length).fill(0)
        }
      } else {
        outcomeData = new Array(labels.length).fill(0)
      }
    } catch (error) {
      console.error('Error parsing chart data:', error)
      console.error('Raw data was:', {
        labels: this.element.dataset.financialChartLabelsValue,
        income: this.element.dataset.financialChartIncomeDataValue,
        outcome: this.element.dataset.financialChartOutcomeDataValue
      })
      // Use fallback data
      labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      incomeData = new Array(12).fill(0)
      outcomeData = new Array(12).fill(0)
    }
    
    // Ensure arrays are same length
    if (incomeData.length !== labels.length) {
      incomeData = new Array(labels.length).fill(0)
    }
    if (outcomeData.length !== labels.length) {
      outcomeData = new Array(labels.length).fill(0)
    }
    
    console.log('Final chart data:', { labels, incomeData, outcomeData })
    
    this.chart = new window.Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Income (Pemasukan)',
          data: incomeData,
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.1,
          fill: true
        }, {
          label: 'Outcome (Pengeluaran)',
          data: outcomeData,
          borderColor: 'rgb(239, 68, 68)',
          backgroundColor: 'rgba(239, 68, 68, 0.1)',
          tension: 0.1,
          fill: true
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
                return 'Rp ' + value.toLocaleString('id-ID')
              }
            }
          }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                return context.dataset.label + ': Rp ' + context.raw.toLocaleString('id-ID')
              }
            }
          }
        }
      }
    })
  }
}