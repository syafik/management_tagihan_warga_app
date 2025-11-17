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
let installButton;

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

// iOS Install Instructions
function showIOSInstallInstructions() {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  const isStandalone = window.navigator.standalone === true;

  // Show instructions if on iOS and not already installed
  if (isIOS && !isStandalone && shouldShowInstallPrompt()) {
    // Create iOS install guide if not exists
    if (!document.getElementById('ios-install-guide')) {
      const guide = createIOSInstallGuide();
      document.body.appendChild(guide);

      // Show guide with animation
      setTimeout(() => {
        guide.classList.add('show');
      }, 1500);
    }
  }
}

// Create iOS Install Guide
function createIOSInstallGuide() {
  const guide = document.createElement('div');
  guide.id = 'ios-install-guide';
  guide.className = 'ios-install-guide';

  guide.innerHTML = `
    <div class="ios-install-content">
      <div class="ios-install-header">
        <h3>📱 Install Puri Ayana App</h3>
        <button class="ios-install-close" id="ios-install-close">✕</button>
      </div>
      <div class="ios-install-steps">
        <div class="ios-install-step">
          <span class="step-number">1</span>
          <span class="step-text">Tap tombol <strong>Share</strong> <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20"><path d="M15 8a3 3 0 10-2.977-2.63l-4.94 2.47a3 3 0 100 4.319l4.94 2.47a3 3 0 10.895-1.789l-4.94-2.47a3.027 3.027 0 000-.74l4.94-2.47C13.456 7.68 14.19 8 15 8z"/></svg> di bawah</span>
        </div>
        <div class="ios-install-step">
          <span class="step-number">2</span>
          <span class="step-text">Scroll ke bawah dan tap <strong>"Add to Home Screen"</strong></span>
        </div>
        <div class="ios-install-step">
          <span class="step-number">3</span>
          <span class="step-text">Tap <strong>"Add"</strong> untuk install</span>
        </div>
      </div>
    </div>
  `;

  // Add close button handler
  guide.querySelector('#ios-install-close').addEventListener('click', () => {
    guide.classList.remove('show');
    setTimeout(() => guide.remove(), 300);

    // Don't show again for 7 days
    localStorage.setItem('pwa-install-dismissed', Date.now());
  });

  return guide;
}

// Initialize on load
window.addEventListener('load', () => {
  // Show iOS instructions if applicable
  showIOSInstallInstructions();
});

// Export for use in other modules
export { showInstallPrompt, hideInstallPrompt, showIOSInstallInstructions };
