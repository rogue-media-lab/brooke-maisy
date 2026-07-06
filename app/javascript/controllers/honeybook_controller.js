import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Guard: only inject the HoneyBook widget script once
    if (document.querySelector('script[src*="placement-controller"]')) return

    const script = document.createElement("script")
    script.type = "text/javascript"
    script.async = true
    script.src = "https://widget.honeybook.com/assets_users_production/websiteplacements/placement-controller.min.js"
    document.body.appendChild(script)
  }
}