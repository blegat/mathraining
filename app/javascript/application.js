import "popper"
import "bootstrap"
import "jquery"
import "jquery_ui"
import "jquery_ujs"
import "select2"
import "select2_locale_fr"

import "custom/clue"
import "custom/info"
import "custom/join"
import Preview from "custom/preview"
import PreviewSafe from "custom/previewsafe"
import Rolling from "custom/rolling"
import "custom/showcode"
import "custom/tainsert"

// NB: Import of springy and springyui is done only in graph_prerequisites.html.erb

window.Preview = Preview;
window.PreviewSafe = PreviewSafe;
window.Rolling = Rolling;

window.dispatchEvent(new CustomEvent("importmap-scripts-loaded"));

window.importJSDone = true; // Used in tests to be sure that everything is imported before clicking
