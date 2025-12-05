import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('[WebView] Controller connected')

    // Check if running in React Native WebView
    this.isReactNative = typeof window.ReactNativeWebView !== 'undefined'

    if (this.isReactNative) {
      console.log('[WebView] Running inside React Native WebView')
      this.checkExistingSession()
      this.listenForMessages()
    }
  }

  disconnect() {
    if (this.messageListener) {
      document.removeEventListener('message', this.messageListener)
    }
  }

  // Check if user is already logged in and notify React Native
  checkExistingSession() {
    // Method 1: Check localStorage for DeviseTokenAuth headers
    const authHeadersStr = localStorage.getItem('authHeaders')

    if (authHeadersStr) {
      try {
        const authHeaders = JSON.parse(authHeadersStr)
        if (authHeaders['access-token'] && authHeaders['client'] && authHeaders['uid']) {
          console.log('[WebView] Found existing session, notifying React Native')
          this.notifyLogin(authHeaders)
          return
        }
      } catch (error) {
        console.error('[WebView] Error parsing stored auth headers:', error)
      }
    }

    // Method 2: Check sessionStorage
    const accessToken = sessionStorage.getItem('access-token')
    const client = sessionStorage.getItem('client')
    const uid = sessionStorage.getItem('uid')

    if (accessToken && client && uid) {
      console.log('[WebView] Found session in sessionStorage, notifying React Native')
      this.notifyLogin({
        'access-token': accessToken,
        'client': client,
        'uid': uid
      })
    }
  }

  // Notify React Native of login success
  notifyLogin(authHeaders) {
    if (!this.isReactNative) return

    const message = {
      type: 'LOGIN_SUCCESS',
      authHeaders: {
        'access-token': authHeaders['access-token'] || authHeaders['accessToken'],
        'client': authHeaders['client'],
        'uid': authHeaders['uid']
      }
    }

    console.log('[WebView→ReactNative] Sending LOGIN_SUCCESS:', message.authHeaders.uid)
    window.ReactNativeWebView.postMessage(JSON.stringify(message))
  }

  // Action method to be called after login success
  notifyLoginSuccess(event) {
    if (!this.isReactNative) return

    // Get auth headers from event detail or dataset
    const authHeaders = {
      'access-token': event.detail?.accessToken || this.element.dataset.accessToken,
      'client': event.detail?.client || this.element.dataset.client,
      'uid': event.detail?.uid || this.element.dataset.uid
    }

    if (authHeaders['access-token'] && authHeaders['client'] && authHeaders['uid']) {
      // Store for later use
      localStorage.setItem('authHeaders', JSON.stringify(authHeaders))

      // Notify React Native
      this.notifyLogin(authHeaders)
    } else {
      console.warn('[WebView] Missing auth headers in login success event')
    }
  }

  // Listen for messages from React Native
  listenForMessages() {
    this.messageListener = (event) => {
      try {
        const data = JSON.parse(event.data)
        console.log('[ReactNative→WebView] Message received:', data)

        if (data.type === 'PUSH_TOKEN_REGISTERED') {
          if (data.success) {
            console.log('[WebView] ✅ Push token registered successfully:', data.token)
            // Optional: Show success notification to user
            // You can dispatch a custom event or update UI here
          } else {
            console.log('[WebView] ⚠️ Push token registration failed')
          }
        }
      } catch (error) {
        console.error('[ReactNative→WebView] Error parsing message:', error)
      }
    }

    document.addEventListener('message', this.messageListener)
  }
}
