// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require select2
//= require select2_locale_fr
//= require bootstrap-sprockets
//= require moment
//= require bootstrap-datetimepicker

// Get toggle button element
const toggle = document.getElementById('dark-mode-toggle');

// Listen for click event on toggle button
toggle.addEventListener('click', () => {

  // Toggle 'dark-mode' class on body
  document.body.classList.toggle('dark-mode');
  
  // Update text of button based on body class
  if(document.body.classList.contains('dark-mode')) {
    toggle.innerText = 'Light Mode';
  } else {
    toggle.innerText = 'Dark Mode';
  }
  
});

//= require custom
//= require_tree .