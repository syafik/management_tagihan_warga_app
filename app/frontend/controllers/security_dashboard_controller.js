import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput",
    "paymentModal",
    "addressInfo",
    "monthsGrid",
    "submitButton",
    "paymentTypeSelect",
    "totalAmount",
    "futureToggle"
  ]

  static values = {
    year: Number,
    addressId: Number
  }

  connect() {
    console.log("Security dashboard controller connected")
    this.searchTimeout = null
    this.selectedMonths = new Map() // Store selected months with their rates
    this.allMonthsData = [] // Store all months data
    this.includeFuture = false
  }

  search(event) {
    const query = event.target.value.trim()

    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    // Debounce search
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  performSearch(query) {
    const form = this.element.querySelector('form')
    if (form) {
      form.submit()
    }
  }

  async showPaymentForm(event) {
    event.preventDefault()

    const addressId = event.currentTarget.dataset.addressId
    const blockAddress = event.currentTarget.dataset.blockAddress
    const headOfFamily = event.currentTarget.dataset.headOfFamily

    console.log('Opening payment form for address:', addressId)

    // Store address ID
    this.addressIdValue = parseInt(addressId)

    // Update modal title
    const modalTitle = this.paymentModalTarget.querySelector('[data-modal-title]')
    if (modalTitle) {
      modalTitle.textContent = `Pembayaran Iuran - ${blockAddress}`
    }

    // Show loading state
    if (this.hasAddressInfoTarget) {
      this.addressInfoTarget.innerHTML = `
        <div class="text-center py-4">
          <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-indigo-600"></div>
          <div class="text-sm text-gray-500 mt-2">Memuat data...</div>
        </div>
      `
    }

    if (this.hasMonthsGridTarget) {
      this.monthsGridTarget.innerHTML = `
        <div class="col-span-full text-center py-8">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      `
    }

    // Show modal first
    this.paymentModalTarget.classList.remove('hidden')

    // Fetch payment status
    await this.loadPaymentStatus(addressId, blockAddress, headOfFamily)
  }

  async loadPaymentStatus(addressId, blockAddress, headOfFamily) {
    try {
      const url = `/security_dashboard/address_detail?id=${addressId}&include_future=${this.includeFuture}`

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch payment status')
      }

      const data = await response.json()

      if (data.success) {
        // Store all months data
        this.allMonthsData = data.months
        this.currentBlockAddress = blockAddress
        this.currentHeadOfFamily = headOfFamily

        // Update address info with summary
        if (this.hasAddressInfoTarget) {
          this.addressInfoTarget.innerHTML = `
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="font-medium text-gray-900 text-lg">${blockAddress}</div>
                <div class="text-sm text-gray-500 mt-1">Kepala Keluarga: ${headOfFamily || 'Tidak ada'}</div>
              </div>
              <div class="text-right">
                <div class="text-xs text-gray-600">Total Tunggakan</div>
                <div class="text-xl font-bold ${data.unpaid_count > 0 ? 'text-red-600' : 'text-green-600'}">
                  Rp ${data.formatted_total_unpaid || '0'}
                </div>
                <div class="text-xs ${data.unpaid_count > 0 ? 'text-red-600' : 'text-green-600'} mt-1">
                  ${data.unpaid_count || 0} bulan belum bayar
                </div>
                ${data.future_count > 0 ? `
                  <div class="text-xs text-blue-600 mt-1">
                    + ${data.future_count} bulan mendatang tersedia
                  </div>
                ` : ''}
              </div>
            </div>
          `
        }

        this.renderMonthsGrid(this.allMonthsData, data.unpaid_count)
      } else {
        console.error('Failed to load payment status:', data.error)
        alert(data.error || 'Gagal memuat status pembayaran')
        this.closeModal()
      }

    } catch (error) {
      console.error('Error loading payment status:', error)
      alert('Terjadi kesalahan saat memuat data')
      this.closeModal()
    }
  }

  async toggleFutureMonths(event) {
    this.includeFuture = event.target.checked

    // Reload payment status with new setting
    if (this.addressIdValue) {
      await this.loadPaymentStatus(
        this.addressIdValue,
        this.currentBlockAddress,
        this.currentHeadOfFamily
      )
    }
  }

  renderMonthsGrid(months, unpaidCount) {
    if (!this.hasMonthsGridTarget) return

    this.selectedMonths.clear()

    if (!months || months.length === 0) {
      this.monthsGridTarget.innerHTML = `
        <div class="col-span-full text-center py-8">
          <svg class="mx-auto h-12 w-12 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
          <p class="mt-4 text-sm font-medium text-gray-900">Tidak Ada Tunggakan</p>
          <p class="mt-1 text-sm text-gray-500">Semua pembayaran sudah lunas</p>
        </div>
      `
      return
    }

    // Separate unpaid and future months
    const unpaidMonths = months.filter(m => !m.is_future)
    const futureMonths = months.filter(m => m.is_future)

    // Group months by year
    const groupByYear = (monthsList) => {
      const grouped = {}
      monthsList.forEach(monthData => {
        if (!grouped[monthData.year]) {
          grouped[monthData.year] = []
        }
        grouped[monthData.year].push(monthData)
      })
      return grouped
    }

    const unpaidByYear = groupByYear(unpaidMonths)
    const futureByYear = groupByYear(futureMonths)

    const unpaidYears = Object.keys(unpaidByYear).sort((a, b) => parseInt(a) - parseInt(b))
    const futureYears = Object.keys(futureByYear).sort((a, b) => parseInt(a) - parseInt(b))

    let monthsHtml = ''

    // Render unpaid months first
    if (unpaidYears.length > 0) {
      monthsHtml += `
        <div class="col-span-full">
          <div class="flex items-center gap-2 mb-3">
            <div class="flex-1 border-t-2 border-red-300"></div>
            <span class="text-sm font-bold text-red-700 px-4 py-1.5 bg-red-50 rounded-full border-2 border-red-200">
              📌 TUNGGAKAN (${unpaidMonths.length} bulan)
            </span>
            <div class="flex-1 border-t-2 border-red-300"></div>
          </div>
        </div>
      `

      unpaidYears.forEach(year => {
        const yearMonths = unpaidByYear[year]

        monthsHtml += `
          <div class="col-span-full mt-2">
            <div class="text-xs font-medium text-gray-600 px-2">Tahun ${year}</div>
          </div>
        `

        yearMonths.forEach(monthData => {
          const monthKey = `${monthData.month}_${monthData.year}`

          monthsHtml += `
            <div class="month-item">
              <label class="block p-3 border rounded-lg cursor-pointer transition-all bg-red-50 border-red-200 hover:shadow-md hover:border-red-300"
                     for="month_${monthKey}">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="font-medium text-gray-900">${monthData.month_text} ${monthData.year}</div>
                    <div class="text-sm text-gray-600 mt-1">Rp ${monthData.formatted_rate}</div>
                    <div class="text-xs text-red-600 mt-1 font-medium">⚠️ Belum Bayar</div>
                  </div>
                  <input type="checkbox"
                         id="month_${monthKey}"
                         class="month-checkbox w-5 h-5 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                         data-action="change->security-dashboard#monthToggled"
                         data-month="${monthData.month}"
                         data-year="${monthData.year}"
                         data-rate="${monthData.contribution_rate}">
                </div>
              </label>
            </div>
          `
        })
      })
    }

    // Render future months if any
    if (futureYears.length > 0) {
      monthsHtml += `
        <div class="col-span-full mt-4">
          <div class="flex items-center gap-2 mb-3">
            <div class="flex-1 border-t-2 border-blue-300"></div>
            <span class="text-sm font-bold text-blue-700 px-4 py-1.5 bg-blue-50 rounded-full border-2 border-blue-200">
              📅 BULAN MENDATANG (${futureMonths.length} bulan)
            </span>
            <div class="flex-1 border-t-2 border-blue-300"></div>
          </div>
        </div>
      `

      futureYears.forEach(year => {
        const yearMonths = futureByYear[year]

        monthsHtml += `
          <div class="col-span-full mt-2">
            <div class="text-xs font-medium text-gray-600 px-2">Tahun ${year}</div>
          </div>
        `

        yearMonths.forEach(monthData => {
          const monthKey = `${monthData.month}_${monthData.year}`

          monthsHtml += `
            <div class="month-item">
              <label class="block p-3 border rounded-lg cursor-pointer transition-all bg-blue-50 border-blue-200 hover:shadow-md hover:border-blue-300"
                     for="month_${monthKey}">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="font-medium text-gray-900">${monthData.month_text} ${monthData.year}</div>
                    <div class="text-sm text-gray-600 mt-1">Rp ${monthData.formatted_rate}</div>
                    <div class="text-xs text-blue-600 mt-1">💰 Bayar Di Muka</div>
                  </div>
                  <input type="checkbox"
                         id="month_${monthKey}"
                         class="month-checkbox w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                         data-action="change->security-dashboard#monthToggled"
                         data-month="${monthData.month}"
                         data-year="${monthData.year}"
                         data-rate="${monthData.contribution_rate}">
                </div>
              </label>
            </div>
          `
        })
      })
    }

    this.monthsGridTarget.innerHTML = monthsHtml
  }

  monthToggled(event) {
    const checkbox = event.target
    const month = parseInt(checkbox.dataset.month)
    const year = parseInt(checkbox.dataset.year)
    const rate = parseFloat(checkbox.dataset.rate)
    const monthKey = `${month}_${year}`

    if (checkbox.checked) {
      this.selectedMonths.set(monthKey, { month, year, rate })
      checkbox.parentElement.classList.add('ring-2', 'ring-indigo-500')
    } else {
      this.selectedMonths.delete(monthKey)
      checkbox.parentElement.classList.remove('ring-2', 'ring-indigo-500')
    }

    this.updateTotalAmount()
    this.updateSubmitButton()
  }

  updateTotalAmount() {
    let total = 0

    this.selectedMonths.forEach(monthData => {
      total += monthData.rate
    })

    if (this.hasTotalAmountTarget) {
      this.totalAmountTarget.textContent = this.formatCurrency(total)
    }
  }

  updateSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      const hasSelection = this.selectedMonths.size > 0
      this.submitButtonTarget.disabled = !hasSelection

      if (hasSelection) {
        this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
        this.submitButtonTarget.classList.add('hover:bg-indigo-700')
      } else {
        this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
        this.submitButtonTarget.classList.remove('hover:bg-indigo-700')
      }
    }
  }

  async submitPayment(event) {
    event.preventDefault()

    if (this.selectedMonths.size === 0) {
      alert('Pilih minimal 1 bulan pembayaran')
      return
    }

    // Disable submit button to prevent double submission
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = 'Memproses...'

    try {
      const months = Array.from(this.selectedMonths.values())
      const paymentType = this.paymentTypeSelectTarget.value

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      const response = await fetch('/security_dashboard/create_payment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken,
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify({
          address_id: this.addressIdValue,
          months: months,
          payment_type: paymentType
        })
      })

      const data = await response.json()

      if (data.success) {
        alert(`${data.message}\nTotal: Rp ${this.formatCurrency(data.total)}`)
        this.closeModal()
        // Reload page to show updated data
        window.location.reload()
      } else {
        alert(data.error || 'Gagal mencatat pembayaran')
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.textContent = 'Simpan Pembayaran'
      }

    } catch (error) {
      console.error('Error submitting payment:', error)
      alert('Terjadi kesalahan saat memproses pembayaran')
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = 'Simpan Pembayaran'
    }
  }

  closeModal() {
    this.paymentModalTarget.classList.add('hidden')
    this.selectedMonths.clear()

    // Reset form
    if (this.hasMonthsGridTarget) {
      this.monthsGridTarget.innerHTML = ''
    }

    if (this.hasTotalAmountTarget) {
      this.totalAmountTarget.textContent = '0'
    }

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.textContent = 'Simpan Pembayaran'
    }

    // Reset future toggle
    if (this.hasFutureToggleTarget) {
      this.futureToggleTarget.checked = false
      this.includeFuture = false
    }
  }

  formatCurrency(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
  }
}
