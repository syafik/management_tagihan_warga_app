// PWA Service Worker Registration and Install Prompt
console.log('[PWA] Initializing...');

// Register Service Worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js')
      .then((registration) => {
        console.log('[PWA] Service Worker registered:', registration.scope);

        // Check for updates periodically
        setInterval(() => {
          registration.update();
        }, 60 * 60 * 1000); // Check every hour
      })
      .catch((error) => {
        console.error('[PWA] Service Worker registration failed:', error);
      });
  });
}

// Install Prompt Handler
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
  console.log('[PWA] Install prompt available');

  // Prevent default browser install prompt
  e.preventDefault();

  // Store the event for later use
  deferredPrompt = e;

  // Show custom install UI
  showInstallPrompt();
});

// Handle successful installation
window.addEventListener('appinstalled', () => {
  console.log('[PWA] App installed successfully');

  // Hide install prompt
  hideInstallPrompt();

  // Clear the deferred prompt
  deferredPrompt = null;

  // Optional: Track installation
  if (typeof gtag !== 'undefined') {
    gtag('event', 'pwa_install', {
      event_category: 'engagement',
      event_label: 'PWA Installed'
    });
  }
});

// Show Install Prompt (Android/Desktop Chrome)
function showInstallPrompt() {
  // Create install banner if not exists
  if (!document.getElementById('pwa-install-banner')) {
    const banner = createInstallBanner();
    document.body.appendChild(banner);

    // Show banner with animation
    setTimeout(() => {
      banner.classList.add('show');
    }, 1000);
  }
}

// Hide Install Prompt
function hideInstallPrompt() {
  const banner = document.getElementById('pwa-install-banner');
  if (banner) {
    banner.classList.remove('show');
    setTimeout(() => {
      banner.remove();
    }, 300);
  }
}

// Create Install Banner HTML
function createInstallBanner() {
  const banner = document.createElement('div');
  banner.id = 'pwa-install-banner';
  banner.className = 'pwa-install-banner';

  banner.innerHTML = `
    <div class="pwa-install-content">
      <div class="pwa-install-icon">
        🏡
      </div>
      <div class="pwa-install-text">
        <div class="pwa-install-title">Install Puri Ayana App</div>
        <div class="pwa-install-subtitle">Akses lebih cepat dari home screen</div>
      </div>
      <div class="pwa-install-actions">
        <button class="pwa-install-btn" id="pwa-install-accept">
          Install
        </button>
        <button class="pwa-install-btn-close" id="pwa-install-dismiss">
          ✕
        </button>
      </div>
    </div>
  `;

  // Add event listeners
  const acceptBtn = banner.querySelector('#pwa-install-accept');
  const dismissBtn = banner.querySelector('#pwa-install-dismiss');

  acceptBtn.addEventListener('click', async () => {
    if (deferredPrompt) {
      // Show native install prompt
      deferredPrompt.prompt();

      // Wait for user response
      const { outcome } = await deferredPrompt.userChoice;
      console.log(`[PWA] User response: ${outcome}`);

      // Clear the prompt
      deferredPrompt = null;
      hideInstallPrompt();
    }
  });

  dismissBtn.addEventListener('click', () => {
    hideInstallPrompt();

    // Don't show again for 7 days
    localStorage.setItem('pwa-install-dismissed', Date.now());
  });

  return banner;
}

// Check if install prompt was dismissed recently
function shouldShowInstallPrompt() {
  const dismissed = localStorage.getItem('pwa-install-dismissed');
  if (dismissed) {
    const dismissedDate = parseInt(dismissed);
    const daysSinceDismissed = (Date.now() - dismissedDate) / (1000 * 60 * 60 * 24);
    return daysSinceDismissed > 7; // Show again after 7 days
  }
  return true;
}

// ✅ Detect Safari iOS specifically (not Chrome iOS, Firefox iOS, etc)
function isSafariIOS() {
  const ua = window.navigator.userAgent;
  const iOS = /iPad|iPhone|iPod/.test(ua);
  const webkit = /WebKit/.test(ua);

  // Safari iOS has webkit but NOT Chrome, Firefox, Opera, etc
  const isSafari = iOS && webkit && !/CriOS|FxiOS|OPiOS|mercury/i.test(ua);

  return isSafari;
}

// ✅ Detect if already installed as PWA
function isInstalled() {
  return window.navigator.standalone === true ||
         window.matchMedia('(display-mode: standalone)').matches;
}

// iOS Install Instructions - ONLY for Safari iOS
function showIOSInstallInstructions() {
  // ✅ ONLY show on Safari iOS and NOT already installed
  if (!isSafariIOS() || isInstalled()) {
    console.log('[PWA] Not Safari iOS or already installed, skipping install button');
    return;
  }

  // Don't show if dismissed recently
  if (!shouldShowInstallPrompt()) {
    console.log('[PWA] Install prompt dismissed recently');
    return;
  }

  // Create iOS install button if not exists
  if (!document.getElementById('ios-install-button')) {
    const button = createIOSInstallButton();
    document.body.appendChild(button);

    console.log('[PWA] Safari iOS install button shown');
  }
}

// ✅ Create iOS Install Button (Fixed position, bottom-right)
function createIOSInstallButton() {
  const button = document.createElement('button');
  button.id = 'ios-install-button';
  button.className = 'ios-install-button';
  button.innerHTML = `
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" style="margin-right: 8px;">
      <path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z" fill="currentColor"/>
    </svg>
    <span>Install App</span>
  `;

  // Click handler - show instructions modal
  button.addEventListener('click', () => {
    showIOSInstallModal();
  });

  return button;
}

// ✅ Show iOS Install Instructions Modal
function showIOSInstallModal() {
  // Remove existing modal if any
  const existingModal = document.getElementById('ios-install-modal');
  if (existingModal) {
    existingModal.remove();
  }

  // Create modal overlay
  const overlay = document.createElement('div');
  overlay.id = 'ios-install-modal';
  overlay.className = 'ios-install-modal-overlay';

  overlay.innerHTML = `
    <div class="ios-install-modal">
      <button class="ios-install-modal-close" id="ios-modal-close">×</button>

      <h2 class="ios-install-modal-title">
        📱 Install Puri Ayana App
      </h2>

      <p class="ios-install-modal-subtitle">
        Untuk menginstall aplikasi ke home screen:
      </p>

      <div class="ios-install-modal-steps">
        <div class="ios-install-modal-step">
          <div class="step-number">1</div>
          <div class="step-content">
            <p class="step-title">Tap tombol Share</p>
            <p class="step-description">
              Tap ikon Share
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style="display: inline; vertical-align: middle; margin: 0 4px;">
                <path d="M16 5l-1.42 1.42-1.59-1.59V16h-1.98V4.83L9.42 6.42 8 5l4-4 4 4zm4 5v11c0 1.1-.9 2-2 2H6c-1.11 0-2-.9-2-2V10c0-1.11.89-2 2-2h3v2H6v11h12V10h-3V8h3c1.1 0 2 .89 2 2z" fill="#007AFF"/>
              </svg>
              di bagian bawah layar
            </p>
          </div>
        </div>

        <div class="ios-install-modal-step">
          <div class="step-number">2</div>
          <div class="step-content">
            <p class="step-title">Pilih "Add to Home Screen"</p>
            <p class="step-description">
              Scroll ke bawah dan tap "Add to Home Screen"
            </p>
          </div>
        </div>

        <div class="ios-install-modal-step">
          <div class="step-number">3</div>
          <div class="step-content">
            <p class="step-title">Tap "Add"</p>
            <p class="step-description">
              Konfirmasi untuk menambahkan ke home screen
            </p>
          </div>
        </div>
      </div>

      <div class="ios-install-modal-footer">
        <p>Setelah di-install, buka app dari home screen untuk pengalaman terbaik!</p>
      </div>

      <button class="ios-install-modal-btn" id="ios-modal-ok">
        Mengerti
      </button>
    </div>
  `;

  document.body.appendChild(overlay);

  // Add event listeners
  const closeBtn = overlay.querySelector('#ios-modal-close');
  const okBtn = overlay.querySelector('#ios-modal-ok');

  const closeModal = () => {
    overlay.classList.add('hide');
    setTimeout(() => overlay.remove(), 300);
  };

  closeBtn.addEventListener('click', closeModal);
  okBtn.addEventListener('click', closeModal);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) {
      closeModal();
    }
  });

  // Show with animation
  setTimeout(() => {
    overlay.classList.add('show');
  }, 10);
}

// Initialize on load
window.addEventListener('load', () => {
  // Show iOS instructions if applicable
  showIOSInstallInstructions();
});

// Export for use in other modules
export { showInstallPrompt, hideInstallPrompt, showIOSInstallInstructions };
