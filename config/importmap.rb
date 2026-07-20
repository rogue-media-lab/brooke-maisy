# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "signature_pad", to: "signature_pad.umd.min.js"
pin "signature_pad_wrapper", to: "signature_pad_wrapper.js"
pin_all_from "app/javascript/controllers", under: "controllers"
