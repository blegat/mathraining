import "popper"
import "bootstrap"
import "jquery"
import "jquery_ui"
import "jquery_ujs"
import "select2"
import "select2_locale_fr"

import Clue from "custom/clue"
import Info from "custom/info"
import Joint from "custom/join"
import Preview from "custom/preview"
import Rolling from "custom/rolling"
import ShowHideCode from "custom/showcode"
import Insert from "custom/tainsert"
import LeavingForm from "custom/leavingform"
import Switcher from "custom/switcher"

// NB: Import of springy and springyui is done only in graph_prerequisites.html.erb

window.Clue = Clue;
window.Info = Info;
window.Joint = Joint;
window.Preview = Preview;
window.Rolling = Rolling;
window.ShowHideCode = ShowHideCode;
window.Insert = Insert;
window.LeavingForm = LeavingForm;
window.Switcher = Switcher

window.dispatchEvent(new CustomEvent("importmap-scripts-loaded"));

window.importJSDone = true; // Used in tests to be sure that everything is imported before clicking
