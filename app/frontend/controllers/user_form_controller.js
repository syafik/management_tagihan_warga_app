import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roleSelect", "addressBox", "picBox", "addressSelect"]

  connect() {
    // Initialize select2 if available
    if (typeof $ !== 'undefined' && $.fn.select2) {
      // Initialize role select
      $(this.roleSelectTarget).select2({
        minimumResultsForSearch: Infinity, // Hide search box for role
        width: '100%'
      });

      // Initialize address select with search and multi-select
      if (this.hasAddressSelectTarget) {
        const isMobile = window.innerWidth < 768;

        const $addressSelect = $(this.addressSelectTarget);

        $addressSelect.select2({
          placeholder: 'Pilih satu atau lebih blok rumah',
          allowClear: true,
          width: '100%',
          closeOnSelect: isMobile, // Auto-close on mobile for better UX
          tags: false,
          dropdownAutoWidth: false,
          templateResult: this.formatOption.bind(this),
          templateSelection: this.formatSelection.bind(this),
          // Mobile-specific optimizations
          containerCssClass: isMobile ? 'select2-container--mobile' : '',
          dropdownCssClass: isMobile ? 'select2-dropdown--mobile' : '',
          // Enable native dropdown on mobile if preferred
          // For multi-select, we keep Select2 but make it touch-friendly
          minimumResultsForSearch: isMobile ? 0 : 0, // Always show search
        });

        // Re-render dropdown on selection change to update checkmarks
        $addressSelect.on('select2:select select2:unselect', (e) => {
          // Small delay to ensure the dropdown updates
          setTimeout(() => {
            if ($addressSelect.data('select2').isOpen()) {
              // Trigger a search to refresh the results display
              const currentSearch = $('.select2-search__field').val();
              $('.select2-search__field').val(currentSearch).trigger('input');
            }
          }, 10);
        });

        // Add backdrop on mobile when dropdown opens
        if (isMobile) {
          $(this.addressSelectTarget).on('select2:open', () => {
            this.addMobileBackdrop();
          });

          $(this.addressSelectTarget).on('select2:close', () => {
            this.removeMobileBackdrop();
          });
        }
      }
    }
    this.toggleFields()
  }

  addMobileBackdrop() {
    if (!document.querySelector('.select2-backdrop')) {
      const backdrop = document.createElement('div');
      backdrop.className = 'select2-backdrop fixed inset-0 bg-black bg-opacity-50 z-[9998]';
      backdrop.addEventListener('click', () => {
        if (this.hasAddressSelectTarget) {
          $(this.addressSelectTarget).select2('close');
        }
      });
      document.body.appendChild(backdrop);
    }
  }

  removeMobileBackdrop() {
    const backdrop = document.querySelector('.select2-backdrop');
    if (backdrop) {
      backdrop.remove();
    }
  }

  disconnect() {
    // Clean up backdrop
    this.removeMobileBackdrop();

    // Clean up select2 if it was initialized
    if (typeof $ !== 'undefined' && $.fn.select2) {
      $(".select-field-js").select2('destroy');
    }
  }

  roleChanged() {
    this.toggleFields()
  }

  toggleFields() {
    const roleValue = this.roleSelectTarget.value

    if (roleValue === '3') { // Security role
      this.addressBoxTarget.classList.add('hidden')
      if (this.hasAddressSelectTarget) {
        $(this.addressSelectTarget).val(null).trigger('change')
      }
      this.picBoxTarget.classList.remove('hidden')
      this.picBoxTarget.querySelector('input').value = ''
    } else {
      this.addressBoxTarget.classList.remove('hidden')
      this.picBoxTarget.classList.add('hidden')
    }
  }

  // Format option in dropdown with checkbox for multi-select
  formatOption(option) {
    if (!option.id) {
      return option.text;
    }

    // Check if this option is selected
    const isSelected = option.selected;

    const checkmark = isSelected
      ? '<svg class="w-4 h-4 text-indigo-600 mr-2 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>'
      : '<svg class="w-4 h-4 text-gray-300 mr-2 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 20 20"><circle cx="10" cy="10" r="8" stroke-width="2"/></svg>';

    const $option = $(
      '<div class="flex items-center justify-between w-full">' +
        '<div class="flex items-center flex-1">' +
          checkmark +
          '<span class="' + (isSelected ? 'font-semibold text-indigo-900' : 'font-normal text-gray-900') + '">' +
            option.text +
          '</span>' +
        '</div>' +
        (isSelected ? '<span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800 ml-2">Dipilih</span>' : '') +
      '</div>'
    );
    return $option;
  }

  // Format selected option (badge/chip)
  formatSelection(option) {
    return option.text;
  }
}