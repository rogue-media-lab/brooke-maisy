import { Controller } from "@hotwired/stimulus"

// Tracks page views across Turbo Drive navigations for Google Ads (AW-18304063526).
// The base gtag.js library + initial config fires once in the <head> on full page load.
// This controller re-fires a page_view event on each turbo:load so Turbo navigations
// are tracked without a full reload.
export default class extends Controller {
  connect() {
    window.addEventListener("turbo:load", this.trackPageView)
  }

  disconnect() {
    window.removeEventListener("turbo:load", this.trackPageView)
  }

  trackPageView() {
    if (typeof gtag === "function") {
      gtag("event", "page_view", {
        page_path: window.location.pathname,
        page_title: document.title
      })
    }
  }
}
