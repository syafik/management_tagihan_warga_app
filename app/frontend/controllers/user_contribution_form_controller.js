import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "addressSearch",
    "addressSelect",
    "searchResults",
    "selectedAddress",
    "selectedAddressText",
    "contributionField", 
    "monthsGrid",
    "monthCheckbox",
    "monthSelectionContent"
  ]

  static values = {
    year: Number,
    currentContributionRate: Number
  }

  static classes = ["yearNavigation"]

  connect() {
    console.log("UserContributionForm controller connected")
    this.currentContributionRateValue = 0
    this.monthlyRates = new Map() // Store month-specific contribution rates
    this.searchTimeout = null
    
    // Check if there's a selected address from turbo stream
    this.checkForSelectedAddress()
    
    // Add click outside handler
    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }

  checkForSelectedAddress() {
    // Check if month selection content has a selected address data attribute
    if (this.hasMonthSelectionContentTarget) {
      const selectedAddress = this.monthSelectionContentTarget.dataset.selectedAddress
      if (selectedAddress && selectedAddress !== '' && this.hasAddressSelectTarget) {
        console.log("Restoring selected address:", selectedAddress)
        // Set the address select value
        this.addressSelectTarget.value = selectedAddress
        // Fetch payment status for this address
        this.fetchPaymentStatus(selectedAddress)
      }
    }
  }

  searchAddresses(event) {
    const query = event.target.value.trim()
    
    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
    
    // Hide results if query is too short
    if (query.length < 2) {
      this.searchResultsTarget.classList.add('hidden')
      return
    }
    
    // Debounce search
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  performSearch(query) {
    const url = `/user_contributions/search_addresses?q=${encodeURIComponent(query)}`
    
    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.displaySearchResults(data)
    })
    .catch(error => {
      console.error('Error searching addresses:', error)
    })
  }

  displaySearchResults(addresses) {
    const resultsContainer = this.searchResultsTarget
    
    if (addresses.length === 0) {
      resultsContainer.innerHTML = '<div class="p-3 text-sm text-gray-500">Tidak ada alamat yang ditemukan</div>'
    } else {
      resultsContainer.innerHTML = addresses.map(address => `
        <button type="button" 
                class="w-full text-left px-3 py-2 hover:bg-gray-100 border-b border-gray-100 last:border-b-0"
                data-action="click->user-contribution-form#selectAddress"
                data-address-id="${address.id}"
                data-address-text="${address.display_text}">
          <div class="font-medium text-gray-900">${address.block_address}</div>
          <div class="text-sm text-gray-500">${address.head_of_family_name || 'Tidak ada nama kepala keluarga'}</div>
        </button>
      `).join('')
    }
    
    resultsContainer.classList.remove('hidden')
  }

  selectAddress(event) {
    const button = event.currentTarget
    const addressId = button.dataset.addressId
    const addressText = button.dataset.addressText
    
    console.log('Address selected:', { addressId, addressText })
    
    // Set the hidden field value
    this.addressSelectTarget.value = addressId
    
    // Update display
    this.selectedAddressTextTarget.textContent = addressText
    this.selectedAddressTarget.classList.remove('hidden')
    
    // Clear search input and hide results
    this.addressSearchTarget.value = ''
    this.searchResultsTarget.classList.add('hidden')
    
    // Trigger address changed event
    this.addressChanged()
  }

  clearSelection() {
    // Clear selection
    this.addressSelectTarget.value = ''
    this.selectedAddressTarget.classList.add('hidden')
    this.addressSearchTarget.value = ''
    this.searchResultsTarget.classList.add('hidden')
    
    // Clear month selection
    const monthSelectionContainer = document.getElementById('month-selection')
    if (monthSelectionContainer) {
      monthSelectionContainer.innerHTML = ''
    }
    
    this.resetForm()
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.searchResultsTarget.classList.add('hidden')
    }
  }

  async addressChanged() {
    const addressId = this.addressSelectTarget.value
    
    if (!addressId) {
      this.resetForm()
      return
    }

    await this.fetchPaymentStatus(addressId)
  }

  async yearNavigation(event) {
    event.preventDefault()
    
    const newYear = parseInt(event.currentTarget.dataset.year)
    const currentAddressId = this.addressSelectTarget?.value
    
    console.log("Year navigation clicked:", newYear, "Address:", currentAddressId)
    
    // Update year value
    this.yearValue = newYear
    
    // Make turbo stream request with current address
    const url = new URL(window.location.origin + '/user_contributions/new')
    url.searchParams.set('year', newYear)
    if (currentAddressId) {
      url.searchParams.set('address_id', currentAddressId)
    }
    
    // Use Turbo to navigate with turbo stream
    await fetch(url.toString(), {
      method: 'GET',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'Turbo-Frame': '_top'
      }
    }).then(response => response.text())
      .then(html => {
        // Process turbo stream response
        Turbo.renderStreamMessage(html)
      })
  }

  // This method is called when monthSelectionContent target is connected/reconnected
  monthSelectionContentTargetConnected() {
    console.log("Month selection content target connected")
    // Small delay to ensure DOM is fully updated
    setTimeout(() => {
      this.checkForSelectedAddress()
    }, 50)
  }

  async fetchPaymentStatus(addressId) {
    try {
      const url = `/user_contributions/payment_status?address_id=${addressId}&year=${this.yearValue}`
      console.log('Fetching payment status from:', url)
      
      const response = await fetch(url)
      const data = await response.json()
      
      console.log('Payment Status Response:', data)
      
      if (data.success && data.months) {
        this.updateContributionInfo(data.months[0])
        this.updateMonthsWithPaymentStatus(data.months)
      } else {
        console.warn('API returned no payment status or failed:', data)
        this.resetForm()
      }
      
    } catch (error) {
      console.error('Error fetching payment status:', error)
      this.resetForm()
    }
  }

  updateContributionInfo(firstMonth) {
    if (!firstMonth) return

    this.currentContributionRateValue = firstMonth.contribution_rate
    
    console.log('Updated contribution rate for address:', this.currentContributionRateValue)
    
    // Clear and reset the contribution field 
    if (this.hasContributionFieldTarget) {
      this.contributionFieldTarget.value = ''
      // Trigger total calculation after contribution rate is updated
      setTimeout(() => {
        this.updateTotalContribution()
      }, 100)
    }
  }

  updateMonthsWithPaymentStatus(months) {
    // Clear previous monthly rates
    this.monthlyRates.clear()
    
    months.forEach(monthData => {
      const monthId = `month_${monthData.month}_${monthData.year}`
      const monthContainer = document.getElementById(monthId)?.parentElement
      
      // Store the monthly rate for later calculation
      const monthKey = `${monthData.month}_${monthData.year}`
      this.monthlyRates.set(monthKey, monthData.contribution_rate)
      
      if (monthContainer) {
        const label = monthContainer.querySelector('.month-label')
        const contributionDisplay = monthContainer.querySelector('.contribution-display')
        const paymentStatus = monthContainer.querySelector('.payment-status')
        const paidIndicator = monthContainer.querySelector('.paid-indicator')
        const unpaidIndicator = monthContainer.querySelector('.unpaid-indicator')
        const checkbox = monthContainer.querySelector('.month-checkbox')
        
        // Update contribution amount display
        if (contributionDisplay && monthData.contribution_rate > 0) {
          contributionDisplay.textContent = `Rp ${monthData.formatted_rate}`
          contributionDisplay.classList.remove('hidden')
        }
        
        // Update payment status
        if (paymentStatus) {
          paymentStatus.classList.remove('hidden')
          
          if (monthData.is_paid) {
            // Already paid - show paid status and disable checkbox
            paidIndicator?.classList.remove('hidden')
            unpaidIndicator?.classList.add('hidden')
            
            // Style as paid
            label?.classList.add('bg-green-50', 'border-green-200', 'text-green-800')
            label?.classList.remove('border-gray-200', 'hover:bg-gray-50')
            
            // Disable checkbox since already paid
            if (checkbox) {
              checkbox.disabled = true
              checkbox.checked = false
            }
          } else {
            // Not paid - show unpaid status and enable checkbox
            paidIndicator?.classList.add('hidden')
            unpaidIndicator?.classList.remove('hidden')
            
            // Style as unpaid
            label?.classList.add('bg-red-50', 'border-red-200')
            label?.classList.remove('border-gray-200', 'bg-green-50', 'border-green-200', 'text-green-800')
            
            // Enable checkbox for selection
            if (checkbox) {
              checkbox.disabled = false
            }
          }
        }
      }
    })
    
    console.log('Monthly rates stored:', Object.fromEntries(this.monthlyRates))
  }

  monthToggled(event) {
    const checkbox = event.target
    const label = document.querySelector(`label[for="${checkbox.id}"]`)
    
    if (checkbox.checked) {
      label?.classList.add('ring-2', 'ring-indigo-500')
    } else {
      label?.classList.remove('ring-2', 'ring-indigo-500')
    }
    
    this.updateTotalContribution()
  }

  updateTotalContribution() {
    const checkedBoxes = this.monthCheckboxTargets.filter(checkbox => 
      checkbox.checked && !checkbox.disabled
    )
    
    let totalAmount = 0
    let monthsDetails = []
    
    // Calculate total based on each month's specific contribution rate
    checkedBoxes.forEach(checkbox => {
      const month = parseInt(checkbox.dataset.month)
      const year = parseInt(checkbox.dataset.year)
      const monthKey = `${month}_${year}`
      
      // Get the specific contribution rate for this month/year
      const monthlyRate = this.monthlyRates.get(monthKey) || this.currentContributionRateValue
      
      totalAmount += monthlyRate
      monthsDetails.push({
        month: month,
        year: year,
        rate: monthlyRate
      })
    })
    
    // Update the contribution field
    if (this.hasContributionFieldTarget) {
      if (checkedBoxes.length > 0 && totalAmount > 0) {
        this.contributionFieldTarget.value = totalAmount
      } else {
        this.contributionFieldTarget.value = ''
      }
    }
    
    console.log('Total contribution calculated:', {
      selectedMonths: checkedBoxes.length,
      monthsDetails: monthsDetails,
      totalAmount: totalAmount
    })
  }

  resetForm() {
    // Clear contribution field
    if (this.hasContributionFieldTarget) {
      this.contributionFieldTarget.value = ''
    }
    
    // Reset all month displays
    this.monthCheckboxTargets.forEach(checkbox => {
      const monthContainer = checkbox.parentElement
      const label = monthContainer.querySelector('.month-label')
      const contributionDisplay = monthContainer.querySelector('.contribution-display')
      const paymentStatus = monthContainer.querySelector('.payment-status')
      
      // Reset styles
      label?.classList.remove('bg-green-50', 'border-green-200', 'text-green-800', 'bg-red-50', 'border-red-200')
      label?.classList.add('border-gray-200', 'hover:bg-gray-50')
      
      // Hide displays
      contributionDisplay?.classList.add('hidden')
      paymentStatus?.classList.add('hidden')
      
      // Enable and uncheck checkbox
      checkbox.disabled = false
      checkbox.checked = false
    })
    
    this.currentContributionRateValue = 0
    this.monthlyRates.clear() // Clear monthly rates
  }

}