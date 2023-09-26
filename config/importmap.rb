# Pin npm packages by running ./bin/importmap

pin "application", preload: true

pin "popper", to: 'popper.js', preload: true
pin "bootstrap", to: 'bootstrap.min.js', preload: true
#pin "jquery", to: "jquery.js", preload: true
pin "jquery", to: "https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.js", preload: true
pin "jquery_ui", to: "https://cdn.jsdelivr.net/npm/jquery-ui@1.13.2/dist/jquery-ui.js", preload: true
pin "jquery_ujs", to: "jquery_ujs.js", preload: true
pin "select2", to: "https://cdn.jsdelivr.net/npm/select2@4.0.13/dist/js/select2.full.min.js", preload: true
pin "select2_locale_fr", to: "select2_locale_fr.js", preload: true
pin_all_from "app/javascript/custom", under: "custom", preload: true
